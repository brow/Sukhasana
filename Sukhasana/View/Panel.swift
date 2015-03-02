//
//  Panel.swift
//  Sukhasana
//
//  Created by Tom Brow on 2/7/15.
//  Copyright (c) 2015 Tom Brow. All rights reserved.
//

import Cocoa

class Panel: NSPanel {
  // MARK: NSWindow
  
  override var canBecomeKeyWindow: Bool {
    return true
  }
  
  override func recalculateKeyViewLoop() {
    // If this is not overridden, then the nextKeyView outlets set in the nibs
    // are ignored the first time that a given view is displayed in the panel.
    // This is not helped by unsetting NSPanel.autorecalculatesKeyViewLoop.
  }
  
  // MARK: NSResponder
  
  func cancel(sender: AnyObject?) {
    // Called during Escape or Command-. shortcuts.
    close()
  }
}