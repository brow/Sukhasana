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
    panel.makeKeyAndOrderFront(self)
  }
  
  // MARK: MainViewControllerDelegate
  
  func mainViewControllerDidChangeFittingSize(mainViewController: MainViewController) {
    updatePanelFrame()
  }
  
  // MARK: NSWindowDelegate
  
  func windowDidResignKey(notification: NSNotification) {
    panel.close()
  }
  
  func windowDidBecomeKey(notification: NSNotification) {
    displayingViewController?.viewDidDisplay()
  }
  
  // MARK: NSApplicationDelegate
  
  func applicationDidFinishLaunching(notification: NSNotification) {
    statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-2 /* NSSquareStatusItemLength */)
    statusItem.title = "☀"
    statusItem.highlightMode = true
    statusItem.target = self
    statusItem.action = "didClickStatusItem:"
    
    panel.floatingPanel = true
    
    // The status item can move when other items are removed or hidden.
    statusItemMoveObserver = notificationCenter.addObserverForName(
      NSWindowDidMoveNotification,
      object: statusItem.button!.window!,
      queue: nil,
      usingBlock: { [weak self] _ in self?.updatePanelFrame(); return })
    
    model.shouldDisplayScreen.start { [weak self] screen in
      if let _self = self {
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
      }
    }
    
    model.shouldOpenURL.start { [weak self] URL in
      NSWorkspace.sharedWorkspace().openURL(URL)
      self?.panel.close()
      return
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
    if let statusItemFrame = statusItem.button?.window?.frame {
      let topLeft = CGPointMake(
        statusItemFrame.origin.x,
        statusItemFrame.origin.y + statusItemFrame.size.height)
      let size = panel.contentView.fittingSize
      let newFrame = NSMakeRect(
        topLeft.x,
        topLeft.y - size.height,
        size.width,
        size.height)
      panel.setFrame(newFrame, display: true)
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

