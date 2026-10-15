#!/usr/bin/env node

import { randomUUID } from 'node:crypto'
import { cp, lstat, mkdir, mkdtemp, readFile, readdir, rm, writeFile } from 'node:fs/promises'
import { createRequire } from 'node:module'
import { tmpdir } from 'node:os'
import path from 'node:path'
import { parseArgs } from 'node:util'
import * as prompts from '@clack/prompts'
import spawn from 'cross-spawn'

const require = createRequire(import.meta.url)
const packageJson = JSON.parse(await readFile(new URL('./package.json', import.meta.url), 'utf8'))
const viteDirectory = path.dirname(require.resolve('create-vite/package.json'))
const templates = (await readdir(viteDirectory, { withFileTypes: true }))
  .filter((entry) => entry.isDirectory() && entry.name.startsWith('template-'))
  .map((entry) => entry.name.slice('template-'.length))
  .sort()

function checkCancelled(value) {
  if (prompts.isCancel(value)) {
    prompts.cancel('Operation cancelled.')
    process.exit(0)
  }
  return value
}

async function assertEmptyDirectory(directory) {
  try {
    const info = await lstat(directory)
    if (!info.isDirectory()) throw new Error(`Target is not a directory: ${directory}`)
    const entries = await readdir(directory)
    if (entries.some((name) => name !== '.git')) {
      throw new Error(`Target directory is not empty: ${directory}. Choose a new or empty directory.`)
    }
  } catch (error) {
    if (error.code !== 'ENOENT') throw error
  }
}

function run(command, args, cwd, quiet = false) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, {
      cwd,
      stdio: quiet ? ['ignore', 'pipe', 'pipe'] : 'inherit',
    })
    let output = ''
    if (quiet) {
      child.stdout.on('data', (data) => { output += data })
      child.stderr.on('data', (data) => { output += data })
    }
    child.on('error', reject)
    child.on('close', (code, signal) => {
      if (code === 0) resolve()
      else reject(new Error(`${path.basename(command)} failed (${signal ?? code}).${output ? `\n${output.trim()}` : ''}`))
    })
  })
}

