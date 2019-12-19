//
//  Main.swift
//  Xcode Progress
//
//  Created by Anton Heestand on 2019-12-19.
//  Copyright © 2019 Hexagons. All rights reserved.
//

import Foundation
import LiveValues
import RenderKit
import PixelKit

class Main: ObservableObject {
    
    @Published var progress: CGFloat?
 
    var screenCapturePix: ScreenCapturePIX!
    var cropPix: CropPIX!
    var finalPix: PIX!
    
    @Published var activeWindowFrame: CGRect?
    @Published var activeWindowName: String?
    struct Window: Equatable {
        let name: String
        let frame: CGRect
    }
    var currentWindow: Window?
    var windowMoveTimer: Timer?
    var lastFrame: CGRect?
    
    init() {
        setupPixs()
        PixelKit.main.render.listenToFrames(callback: frameLoop)
    }
    
    func setupPixs() {
        screenCapturePix = ScreenCapturePIX()
        cropPix = CropPIX()
        cropPix.input = screenCapturePix
        finalPix = cropPix
    }
    
    func frameLoop() {
        if let window = windows().first {
            if self.currentWindow != window {
                if activeWindowName != window.name {
                    activeWindowName = window.name
                }
                if activeWindowFrame != window.frame {
                    self.activeWindowFrame = nil
                    windowMoveTimer?.invalidate()
                    windowMoveTimer = Timer(timeInterval: 0.1, repeats: false, block: { _ in
                        guard let windowFrame = self.currentWindow?.frame else { return }
                        self.activeWindowFrame = windowFrame
                        self.crop(with: windowFrame)
                    })
                    RunLoop.current.add(windowMoveTimer!, forMode: .common)
                    self.currentWindow = window
                }
            }
        }
    }
    
    func crop(with windowFrame: CGRect) {
        guard let screen: CGSize = NSScreen.main?.frame.size else { return }
        let x: CGFloat = (windowFrame.minX + windowFrame.maxX) / 2 - 256 - windowFrame.minX
        let cropFrame: CGRect = CGRect(x: x, y: 8, width: 512, height: 22)
        let progressFrame: CGRect = crop(frame: windowFrame, with: cropFrame)
        let uvFrame: CGRect = getUVFrame(from: progressFrame, in: screen)
        cropPix.cropFrame = uvFrame
        print("Cropped at \(windowFrame)")
    }
    
    func crop(frame: CGRect, with cropFrame: CGRect) -> CGRect {
        CGRect(x: frame.minX + cropFrame.minX,
               y: frame.minY + cropFrame.minY,
               width: cropFrame.width,
               height: cropFrame.height)
    }
    
    func getUVFrame(from frame: CGRect, in size: CGSize) -> CGRect {
        var uvFrame: CGRect = CGRect(x: frame.minX / size.width,
                                     y: frame.minY / size.height,
                                     width: frame.width / size.width,
                                     height: frame.height / size.height)
        uvFrame = CGRect(x: uvFrame.minX, y: 1.0 - uvFrame.maxY, width: uvFrame.width, height: uvFrame.height)
        return uvFrame
    }
    
    func windows() -> [Window] {

        var windows: [Window] = []
        
        let type = CGWindowListOption.optionOnScreenOnly
        let windowList = CGWindowListCopyWindowInfo(type, kCGNullWindowID) as NSArray? as? [[String: AnyObject]]

        for entry in windowList! {

            let owner = entry[kCGWindowOwnerName as String] as! String
            guard owner == "Xcode" else { continue }

            guard let bounds: [String: Int] = entry[kCGWindowBounds as String] as? [String: Int] else { continue }
            guard let isOnScreen: Bool = entry[kCGWindowIsOnscreen as String] as? Bool else { continue }
            guard let name: String = entry[kCGWindowName as String] as? String else { continue }

            guard isOnScreen else { continue }

            guard let x: Int = bounds["X"] else { continue }
            guard let y: Int = bounds["Y"] else { continue }
            guard let w: Int = bounds["Width"] else { continue }
            guard let h: Int = bounds["Height"] else { continue }

            let frame: CGRect = CGRect(x: x, y: y, width: w, height: h)
            
            windows.append(Window(name: name, frame: frame))

        }

        return windows

    }
    
}
