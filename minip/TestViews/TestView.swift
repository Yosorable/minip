//
//  TestView.swift
//  minip
//
//  Created by LZY on 2024/8/6.
//

import SwiftUI
import WebKit

struct TestView: View {
    @State var num = 45
    @State var res = ""
    @State var isRunning = false
    
    func fibonacci(_ n: Int) -> Int {
        if n <= 1 {
            return n
        } else {
            return fibonacci(n - 1) + fibonacci(n - 2)
        }
    }
    
    let formatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            return formatter
        }()

        var body: some View {
            VStack {
                Text(res)
                TextField("Enter number", value: $num, formatter: formatter)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button {
                    isRunning = true
                    
                    let startTime = Date()
                    let result = fibonacci(num)
                    let endTime = Date()
                    let elapsedTime = endTime.timeIntervalSince(startTime)
                    res = "res: \(result), cost: \(elapsedTime) s"
                    isRunning = false
                } label: {
                    Text("run fib \(num)")
                }.disabled(isRunning)
                
                Button {
                    let vc = UINavigationController(rootViewController: TestViewController())
                    vc.overrideUserInterfaceStyle = .light
                    vc.modalPresentationStyle = .fullScreen
                    GetTopViewController()?.present(vc, animated: true)
                } label: {
                    Text("test webview")
                }
            }
        }
}

class TestViewController: UIViewController {
    var webview: WKWebView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItems = [
            UIBarButtonItem(
                image: UIImage(systemName: "chevron.left"), style: .done, target: self, action: #selector(back)
            )
        ]
        
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(
                image: UIImage(systemName: "xmark"), style: .done, target: self, action: #selector(close)
            ),
            UIBarButtonItem(
                image: UIImage(systemName: "arrow.clockwise"), style: .done, target: self, action: #selector(refresh)
            )
        ]
        
        self.webview = WKWebView()
        self.title = "Test WebView"
        self.view = webview
        loadHtml()
        
    }
    
    @objc
    func close() {
        self.dismiss(animated: true)
    }
    
    @objc
    func refresh() {
        loadHtml()
    }
    
    @objc
    func back() {
        if webview.canGoBack {
            webview.goBack()
        }
    }
    
    func loadHtml() {
        webview.loadHTMLString("""
<html>
<head>
<meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=0" />
</head>
<body>
    <h1>Hello, world!</h1>
    <div id="res"></div>
    <button onclick="runFib()">run fibonacci 45</button>
    <script>
    const resDiv = document.querySelector("#res")
    resDiv.innerText = window.location.href

    
window.onerror = function(e) {
    resDiv.innerText = e.message
}

    function fib(n) {
        if (n <= 2)
            return 1
        return fib(n - 1) + fib(n-2)
    }

    function runFib() {
        const start = Date.now()
        const res = fib(45)
        const end = Date.now()
        resDiv.innerText = `res: ${res}, cost: ${(end - start) / 1000}`
    }
    </script>
</body>
</html>
""", baseURL: nil)
    }
}
