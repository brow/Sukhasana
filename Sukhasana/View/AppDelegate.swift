//
//  AppDelegate.swift
//  Sukhasana
//
//  Created by Tom Brow on 2/4/15.
//  Copyright (c) 2015 Tom Brow. All rights reserved.
//

import Cocoa
import MASShortcut

@NSApplicationMain
class AppDelegate: NSObject, MainViewControllerDelegate,  NSApplicationDelegate, NSWindowDelegate {
  @IBOutlet var panel: NSPanel!
  
  deinit {
    notificationCenter.removeObserver(statusItemMoveObserver)
  }
  
  @IBAction func didClickStatusItem(sender: AnyObject) {
    if panel.keyWindow {
      panel.close()
    } else {
      // Later in this event loop iteration, the highlight of the status item
      // button is automatically set to false. So if we want to highlight the
      // button, as we do in `windowDidBecomeKey`, we need to ensure that happens
      // in a later iteration.
      dispatch_async(dispatch_get_main_queue()) {
        self.panel.makeKeyAndOrderFront(self)
      }
    }
  }
  
  // MARK: MainViewControllerDelegate
  
  func mainViewControllerDidChangeFittingSize(mainViewController: MainViewController) {
    updatePanelFrame()
  }
  
  // MARK: NSWindowDelegate
  
  func windowDidResignKey(notification: NSNotification) {
    // windowDidResignKey is always called when the window is closed (e.g., by
    // calling panel.close()), so it's a reliable place to un-highlight the 
    // status item.
    statusItem.button?.highlight(false)
    
    // However, the window isn't necessarily closed when it resigns key, so we
    // must ensure here that it closes.
    panel.close()
  }
  
  func windowDidBecomeKey(notification: NSNotification) {
    displayingViewController?.viewDidDisplay()
    self.statusItem.button?.highlight(true)
  }
  
  // MARK: NSApplicationDelegate
  
  func applicationDidFinishLaunching(notification: NSNotification) {
    statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-2 /* NSSquareStatusItemLength */)
    if let button = statusItem.button {
      button.image = NSImage(named: "StatusItemIcon")
      button.alternateImage = NSImage(named: "StatusItemIconHighlighted")
      button.target = self
      button.action = "didClickStatusItem:"
    }
    
    panel.floatingPanel = true
    
    // The status item can move when other items are removed or hidden.
    statusItemMoveObserver = notificationCenter.addObserverForName(
      NSWindowDidMoveNotification,
      object: statusItem.button!.window!,
      queue: nil,
      usingBlock: { [weak self] _ in self?.updatePanelFrame(); return })
    
    model.effects.start { [weak self] effect in
      if let _self = self {
        switch effect {
          
        case .DisplayScreen(let screen):
          _self.displayingViewController = {
            switch screen {
            case .Settings(let model):
              return SettingsViewController(model: model)
            case .Main(let model):
              return MainViewController(model: model, delegate: _self)
            }
            }()
          _self.setContentView(_self.displayingViewController!.view)
          _self.displayingViewController!.viewDidDisplay()
          
        case .Results(.OpenURL(let URL)):
          NSWorkspace.sharedWorkspace().openURL(URL)
          _self.panel.close()
          
        case .Results(.WriteObjectsToPasteboard(let objects)):
          let pasteboard = NSPasteboard.generalPasteboard()
          pasteboard.clearContents()
          pasteboard.writeObjects(objects)
          _self.panel.close()
        }
      }
    }
    
    if model.shouldOpenPanelOnLaunch {
      panel.makeKeyAndOrderFront(self)
    }
    
    MASShortcutBinder.sharedBinder().bindShortcutWithDefaultsKey(globalShortcutDefaultsKey) { [weak self] in
      if let _self = self {
        _self.panel.makeKeyAndOrderFront(_self)
      }
    }
  }
  
  // MARK: private
  
  private func setContentView(view: NSView) {
    panel.contentView = view
    updatePanelFrame()
  }
  
  private func updatePanelFrame() {
    if let statusItemWindow = statusItem.button?.window? {
      let statusItemFrame = statusItemWindow.frame
      let panelSize = panel.contentView.fittingSize
      let maxPanelOriginX: CGFloat? = {
        if let screen = statusItemWindow.screen {
          let frame = screen.visibleFrame
          return frame.origin.x + frame.size.width - panelSize.width
        } else {
          return nil
        }
      }()
      let panelOrigin = CGPoint(
        x: min(statusItemFrame.origin.x, maxPanelOriginX ?? CGFloat.max),
        y: statusItemFrame.origin.y + statusItemFrame.size.height)
      let panelFrame = NSMakeRect(
        panelOrigin.x,
        panelOrigin.y - panelSize.height,
        panelSize.width,
        panelSize.height)
      
      panel.setFrame(panelFrame, display: true)
    }
  }
  
  private let model = ApplicationModel(
    settingsStore: NSUserDefaults.standardUserDefaults(),
    globalShortcutDefaultsKey: globalShortcutDefaultsKey)
  private let notificationCenter = NSNotificationCenter.defaultCenter()
  private var statusItem: NSStatusItem!
  private var statusItemMoveObserver: AnyObject!
  private var displayingViewController: ViewController?
}

private let globalShortcutDefaultsKey = "globalShortcut"

