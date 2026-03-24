//
//  JSBridge.swift
//  minip
//

import Foundation
import JavaScriptCore

class JSBridge {
    private var context: JSContext!
    private let queue = DispatchQueue(label: "com.minip.jsBridge", qos: .userInitiated)
    private var isReady = false

    init() {
        // Create JSContext and load bundles entirely on the background queue
        queue.async { [weak self] in
            guard let self else { return }
            let ctx = JSContext()!
            ctx.exceptionHandler = { _, exception in
                if let err = exception?.toString() {
                    print("[JSBridge] JS Exception: \(err)")
                }
            }
            self.context = ctx
            self.injectPolyfills()
            self.loadBundles()
            self.isReady = true
        }
    }

    private func injectPolyfills() {
        let polyfills = """
        // console polyfill
        if (typeof console === 'undefined') {
            var console = {};
        }
        console.log = function() {};
        console.warn = function() {};
        console.error = function() {};
        console.info = function() {};

        // setTimeout/clearTimeout stubs (synchronous)
        if (typeof globalThis.setTimeout === 'undefined') {
            globalThis.setTimeout = function(fn, delay) {
                if (typeof fn === 'function') fn();
                return 0;
            };
        }
        if (typeof globalThis.clearTimeout === 'undefined') {
            globalThis.clearTimeout = function() {};
        }
        if (typeof globalThis.setInterval === 'undefined') {
            globalThis.setInterval = function() { return 0; };
        }
        if (typeof globalThis.clearInterval === 'undefined') {
            globalThis.clearInterval = function() {};
        }

        // TextEncoder / TextDecoder polyfill
        if (typeof globalThis.TextEncoder === 'undefined') {
            globalThis.TextEncoder = function() {};
            globalThis.TextEncoder.prototype.encode = function(str) {
                var arr = [];
                for (var i = 0; i < str.length; i++) {
                    var c = str.charCodeAt(i);
                    if (c < 128) {
                        arr.push(c);
                    } else if (c < 2048) {
                        arr.push((c >> 6) | 192);
                        arr.push((c & 63) | 128);
                    } else {
                        arr.push((c >> 12) | 224);
                        arr.push(((c >> 6) & 63) | 128);
                        arr.push((c & 63) | 128);
                    }
                }
                return arr;
            };
        }
        if (typeof globalThis.TextDecoder === 'undefined') {
            globalThis.TextDecoder = function() {};
            globalThis.TextDecoder.prototype.decode = function(arr) {
                var str = '';
                for (var i = 0; i < arr.length; i++) {
                    str += String.fromCharCode(arr[i]);
                }
                return str;
            };
        }

        // URL stub
        if (typeof globalThis.URL === 'undefined') {
            globalThis.URL = function(url) { this.href = url; this.toString = function() { return url; }; };
        }
        """
        context.evaluateScript(polyfills)
    }

    private func loadBundles() {
        loadBundle(named: "htmlLanguageService")
        loadBundle(named: "cssLanguageService")
        loadBundle(named: "jsLanguageService")
    }

