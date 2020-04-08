import Cocoa
import AVFoundation

class MVTimerController: NSWindowController {

  private var mainView: MVMainView!
  private var clockView: MVClockView!
  
  private var volumeButton: NSButton!
  private var volume:Float = 1
  private var audioPlayer: AVAudioPlayer? // player must be kept in memory

  convenience init() {
    let mainView = MVMainView(frame: NSZeroRect)

    let window = MVWindow(mainView: mainView)

    self.init(window: window)
    
    self.mainView = mainView
    self.mainView.controller = self
    self.clockView = MVClockView()
    self.clockView.target = self
    self.clockView.action = #selector(handleClockTimer)
    self.mainView.addSubview(clockView)
    
    // Add a volume button
    volumeButton = NSButton()
    volumeButton.setButtonType(.momentaryPushIn)
    volumeButton.isBordered = false
    volumeButton.alphaValue = 0.38
    let size = NSSize(width: 28, height: 28)
    volumeButton.frame = NSRect(origin: NSPoint(x: mainView.frame.size.width - size.width, y: mainView.frame.origin.y), size: size)
    volumeButton.target = self
    volumeButton.action = #selector(clickVolumeButton)
    self.setVolume(UserDefaults.standard.float(forKey: MVUserDefaultsKeys.volume))
    self.mainView.addSubview(volumeButton)
    
    self.windowFrameAutosaveName = NSWindow.FrameAutosaveName("TimerWindowAutosaveFrame")
    
    window.makeKeyAndOrderFront(self)    
  }
  
  convenience init(closeToWindow: NSWindow?) {
    self.init()
    
    if closeToWindow != nil {
      var point = closeToWindow!.frame.origin
      point.x += CGFloat(Int(arc4random_uniform(UInt32(80))) - 40)
      point.y += CGFloat(Int(arc4random_uniform(UInt32(80))) - 40)
      self.window?.setFrameOrigin(point)
    }
  }
  
  deinit {
    self.clockView.target = nil
    self.clockView.stop()
  }
  
  func showInDock(_ state: Bool) {
    self.clockView.inDock = state
    self.mainView.menuItem?.state = state ? .on : .off
  }
  
  func windowVisibilityChanged(_ visible:Bool) {
    clockView.windowIsVisible = visible
  }
  
  enum VolumeCategory: Float {
    case off = 0, low = 0.05, medium = 0.25, high = 1
    
    static let allCases = [VolumeCategory.off, .low, .medium, .high]
    
    init(_ volume:Float) {
      for threshold in VolumeCategory.allCases.reversed() {
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
        case .off: return "off"
        case .low:  return "low"
        case .medium:  return "medium"
        case .high:  return "high"
      }
    }
  }
  
  func setVolume(_ volume:Float) {
    self.volume = volume
    
    // Update button image
    let name = "volume-\(VolumeCategory(volume).name)"
    volumeButton.image = NSImage(named: NSImage.Name(rawValue: name))
  }
  
  func playAlarmSound() {
    let soundURL = Bundle.main.url(forResource: "alert-sound", withExtension: "caf")
    audioPlayer = try? AVAudioPlayer(contentsOf: soundURL!)
    audioPlayer?.volume = self.volume
    audioPlayer?.play()
  }
  
  @objc func clickVolumeButton(_ button: NSButton) {
    let newVolume:Float = VolumeCategory(self.volume).next().rawValue
    UserDefaults.standard.set(newVolume, forKey: MVUserDefaultsKeys.volume)
    self.setVolume(newVolume)
    
    //playAlarmSound()
  }
  
  @objc func handleClockTimer(_ clockView: MVClockView) {
    let notification = NSUserNotification()
    notification.title = "It's time! 🕘"
    
    NSUserNotificationCenter.default.deliver(notification)
    
    NSApplication.shared.requestUserAttention(.criticalRequest)
    
    playAlarmSound()
  }
  
  override func keyUp(with theEvent: NSEvent) {
    self.clockView.keyUp(with: theEvent)
  }

  override func keyDown(with event: NSEvent) {
  }

}
