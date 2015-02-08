//
//  InputView.swift
//  Sukhasana
//
//  Created by Tom Brow on 2/5/15.
//  Copyright (c) 2015 Tom Brow. All rights reserved.
//

import Cocoa
import Cartography

class InputView: NSView {
  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    
//    textField.drawsBackground = false
    textField.drawsBackground = false
    textField.bezeled = false
    textField.wantsLayer = true
    self.addSubview(textField)
    
    self.needsUpdateConstraints = true
    self.updateConstraintsForSubtreeIfNeeded()
  }
  
  required init(coder aDecoder: NSCoder) {
    fatalError("nope")
  }
  
  // MARK: private
  
  let textField = NSTextField()
  
  // MARK: NSView
  
  override func updateConstraints() {
    constrain(textField, self) { textField, view in
      view.height == 50
      view.width == 300
      textField.edges == view.edges
      return
    }
    
    super.updateConstraints()
  }
}