    private func loadBundle(named name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "js", subdirectory: "LanguageServiceBundles") ??
                Bundle.main.url(forResource: name, withExtension: "js") else {
            print("[JSBridge] Bundle not found: \(name).js")
            return
        }
        do {
            let code = try String(contentsOf: url, encoding: .utf8)
            context.evaluateScript(code)
        } catch {
            print("[JSBridge] Failed to load \(name).js: \(error)")
        }
    }

    // MARK: - HTML

    func htmlValidate(uri: String, text: String, completion: @escaping (String?) -> Void) {
        queue.async { [weak self] in
            guard let self, self.isReady else { completion(nil); return }
            let result = self.context
                .objectForKeyedSubscript("HTMLLanguageService")
                .objectForKeyedSubscript("doValidation")
                .call(withArguments: [uri, text])
                .toString()
            DispatchQueue.main.async { completion(result) }
        }
    }

    func htmlComplete(uri: String, text: String, line: Int, character: Int, completion: @escaping (String?) -> Void) {
        queue.async { [weak self] in
            guard let self, self.isReady else { completion(nil); return }
            let result = self.context
                .objectForKeyedSubscript("HTMLLanguageService")
                .objectForKeyedSubscript("doComplete")
                .call(withArguments: [uri, text, line, character])
                .toString()
            DispatchQueue.main.async { completion(result) }
        }
    }

    func htmlSignatureHelp(uri: String, text: String, line: Int, character: Int, completion: @escaping (String?) -> Void) {
        queue.async { [weak self] in
            guard let self, self.isReady else { completion(nil); return }
            let result = self.context
                .objectForKeyedSubscript("HTMLLanguageService")
                .objectForKeyedSubscript("doSignatureHelp")
                .call(withArguments: [uri, text, line, character])
                .toString()
            DispatchQueue.main.async { completion(result) }
        }
    }

    func htmlHover(uri: String, text: String, line: Int, character: Int, completion: @escaping (String?) -> Void) {
        queue.async { [weak self] in
            guard let self, self.isReady else { completion(nil); return }
            let result = self.context
                .objectForKeyedSubscript("HTMLLanguageService")
                .objectForKeyedSubscript("doHover")
                .call(withArguments: [uri, text, line, character])
                .toString()
            DispatchQueue.main.async { completion(result) }
        }
    }

    // MARK: - CSS

    func cssComplete(uri: String, text: String, line: Int, character: Int, completion: @escaping (String?) -> Void) {
        queue.async { [weak self] in
            guard let self, self.isReady else { completion(nil); return }
            let result = self.context
                .objectForKeyedSubscript("CSSLanguageService")
                .objectForKeyedSubscript("doComplete")
                .call(withArguments: [uri, text, line, character])
                .toString()
            DispatchQueue.main.async { completion(result) }
        }
    }

    func cssHover(uri: String, text: String, line: Int, character: Int, completion: @escaping (String?) -> Void) {
        queue.async { [weak self] in
            guard let self, self.isReady else { completion(nil); return }
            let result = self.context
                .objectForKeyedSubscript("CSSLanguageService")
                .objectForKeyedSubscript("doHover")
                .call(withArguments: [uri, text, line, character])
                .toString()
            DispatchQueue.main.async { completion(result) }
        }
    }

    // MARK: - JavaScript

    func jsComplete(uri: String, text: String, line: Int, character: Int, completion: @escaping (String?) -> Void) {
        queue.async { [weak self] in
            guard let self, self.isReady else { completion(nil); return }
            let result = self.context
                .objectForKeyedSubscript("JSLanguageService")
                .objectForKeyedSubscript("doComplete")
                .call(withArguments: [uri, text, line, character])
                .toString()
            DispatchQueue.main.async { completion(result) }
        }
    }

    func jsSignatureHelp(uri: String, text: String, line: Int, character: Int, completion: @escaping (String?) -> Void) {
        queue.async { [weak self] in
            guard let self, self.isReady else { completion(nil); return }
            let result = self.context
                .objectForKeyedSubscript("JSLanguageService")
                .objectForKeyedSubscript("doSignatureHelp")
                .call(withArguments: [uri, text, line, character])
                .toString()
            DispatchQueue.main.async { completion(result) }
        }
    }

    func jsValidate(uri: String, text: String, completion: @escaping (String?) -> Void) {
        queue.async { [weak self] in
            guard let self, self.isReady else {
                #if DEBUG
                print("[JSBridge] jsValidate: not ready")
                #endif
                completion(nil); return
            }
            let result = self.context
                .objectForKeyedSubscript("JSLanguageService")
                .objectForKeyedSubscript("doValidation")
                .call(withArguments: [uri, text])
                .toString()
            #if DEBUG
            print("[JSBridge] jsValidate result: \(result?.prefix(200) ?? "nil")")
            #endif
            DispatchQueue.main.async { completion(result) }
        }
    }

    // MARK: - CSS Validation

    func cssValidate(uri: String, text: String, completion: @escaping (String?) -> Void) {
        queue.async { [weak self] in
            guard let self, self.isReady else { completion(nil); return }
            let result = self.context
                .objectForKeyedSubscript("CSSLanguageService")
                .objectForKeyedSubscript("doValidation")
                .call(withArguments: [uri, text])
                .toString()
            DispatchQueue.main.async { completion(result) }
        }
    }
}
