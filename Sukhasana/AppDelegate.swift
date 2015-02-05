//
//  AppDelegate.swift
//  Sukhasana
//
//  Created by Tom Brow on 2/4/15.
//  Copyright (c) 2015 Tom Brow. All rights reserved.
//

import Cocoa
import AppKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  @IBOutlet weak var window: NSWindow!

  override init() {
    statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-1 /* NSVariableStatusItemLength */)
    statusItem.title = "Asana"
    statusItem.highlightMode = true
  }
  
  func applicationDidFinishLaunching(aNotification: NSNotification) {
    // Insert code here to initialize your application
  }

  func applicationWillTerminate(aNotification: NSNotification) {
    // Insert code here to tear down your application
  }

  // MARK: priavte
  
  let statusItem: NSStatusItem
}

