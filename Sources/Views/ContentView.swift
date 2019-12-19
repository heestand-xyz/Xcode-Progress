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
        VStack(spacing: 10) {
            NODERepView(node: main.finalPix)
                .frame(width: Main.infoFrame.width, height: Main.infoFrame.height)
                .opacity(main.activeWindowFrame != nil ? 1.0 : 0.0)
            Spacer()
            if main.progress != nil {
                ProgressCircleView(fraction: Binding<CGFloat>(get: { self.main.progress! }, set: { _ in }))                
            }
            Spacer()
            HStack {
                Circle()
                    .foregroundColor(.yellow)
                    .opacity(main.hasWarning == true ? 1.0 : 0.0)
                    .aspectRatio(1.0, contentMode: .fit)
                Spacer()
                Circle()
                    .foregroundColor(.red)
                    .opacity(main.hasError == true ? 1.0 : 0.0)
                    .aspectRatio(1.0, contentMode: .fit)
            }
                .frame(height: 50)
        }
            .padding()
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(Main())
    }
}
