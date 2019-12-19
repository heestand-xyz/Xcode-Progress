//
//  ProgressCircleView.swift
//  Xcode Progress
//
//  Created by Anton Heestand on 2019-12-19.
//  Copyright © 2019 Hexagons. All rights reserved.
//

import SwiftUI

struct ProgressCircleView: View {
    @Binding var fraction: CGFloat
    var body: some View {
        ZStack {
            Circle()
                .foregroundColor(.primary)
                .opacity(0.1)
            GeometryReader { geo in
                Path { path in
                    let w = geo.size.width
                    path.move(to: CGPoint(x: w / 2, y: w / 2))
                    path.addArc(center: CGPoint(x: w / 2, y: w / 2),
                                radius: w / 2,
                                startAngle: Angle(radians: -.pi / 2),
                                endAngle: Angle(radians: -.pi / 2 + Double(self.fraction) * .pi * 2),
                                clockwise: false)
                }
                .foregroundColor(.accentColor)
            }
            .aspectRatio(1.0, contentMode: .fit)
        }
    }
}

struct ProgressCircleView_Previews: PreviewProvider {
    static var previews: some View {
        ProgressCircleView(fraction: .constant(0.75))
            .environmentObject(Main())
    }
}
