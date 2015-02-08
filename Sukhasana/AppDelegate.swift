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
    panel = Panel(
      contentRect: NSMakeRect(0, 0, 300, 50),
      styleMask: NSBorderlessWindowMask | NSNonactivatingPanelMask,
      backing: .Buffered,
      defer: true)

    super.init()
    
    statusItem.title = "a⋮"
    statusItem.highlightMode = true
    statusItem.target = self
    statusItem.action = "didClickStatusItem:"
    
    panel.floatingPanel = true
    panel.collectionBehavior = .CanJoinAllSpaces
    panel.contentView = InputView(frame: NSZeroRect)
  }
  
  @IBAction func didClickStatusItem(sender: AnyObject) {
    let statusItemFrame = sender.window.frame
    
    panel.setFrameTopLeftPoint(NSMakePoint(
      statusItemFrame.origin.x,
      statusItemFrame.origin.y + statusItemFrame.size.height))
    panel.makeKeyAndOrderFront(self)
  }

  // MARK: private
  
  let statusItem: NSStatusItem
  let panel: NSPanel
}

