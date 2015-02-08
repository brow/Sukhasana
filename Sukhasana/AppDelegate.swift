//
//  AppDelegate.swift
//  Sukhasana
//
//  Created by Tom Brow on 2/4/15.
//  Copyright (c) 2015 Tom Brow. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  override init() {
    statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-2 /* NSSquareStatusItemLength */)
    panel = NSPanel(
      contentRect: NSMakeRect(0, 0, 300, 50),
      styleMask: NSBorderlessWindowMask | NSUtilityWindowMask | NSNonactivatingPanelMask,
      backing: .Buffered,
      defer: true)

    super.init()
    
    statusItem.title = "a⋮"
    statusItem.highlightMode = true
    statusItem.target = self
    statusItem.action = "didClickStatusItem:"
  }
  
  @IBAction func didClickStatusItem(sender: AnyObject) {
    let statusItemFrame = sender.window.frame
    
    panel.setFrameTopLeftPoint(NSMakePoint(
      statusItemFrame.origin.x,
      statusItemFrame.origin.y + statusItemFrame.size.height))
    panel.makeKeyAndOrderFront(self)
  }
  
  func applicationDidFinishLaunching(aNotification: NSNotification) {
    // Insert code here to initialize your application
  }

  func applicationWillTerminate(aNotification: NSNotification) {
    // Insert code here to tear down your application
  }

  // MARK: priavte
  
  let statusItem: NSStatusItem
  let panel: NSPanel
}

