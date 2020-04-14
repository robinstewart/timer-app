//
//  MVVolumeControl.swift
//  Timer
//
//  Created by Robin Stewart on 4/13/20.
//  Copyright © 2020 Michael Villar. All rights reserved.
//

import Cocoa

/// Volume thresholds corresponding to the four image states
enum VolumeCategory: Float, CaseIterable {
  case high = 1
  case medium = 0.25
  case low = 0.05
  case off = 0

  init(_ volume:Float) {
    for threshold in VolumeCategory.allCases {
      if volume >= threshold.rawValue {
        self = threshold
        return
      }
    }
    self = .high // default
  }
  
  func next() -> VolumeCategory {
    switch self {
      case .high:  return .medium
      case .medium:  return .low
      case .low:  return .off
      case .off: return .high
    }
  }
  
  var name: String {
    switch self {
      case .high:  return "high"
      case .medium:  return "medium"
      case .low:  return "low"
      case .off: return "off"
    }
  }
}

// MARK: -

class MVVolumeControl: NSButton {
  
  var volume:Float = 1
  
  // Set up
  override func viewDidMoveToSuperview() {
    guard let superview = self.superview  else { return } // Setup only
    
    self.setButtonType(.momentaryChange)
    self.isBordered = false
    
    let size = NSSize(width: 27, height: 27)
    let upRight = NSPoint(x: superview.frame.maxX, y: superview.frame.maxY)
    self.frame = NSRect(origin: NSPoint(x: upRight.x - size.width, y: upRight.y - size.height), size: size)
    
    self.target = self
    self.action = #selector(clickVolumeButton)
    
    self.setVolume(UserDefaults.standard.float(forKey: MVUserDefaultsKeys.volume))
  }
  
  @objc func clickVolumeButton(_ button: NSButton) {
    let newVolume:Float = VolumeCategory(self.volume).next().rawValue
    UserDefaults.standard.set(newVolume, forKey: MVUserDefaultsKeys.volume)
    self.setVolume(newVolume)
    
    //playAlarmSound()
  }
  
  func setVolume(_ volume:Float) {
    self.volume = volume
    updateImages()
  }
  
  func updateImages() {
    self.image = image(for: VolumeCategory(volume))
    self.alternateImage = image(for: VolumeCategory(volume), isAlternate: true)
  }
  
  func image(for category: VolumeCategory, isAlternate: Bool = false) -> NSImage? {
    guard let baseImage = NSImage(named: "volume-\(category.name)")
      else { return nil }
    
    func imageColor() -> NSColor {
      if #available(OSX 10.13, *) {
        return isAlternate ? NSColor(named: "control-pressed-tint-color")! : NSColor(named: "control-tint-color")!
      }
      return NSColor(white: 0, alpha: isAlternate ? 0.4 : 0.2)
    }
    
    return tintedImage(baseImage, colorFunc: imageColor)
  }
}

func tintedImage(_ image: NSImage, colorFunc: @escaping ()->NSColor) -> NSImage {
  // Create an image that automatically redraws when the system appearance changes
  return NSImage(size: image.size, flipped: false) { (dstRect) -> Bool in
    let color = colorFunc()
    
    image.draw(in: dstRect, from: dstRect, operation: .sourceOver, fraction: color.alphaComponent)
    
    color.withAlphaComponent(1).set()
    dstRect.fill(using: .sourceAtop)
    return true
  }
}
