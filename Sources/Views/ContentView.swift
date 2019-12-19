//
//  ContentView.swift
//  Xcode Progress
//
//  Created by Anton Heestand on 2019-12-19.
//  Copyright © 2019 Hexagons. All rights reserved.
//

import SwiftUI
import RenderKit

struct ContentView: View {
    @EnvironmentObject var main: Main
    var body: some View {
        VStack {
            Spacer()
            Text(main.activeWindowName ?? "")
            NODERepView(node: main.finalPix)
                .aspectRatio(CGSize(width: 1024, height: 44), contentMode: .fit)
                .opacity(main.activeWindowFrame != nil ? 1.0 : 0.0)
            Spacer()
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(Main())
    }
}
