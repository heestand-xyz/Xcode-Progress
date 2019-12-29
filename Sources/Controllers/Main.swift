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
import SwiftUI

class Main: ObservableObject, NODEDelegate {
    
    static let infoFrame: CGRect = CGRect(x: 0, y: 8, width: 512, height: 22)
    static let alertWarningColor: LiveColor = LiveColor(hex: "f6c644")
    static let alertWarningDimColor: LiveColor = LiveColor(hex: "a18841")
    static let alertErrorColor: LiveColor = LiveColor(hex: "ce3227")
    static let alertErrorDimColor: LiveColor = LiveColor(hex: "8c3632")
    
    @Published var progress: CGFloat?
    @Published var hasWarning: Bool?
    @Published var hasError: Bool?
    
    var ocrInProgress: Bool = false
    @Published var infoText: String?
 
    var screenCapturePix: ScreenCapturePIX!
    var infoPix: CropPIX!
    var progressPix: CropPIX!
    var textPix: CropPIX!
    var alertPix: CropPIX!
    var finalPix: PIX!
    
    @Published var activeWindowFrame: CGRect?
    struct Window: Equatable {
        let name: String
        let frame: CGRect
    }
    var currentWindow: Window?
    var windowMoveTimer: Timer?
    var lastFrame: CGRect?
    
    let ocr: SLTesseract
    
    init() {
        ocr = SLTesseract()
        setupPixs()
        PixelKit.main.render.listenToFrames(callback: frameLoop)
    }
    
    func setupPixs() {
        screenCapturePix = ScreenCapturePIX()
        infoPix = CropPIX()
        infoPix.input = screenCapturePix
        progressPix = CropPIX()
        progressPix.input = screenCapturePix
        progressPix.delegate = self
        textPix = CropPIX()
        textPix.input = screenCapturePix
        textPix.delegate = self
        alertPix = CropPIX()
        alertPix.input = screenCapturePix
        alertPix.delegate = self
        finalPix = infoPix
    }
    
    func frameLoop() {
        if let window = windows().first {
            if self.currentWindow != window {
                if activeWindowFrame != window.frame {
                    clear()
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
    
    func clear() {
        activeWindowFrame = nil
        progress = nil
        hasWarning = nil
        hasError = nil
        infoText = nil
    }
    
    func nodeDidRender(_ node: NODE) {
        guard activeWindowFrame != nil else { return }
        if node.id == progressPix.id {
            
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
            progress = fraction
         
        } else if node.id == textPix.id {
            
            guard !ocrInProgress else { return }
            
            guard let image: NSImage = textPix.renderedImage else {
                infoText = nil
                return
            }
            
            ocrInProgress = true
            DispatchQueue.global(qos: .background).async {
                let text = self.ocr.recognize(image)
                DispatchQueue.main.async {
                    self.infoText = text
                    self.ocrInProgress = false
                }
            }
            
        } else if node.id == alertPix.id {
            
            guard let pixels: PIX.PixelPack = alertPix.renderedPixels else {
                hasWarning = nil
                hasError = nil
                return
            }
            
            var hasWarning: Bool = false
            var hasError: Bool = false
            for pixel in pixels.raw[0] {
                let dist: LiveFloat = 0.25
                if (similar(a: pixel.color, b: Main.alertWarningColor, by: dist) ||
                    similar(a: pixel.color, b: Main.alertWarningDimColor, by: dist)).val {
                    hasWarning = true
                } else if (similar(a: pixel.color, b: Main.alertErrorColor, by: dist) ||
                    similar(a: pixel.color, b: Main.alertErrorDimColor, by: dist)).val {
                    hasError = true
                }
            }
            self.hasWarning = hasWarning
            self.hasError = hasError
        }
    }
    
    func crop(with windowFrame: CGRect) {

        guard let screen: CGSize = NSScreen.main?.frame.size else { return }

        let x: CGFloat = (windowFrame.minX + windowFrame.maxX) / 2 - (Main.infoFrame.width / 2) - windowFrame.minX
        let cropFrame: CGRect = CGRect(x: x, y: Main.infoFrame.minY, width: Main.infoFrame.width, height: Main.infoFrame.height)
        let infoFrame: CGRect = crop(frame: windowFrame, with: cropFrame)
        let uvFrame: CGRect = getUVFrame(from: infoFrame, in: screen)
        infoPix.cropFrame = uvFrame

        let cropProgressFrame: CGRect = CGRect(x: x + 1, y: cropFrame.minY + cropFrame.height - 2, width: cropFrame.width - 2, height: 1)
        let progressFrame: CGRect = crop(frame: windowFrame, with: cropProgressFrame)
        let uvProgressFrame: CGRect = getUVFrame(from: progressFrame, in: screen)
        progressPix.cropFrame = uvProgressFrame

        let cropTextFrame: CGRect = CGRect(x: x + 5, y: cropFrame.minY + 3, width: cropFrame.width - 95, height: cropFrame.height - 6)
        let textFrame: CGRect = crop(frame: windowFrame, with: cropTextFrame)
        let uvTextFrame: CGRect = getUVFrame(from: textFrame, in: screen)
        textPix.cropFrame = uvTextFrame

        let cropAlertFrame: CGRect = CGRect(x: cropFrame.maxX - 100, y: cropFrame.minY + cropFrame.height / 2, width: 100, height: 1)
        let alertFrame: CGRect = crop(frame: windowFrame, with: cropAlertFrame)
        let uvAlertFrame: CGRect = getUVFrame(from: alertFrame, in: screen)
        alertPix.cropFrame = uvAlertFrame
        
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
        
        print(">>>")

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
            
            print(frame)
            
            /// Block Popups
            guard frame.size.width > 300 && frame.size.height > 300 else { continue }
            
//            /// Block non main screen
//            guard let windowFrame = NSScreen.main?.frame else { continue }
//            guard windowFrame.contains(CGPoint(x: frame.midX, y: frame.midY)) else { continue }
            
            windows.append(Window(name: name, frame: frame))

        }

        return windows

    }
    
    func similar(a colorA: LiveColor, b colorB: LiveColor, by value: LiveFloat) -> LiveBool {
        let rDiff: LiveFloat = colorA.r - colorB.r
        let gDiff: LiveFloat = colorA.g - colorB.g
        let bDiff: LiveFloat = colorA.b - colorB.b
        let aDiff: LiveFloat = colorA.a - colorB.a
        func getDist(_ a: LiveFloat, _ b: LiveFloat) -> LiveFloat {
            sqrt(pow(a, 2) + pow(b, 2))
        }
        let rgDiff: LiveFloat = getDist(rDiff, gDiff)
        let rgbDiff: LiveFloat = getDist(rgDiff, bDiff)
        let rgbaDiff: LiveFloat = getDist(rgbDiff, aDiff)
        return rgbaDiff < value
    }
    
}
