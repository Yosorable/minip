//
//  JSContext++.swift
//  minip
//
//  Created by ByteDance on 2023/7/11.
//

import JavaScriptCore

extension JSContext {
    /// 开启增强模式
    /// 包括 console.log 功能和类似 nodejs 的 require 导入功能
    func enhancementMode(entryFolder: URL) {
        addConsole()
        addReuire(entryFolder: entryFolder)
    }
    
    func addReuire(entryFolder: URL) {
        let context = self
        let callback: (String) -> JSValue = { jsName in
            // 这里只关注了在 target 里面的 js 导入情况
            // 在实际业务中, 一般来说这些 js 导入的操作应该是作为类似插件的效果, 存放在 document 等文件夹内
            // 此时应该用 FileManager 进行操作获取相关路径
            var moduleName = jsName
            if (jsName.hasSuffix(".js")) {
                moduleName = jsName.replacingOccurrences(of: ".js", with: "")
            }
//            let path = Bundle.main.path(forResource: moduleName, ofType: "js") ?? ""
            let path = entryFolder.appending(component: moduleName).path()
            
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
        setObject(callback, forKeyedSubscript: "require" as NSCopying & NSObjectProtocol)
    }
    
    func addConsole() {
        // 注入 js 脚本
        // 用于定义一些全局对象与函数
        
        // 定义一个简易的 console.log 功能
        let js = """
            const console = {
                log: (...message) => {
                    _consoleLog(message.join(" "))
                }
            }
            """
        evaluateScript(js)
        
        // 设置回调提供原生使用, 用于输出打印信息到 Xcode Console
        let callback: @convention(block) (String?) -> Void = {
            print("[JavaScriptCore]: \($0 ?? "undefined")")
        }
        setObject(callback, forKeyedSubscript: "_consoleLog" as NSCopying & NSObjectProtocol)
    }
}
