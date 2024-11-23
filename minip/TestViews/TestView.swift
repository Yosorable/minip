//
//  TestView.swift
//  minip
//
//  Created by LZY on 2024/8/6.
//

import SwiftUI

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
            }
        }
}
