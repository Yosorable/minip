//
//  SettingsView.swift
//  minip
//
//  Created by ByteDance on 2023/7/14.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    CodeView()
                } label: {
                    Text("Playgrounds")
                }
                
                    Button {
                        PreviewImage(url: URL(string: "https://img0.baidu.com/it/u=1724694977,4042951717&fm=253&fmt=auto&app=120&f=JPEG?w=1280&h=800"))
                    } label: {
                        Text("prevuiew")
                    }
            }
            .navigationTitle(Text("Settings"))
        }
    }
}

struct CodeView: View {
    @State var selectedLanguage = 0
    var body: some View {
//        NavigationStack {
            ZStack {
                if selectedLanguage == 0 {
                    JSCoreTestView()
                } else if selectedLanguage == 1 {
                    PyTestView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Picker("What is your favorite language?", selection: $selectedLanguage) {
                        Text("js").tag(0)
                        Text("py").tag(1)
                    }
                    .pickerStyle(.segmented)
                }
            }
//        }
        
    }
}
