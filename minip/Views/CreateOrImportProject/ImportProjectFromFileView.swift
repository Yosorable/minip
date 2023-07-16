//
//  ImportProjectFromFileView.swift
//  minip
//
//  Created by ByteDance on 2023/7/14.
//

import SwiftUI

struct ImportProjectFromFileView: View {
    var onSuccess: (()->Void)?
    var body: some View {
        FileImporterView(onSuccess: onSuccess)
            .edgesIgnoringSafeArea(.all)
    }
}
