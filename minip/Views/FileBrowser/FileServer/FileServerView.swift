//
//  FileServerView.swift
//  minip
//
//  Created by LZY on 2025/3/28.
//

import SwiftUI

struct FileServerView: View {
    var body: some View {
        NavigationView {
            List {
                Section {} header: {
                    Text("Network")
                } footer: {}
                Button {} label: {
                    HStack {
                        Spacer()
                        Text("Start")
                        Spacer()
                    }
                }
            }
            .navigationBarTitle(Text("File Server"), displayMode: .inline)
        }
    }
}
