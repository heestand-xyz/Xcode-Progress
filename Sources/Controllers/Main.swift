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

class Main: ObservableObject, NODEDelegate {
    
    static let infoFrame: CGRect = CGRect(x: 0, y: 8, width: 512, height: 22)
    
    @Published var progress: CGFloat?
 
    var screenCapturePix: ScreenCapturePIX!
    var cropPix: CropPIX!
    var progressPix: CropPIX!
    var finalPix: PIX!
    
    @Published var activeWindowFrame: CGRect?
//    @Published var activeWindowName: String?
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
        progressPix = CropPIX()
        progressPix.input = screenCapturePix
        progressPix.delegate = self
        finalPix = cropPix
    }
    
    func frameLoop() {
        if let window = windows().first {
            if self.currentWindow != window {
//                if activeWindowName != window.name {
//                    activeWindowName = window.name
//                }
                if activeWindowFrame != window.frame {
                    self.activeWindowFrame = nil
                    self.progress = nil
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
    
    func nodeDidRender(_ node: NODE) {
        guard node.id == progressPix.id else { return }
        guard activeWindowFrame != nil else { return }
        guard let pixels: PIX.PixelPack = progressPix.renderedPixels else {
            progress = nil
            return
        }
        let width: Int = pixels.resolution.w
        var index: Int = 0
        for (i, pixel) in pixels.raw[0].enumerated() {
            if pixel.color.sat.cg > 0.5 {
                index = i
            } else {
                break
            }
        }
        let fraction: CGFloat = CGFloat(index) / CGFloat(width - 1)
        print(index, width, fraction)
        progress = fraction
    }
    
    func crop(with windowFrame: CGRect) {

        guard let screen: CGSize = NSScreen.main?.frame.size else { return }

        let x: CGFloat = (windowFrame.minX + windowFrame.maxX) / 2 - (Main.infoFrame.width / 2) - windowFrame.minX
        let cropFrame: CGRect = CGRect(x: x, y: Main.infoFrame.minY, width: Main.infoFrame.width, height: Main.infoFrame.height)
        let infoFrame: CGRect = crop(frame: windowFrame, with: cropFrame)
        let uvFrame: CGRect = getUVFrame(from: infoFrame, in: screen)
        cropPix.cropFrame = uvFrame

        let cropProgressFrame: CGRect = CGRect(x: x + 1, y: cropFrame.minY + cropFrame.height - 2, width: cropFrame.width - 2, height: 1)
        let progressFrame: CGRect = crop(frame: windowFrame, with: cropProgressFrame)
        let uvProgessFrame: CGRect = getUVFrame(from: progressFrame, in: screen)
        progressPix.cropFrame = uvProgessFrame
        
        print("Cropped from \(windowFrame)")
        
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
            
            /// Block Popups
            guard frame.size.width > 300 && frame.size.height > 300 else { continue }
            
            windows.append(Window(name: name, frame: frame))

        }

        return windows

    }
    
}
