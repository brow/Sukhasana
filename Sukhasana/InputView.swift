//
//  InputView.swift
//  Sukhasana
//
//  Created by Tom Brow on 2/5/15.
//  Copyright (c) 2015 Tom Brow. All rights reserved.
//

import Cocoa
import Cartography

class InputView: NSView, NSTextFieldDelegate {
  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    
    textField.font = NSFont.systemFontOfSize(20)
    textField.focusRingType = NSFocusRingType.None
    textField.drawsBackground = false
    textField.bezeled = false
    textField.wantsLayer = true
    textField.delegate = self
    self.addSubview(textField)
    
    self.needsUpdateConstraints = true
    self.updateConstraintsForSubtreeIfNeeded()
  }
  
  required init(coder aDecoder: NSCoder) {
    fatalError("nope")
  }
  
  // MARK: private
  
  let model = InputViewModel()
  let textField = NSTextField()

  // MARK: NSTextFieldDelegate
  
  override func controlTextDidChange(obj: NSNotification) {
    model.textFieldText.put(textField.stringValue)
  }
  
  // MARK: NSView
  
  override func updateConstraints() {
    constrain(self, textField) { view, textField in
      textField.edges == inset(view.edges, 10)
      return
    }
    
    super.updateConstraints()
  }

}
