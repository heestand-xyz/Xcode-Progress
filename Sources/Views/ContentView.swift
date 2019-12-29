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
            GeometryReader { geo in
                HStack {
                    Spacer()
                    Text(self.main.infoText ?? "")
                        .font(.system(size: geo.size.width / 50, weight: .regular, design: .monospaced))
                    Spacer()
                }
                    .layoutPriority(-1)
            }
                .frame(height: 100)
            Spacer()
            ZStack {
                Circle()
                    .foregroundColor({
                        if self.main.infoText != nil && main.progress == 0.0 {
                            if self.main.infoText!.contains("Failed") {
                                return .red
                            } else if self.main.infoText!.contains("Succeeded") {
                                return .green
                            }
                        }
                        return .clear
                    }())
                    .aspectRatio(1.0, contentMode: .fit)
                if main.progress != nil {
                    ProgressCircleView(fraction: Binding<CGFloat>(get: { self.main.progress! }, set: { _ in }))
                }
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
