//
//  JSCoreTestView.swift
//  minip
//
//  Created by ByteDance on 2023/7/11.
//

import SwiftUI
import JavaScriptCore

struct JSCoreTestView: View {
    @State var input = {
    let defaultRes = """
function fib(n) {
    if (n <= 2)
        return 1
    return fib(n - 1) + fib(n-2)
}

const start = Date.now()
const res = fib(40)
const end = Date.now()
console.log(`res: ${res}, cost: ${(end - start) / 1000}`)
end - start123
"""
    
    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let playgroundPath = documentsURL.appendingPathComponent("playground")
    
    let fileURL = playgroundPath.appendingPathComponent("test.js")
    
    let (exist, isFolder) = fileOrFolderExists(path: playgroundPath.path)
    if !exist {
        mkdir(path: playgroundPath.path)
        touch(path: fileURL.path, content: defaultRes.data(using: .utf8))
        return defaultRes
    } else if isFolder {
        let (e, isF) = fileOrFolderExists(path: fileURL.path)
        if !e {
            touch(path: fileURL.path, content: defaultRes.data(using: .utf8))
            return defaultRes
        } else if !isF {
            return cat(url: fileURL)
        }
    }
    
    return defaultRes
}()
    @State var outputs = [ResultInfo]()
    @State var showRes = false
    @State var isRunning = false
    @State var currentJSContext: JSContext? = nil
    var entryFolder: URL? = nil
    
    struct ResultInfo: Identifiable {
        var id = UUID()
        var type: ResultType
        var content: String
        enum ResultType {
            case Number
            case Undefined
            case Null
            case String
            case Error
            case ErrorPosition
        }
    }
    
    
    var body: some View {
        VStack{
            CodeEditorV2View(contentString: $input, language: .javaScript)
                .onChange(of: input, perform: { str in
                    print("save")
                    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let playgroundPath = documentsURL.appendingPathComponent("playground")
                    
                    let fileURL = playgroundPath.appendingPathComponent("test.js")
                    saveFile(url: fileURL, content: str)
                })
                .edgesIgnoringSafeArea(.all)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            showRes = true
                        } label: {
                            Image(systemName: "pc")
                                .foregroundColor(.secondary)
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            if !isRunning {
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                outputs.removeAll()
                                showRes = true
                                isRunning = true
                                DispatchQueue.global(qos: .userInteractive).async {
                                    let context = createJSContext()
                                    let res = context?.evaluateScript(input, withSourceURL: URL(string: "index.js"))
                                    DispatchQueue.main.async {
                                        isRunning = false
                                        currentJSContext = context
                                        if let resStr = res?.toString() {
                                            outputs.append(ResultInfo(type: .String, content: resStr))
                                        }
                                    }
                                }
                            } else {
                                ShowNotImplement()
                            }
                        } label: {
                            Image(systemName: isRunning ? "xmark.square" : "play")
                                .foregroundColor(.green)
                                .frame(width: 25)
                        }
                    }
                }
                .navigationTitle(Text("playground"))
                .navigationBarTitleDisplayMode(.inline)
            
            
                .navigationDestination(isPresented: $showRes) {
                    resultView()
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button {
                                    if !isRunning {
                                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                        outputs.removeAll()
                                        showRes.toggle()
                                        isRunning = true
                                        DispatchQueue.global().async {
                                            let context = createJSContext()
                                            let res = context?.evaluateScript(input, withSourceURL: URL(string: "index.js"))
                                            DispatchQueue.main.async {
                                                isRunning = false
                                                currentJSContext = context
                                                if let resStr = res?.toString() {
                                                    outputs.append(ResultInfo(type: .String, content: resStr))
                                                }
                                            }
                                        }
                                    } else {
                                        ShowNotImplement()
                                    }
                                } label: {
                                    Image(systemName: isRunning ? "xmark.square" : "play")
                                        .foregroundColor(.green)
                                        .frame(width: 25)
                                }
                            }
                        }
                }
        }
    }
    
    func resultView() -> some View {
        ScrollView {
            VStack(alignment: .leading) {
                ForEach(outputs, id: \.id) { ele in
                    HStack {
                        Text(ele.content)
                            .foregroundColor({
                                switch ele.type {
                                case .Error:
                                    return .red
                                case .ErrorPosition:
                                    return .secondary
                                default:
                                    return .primary
                                }
                            }())
                        Spacer()
                    }
                    
                }
            }
        }
    }
    
    func createJSContext() -> JSContext? {
        guard let context = JSContext() else {
            return nil
        }
        
        addConsole(to: context)
        addRequire(to: context, entryFolder: entryFolder)
        
        return context
    }
    
    func addConsole(to context: JSContext) {
        let callback: @convention(block) (String?) -> Void = {
            if let msg = $0 {
                DispatchQueue.main.async {
                    outputs.append(ResultInfo(type: .String, content: msg))
                }
            }
            print("[JavaScriptCore]: \($0 ?? "undefined")")
        }
        context.setObject(callback, forKeyedSubscript: "_consoleLog" as NSCopying & NSObjectProtocol)
        context.exceptionHandler = { ctx, val in
            // type of String
            let stacktrace = val?.objectForKeyedSubscript("stack").toString()
            // type of Number
            //            let lineNumber = val?.objectForKeyedSubscript("line").toString()
            // type of Number
            //            let column = val?.objectForKeyedSubscript("column").toString()
            let moreInfo = "in method \(stacktrace ?? "")"
            if let err = val?.toString() {
                DispatchQueue.main.async {
                    outputs.append(ResultInfo(type: .Error, content: err))
                    outputs.append(ResultInfo(type: .ErrorPosition, content: moreInfo))
                }
            }
        }
        context.evaluateScript("""
                            const console = {
                                log: (...message) => {
                                    _consoleLog(message.join(" "))
                                }
                            }
                            """)
    }
    
    func addRequire(to context: JSContext, entryFolder: URL?) {
        let callback: (String) -> JSValue = { jsName in
            // 这里只关注了在 target 里面的 js 导入情况
            // 在实际业务中, 一般来说这些 js 导入的操作应该是作为类似插件的效果, 存放在 document 等文件夹内
            // 此时应该用 FileManager 进行操作获取相关路径
            var moduleName = jsName
            if (jsName.hasSuffix(".js")) {
                moduleName = jsName.replacingOccurrences(of: ".js", with: "")
            }
            //            let path = Bundle.main.path(forResource: moduleName, ofType: "js") ?? ""
            let path = entryFolder?.appending(component: moduleName).path ?? "unknown"
            
            let moduleContent = try? String(contentsOfFile: path, encoding: .utf8)
            // 模仿 nodejs 的 require 实现原理
            // 简单来说, 就是将 js 文件内容包裹在一个函数内, 对外导出 module.exports
            // 借助 evaluateScript 功能, 很好实现
            let js = """
                (() => {
                    let module = {}
                    module.exports = {}
                    let exports = module.exports
                    \(moduleContent ?? "")
                    return module.exports
                })()
                """
            return context.evaluateScript(js, withSourceURL: URL(string: moduleName))
        }
        context.setObject(callback, forKeyedSubscript: "require" as NSCopying & NSObjectProtocol)
    }
}
