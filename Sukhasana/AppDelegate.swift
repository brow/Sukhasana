//
//  AppDelegate.swift
//  Sukhasana
//
//  Created by Tom Brow on 2/4/15.
//  Copyright (c) 2015 Tom Brow. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, MainViewControllerDelegate,  NSApplicationDelegate, NSWindowDelegate {
  @IBOutlet var panel: NSPanel!
  
  override init() {
    settingsViewController = SettingsViewController(model: SettingsViewControllerModel())!
  }
  
  @IBAction func didClickStatusItem(sender: AnyObject) {
    let statusItemFrame = sender.window.frame
    panel.setFrameTopLeftPoint(NSMakePoint(
      statusItemFrame.origin.x,
      statusItemFrame.origin.y + statusItemFrame.size.height))
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
  
  // MARK: NSApplicationDelegate
  
  func applicationDidFinishLaunching(notification: NSNotification) {
    let client = APIClient(APIKey: "4cAUaVhk.Vt70w5u6rOHQgsy3fsLoX9v")
    
    let mainViewControllerModel = MainViewControllerModel(client: client)
    let mainViewController = MainViewController(model: mainViewControllerModel)!
    mainViewController.delegate = self
    
    statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-2 /* NSSquareStatusItemLength */)
    statusItem.title = "a⋮"
    statusItem.highlightMode = true
    statusItem.target = self
    statusItem.action = "didClickStatusItem:"
    
    panel.floatingPanel = true

    setContentView(settingsViewController.view)
  }
  
  // MARK: private
  
  private func setContentView(view: NSView) {
    panel.contentView = view
    updatePanelFrame()
  }
  
  private func updatePanelFrame() {
    let topLeft = CGPointMake(
      panel.frame.origin.x,
      panel.frame.origin.y + panel.frame.size.height)
    let newSize = panel.contentView.fittingSize
    let newFrame = NSMakeRect(
      topLeft.x,
      topLeft.y - newSize.height,
      newSize.width,
      newSize.height)
    panel.setFrame(newFrame, display: true)
  }
  
  // MARK: private
  
  private var statusItem: NSStatusItem!
  private var settingsViewController: SettingsViewController
}