async function configureProject(directory, template, packageManager) {
  const filename = path.join(directory, 'package.json')
  const project = JSON.parse(await readFile(filename, 'utf8'))
  project.dependencies = { ...project.dependencies, 'minip-bridge': packageJson.minip.bridgeVersion }
  project.devDependencies = { ...project.devDependencies, 'vite-plugin-minip': packageJson.minip.pluginVersion }
  project.scripts.pack = `${packageManager} run build && vite preview`
  await writeFile(filename, `${JSON.stringify(project, null, 2)}\n`)

  const configs = (await readdir(directory)).filter((name) => /^vite\.config\.[cm]?[jt]s$/.test(name))
  if (configs.length > 1) throw new Error('The upstream template contains multiple Vite configurations.')
  if (configs.length === 1) {
    const configPath = path.join(directory, configs[0])
    const config = await readFile(configPath, 'utf8')
    if (!/\bplugins\s*:\s*\[/.test(config)) {
      throw new Error(`Cannot add Minip to the upstream ${configs[0]}. Its plugins array was not found.`)
    }
    await writeFile(configPath, `import minip from 'vite-plugin-minip'\n${config.replace(/\bplugins\s*:\s*\[/, '$&minip(), ')}`)
  } else {
    const extension = template.endsWith('-ts') ? 'ts' : 'js'
    await writeFile(path.join(directory, `vite.config.${extension}`),
      "import { defineConfig } from 'vite'\nimport minip from 'vite-plugin-minip'\n\nexport default defineConfig({\n  plugins: [minip()],\n})\n")
  }

  await writeFile(path.join(directory, 'app.json'), `${JSON.stringify({
    appId: randomUUID(),
    name: project.name,
    homepage: 'index.html',
    version: '0.0.1',
  }, null, 2)}\n`)

  const readmePath = path.join(directory, 'README.md')
  let readme = ''
  try {
    readme = await readFile(readmePath, 'utf8')
  } catch (error) {
    if (error.code !== 'ENOENT') throw error
  }
  await writeFile(readmePath, `${readme.trimEnd()}${readme ? '\n\n' : ''}## Minip\n
This project uses [vite-plugin-minip](https://www.npmjs.com/package/vite-plugin-minip)
to build an installable Minip app. It was created from the official Vite
\`${template}\` template; the framework's source and build commands are preserved.

- \`${packageManager} run dev\`: scan the development QR code with Minip for native APIs and Vite hot updates.
- \`${packageManager} run build\`: build the frontend and create \`dist/${project.name}.zip\`.
- \`${packageManager} run pack\`: build, start the preview server, and show an installation QR code.

Connect your phone and computer to the same network, then scan the QR code using
a Minip app build that supports development sessions. Keep the development server
running while editing. Native storage and permissions use the stable \`appId\` in
\`app.json\`; development and installed copies with that ID share native data.
Rescan after changing native settings in \`app.json\`, such as tabs or navigation.
Browser preview is also available, but native APIs run inside Minip.

Use \`pack\` to test or distribute an installed app. Keep the preview server running
until the download finishes. Rebuild and scan again to install an update.

Edit \`app.json\` to set the app's name and metadata. Keep its \`appId\` unchanged
when releasing updates. Optional icons can live in \`public/\` or the project root;
set \`icon\` to their path within the installed app.

Import native APIs from \`minip-bridge\`, for example:

\`\`\`js
import { getKVStorage, setKVStorage } from 'minip-bridge'

await setKVStorage('theme', 'dark')
const theme = await getKVStorage('theme')
\`\`\`

SDK 2 requires a Minip app build with bridge runtime version 1.
`)
}

async function main() {
  const { values, positionals } = parseArgs({
    allowPositionals: true,
    options: {
      template: { type: 'string', short: 't' },
      'no-install': { type: 'boolean', default: false },
      help: { type: 'boolean', short: 'h' },
      version: { type: 'boolean', short: 'v' },
    },
  })
  if (values.version) {
    console.log(packageJson.version)
    return
  }
  if (values.help) {
    console.log(`Usage: create-minip [DIRECTORY] [OPTIONS]

Create a Vite frontend project configured for Minip.

Options:
  -t, --template NAME  Use an official Vite frontend template
      --no-install     Create the project without installing dependencies
  -h, --help           Show this help
  -v, --version        Show the version

Templates: ${templates.join(', ')}

Examples:
  npm create minip@latest
  npm create minip@latest my-app -- --template vue-ts
  pnpm create minip my-app --template react-ts --no-install`)
    return
  }
  if (positionals.length > 1) throw new Error('Pass only one target directory.')
  if (!templates.length) throw new Error('No frontend templates were found in create-vite.')
  const interactive = Boolean(process.stdin.isTTY && process.stdout.isTTY)
  if (values.template && !templates.includes(values.template)) {
    throw new Error(`Unknown frontend template: ${values.template}. Available templates: ${templates.join(', ')}`)
  }
  if (!interactive && !values.template) {
    throw new Error('Pass --template when running without an interactive terminal. Use --help to list templates.')
  }

  prompts.intro('Create a Minip app')
  const target = positionals[0] ?? (interactive
    ? checkCancelled(await prompts.text({ message: 'Project directory:', placeholder: 'minip-app', defaultValue: 'minip-app' }))
    : 'minip-app')
  const directory = path.resolve(target)
  const projectName = path.basename(directory)
  if (!projectName || /[<>:"\\|?*\x00-\x1f]/.test(projectName) || /[. ]$/.test(projectName)) {
    throw new Error('Choose a project directory with a valid filename.')
  }
  await assertEmptyDirectory(directory)

  let template = values.template
  if (!template) {
    const frameworks = [...new Set(templates.map((name) => name.replace(/-ts$/, '')))]
    const framework = checkCancelled(await prompts.select({
      message: 'Select a framework:',
      options: frameworks.map((name) => ({ value: name, label: name[0].toUpperCase() + name.slice(1) })),
    }))
    const variants = templates.filter((name) => name === framework || name === `${framework}-ts`)
    template = checkCancelled(await prompts.select({
      message: 'Select a language:',
      initialValue: variants.find((name) => name.endsWith('-ts')) ?? variants[0],
      options: variants.map((name) => ({ value: name, label: name.endsWith('-ts') ? 'TypeScript' : 'JavaScript' })),
    }))
  }

  const agent = process.env.npm_config_user_agent?.split('/')[0]
  const packageManager = ['npm', 'pnpm', 'yarn', 'bun'].includes(agent) ? agent : 'npm'
  const staging = await mkdtemp(path.join(tmpdir(), 'create-minip-'))
  try {
    prompts.log.step(`Creating ${template} with create-vite...`)
    await run(process.execPath, [path.join(viteDirectory, 'index.js'), projectName,
      '--template', template, '--no-interactive', '--no-immediate', '--no-rolldown'], staging, true)
    const generated = path.join(staging, projectName)
    await configureProject(generated, template, packageManager)
    await assertEmptyDirectory(directory)
    await mkdir(directory, { recursive: true })
    for (const entry of await readdir(generated)) {
      await cp(path.join(generated, entry), path.join(directory, entry), {
        recursive: true, force: false, errorOnExist: true,
      })
    }
  } finally {
    await rm(staging, { recursive: true, force: true })
  }

  if (!values['no-install']) {
    prompts.log.step(`Installing dependencies with ${packageManager}...`)
    try {
      await run(packageManager, ['install'], directory)
    } catch (error) {
      throw new Error(`Project created at ${directory}, but dependency installation failed. Run ${packageManager} install there to retry.`, { cause: error })
    }
  }
  const relative = path.relative(process.cwd(), directory)
  const quotedDirectory = process.platform === 'win32'
    ? `"${relative}"`
    : `'${relative.replaceAll("'", "'\\''")}'`
  const instructions = [
    ...(relative ? [`cd ${quotedDirectory}`] : []),
    ...(values['no-install'] ? [`${packageManager} install`] : []),
    `${packageManager} run dev`,
  ]
  prompts.outro(`Ready!\n\n  ${instructions.join('\n  ')}\n\nScan the QR code with Minip on the same network for native APIs and hot updates.\nUse ${packageManager} run pack to build and install the app.`)
}

try {
  await main()
} catch (error) {
  console.error(`\n[create-minip] ${error.message}`)
  if (error.cause) console.error(error.cause.message)
  process.exitCode = 1
}
