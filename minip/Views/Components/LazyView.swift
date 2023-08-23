//
//  LazyView.swift
//  minip
//
//  Created by ByteDance on 2023/8/8.
//

import SwiftUI

struct LazyView<Content: View>: View {
    var content: () -> Content
    var body: some View {
        self.content()
    }
}
