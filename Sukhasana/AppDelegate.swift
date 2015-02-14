//
//  AppDelegate.swift
//  Sukhasana
//
//  Created by Tom Brow on 2/4/15.
//  Copyright (c) 2015 Tom Brow. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, MainViewDelegate,  NSApplicationDelegate, NSWindowDelegate {
  
  @IBOutlet var panel: NSPanel!
  @IBOutlet var mainView: MainView!
  
  @IBAction func didClickStatusItem(sender: AnyObject) {
    let statusItemFrame = sender.window.frame
    panel.setFrameTopLeftPoint(NSMakePoint(
      statusItemFrame.origin.x,
      statusItemFrame.origin.y + statusItemFrame.size.height))
    panel.makeKeyAndOrderFront(self)    
  }
  
  // MARK: MainViewDelegate
  
  func mainViewDidChangeFittingSize(mainView: MainView) {
    self.updatePanelFrame()
  }
  
  // MARK: NSWindowDelegate
  
  func windowDidResignKey(notification: NSNotification) {
    panel.close()
  }
  
  // MARK: NSApplicationDelegate
  
  func applicationDidFinishLaunching(notification: NSNotification) {
    panel.floatingPanel = true
    
    mainView.delegate = self

    statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-2 /* NSSquareStatusItemLength */)
    statusItem.title = "a⋮"
    statusItem.highlightMode = true
    statusItem.target = self
    statusItem.action = "didClickStatusItem:"
    
    self.updatePanelFrame()
  }
  
  // MARK: private
  
  private func updatePanelFrame() {
    let topLeft = CGPointMake(
      panel.frame.origin.x,
      panel.frame.origin.y + panel.frame.size.height)
    let newSize = mainView.fittingSize
    let newFrame = NSMakeRect(
      topLeft.x,
      topLeft.y - newSize.height,
      newSize.width,
      newSize.height)
    panel.setFrame(newFrame, display: true)
  }
  
  // MARK: private
  
  private var statusItem: NSStatusItem!
}

