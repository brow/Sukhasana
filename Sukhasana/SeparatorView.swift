//
//  SeparatorView.swift
//  Sukhasana
//
//  Created by Tom Brow on 2/22/15.
//  Copyright (c) 2015 Tom Brow. All rights reserved.
//

import Cocoa

class SeparatorView: NSView {
  override func drawRect(dirtyRect: NSRect) {
    super.drawRect(dirtyRect)
    NSColor(calibratedWhite: 0.8, alpha: 1).setFill()
    NSRectFill(dirtyRect)
  }
}
