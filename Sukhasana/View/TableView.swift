//
//  TableView.swift
//  Sukhasana
//
//  Created by Tom Brow on 2/22/15.
//  Copyright (c) 2015 Tom Brow. All rights reserved.
//

import Cocoa
import Carbon

class TableView: NSTableView {
  @IBOutlet weak var secondDelegate: TableViewDelegate?
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    
    self.allowsTypeSelect = false
    
    addTrackingArea(
      NSTrackingArea(
        rect: NSZeroRect, // ignored due to .InVisibleRect option
        options: .ActiveAlways | .InVisibleRect | .MouseEnteredAndExited | .MouseMoved,
        owner: self,
        userInfo: nil))
  }
  
  // MARK: NSResponder
  
  func acceptsFirstResponder() -> Bool {
    return numberOfRows > 0
  }
  
  override func becomeFirstResponder() -> Bool {
    selectRowIndexes(NSIndexSet(index: 0), byExtendingSelection: false)
    return true
  }
  
  override func mouseExited(theEvent: NSEvent) {
    super.mouseExited(theEvent)
    selectRowIndexes(NSIndexSet(), byExtendingSelection: false)
  }
  
  override func mouseMoved(theEvent: NSEvent) {
    super.mouseMoved(theEvent)
    
    let row = rowAtPoint(convertPoint(theEvent.locationInWindow, fromView: nil))
    let rowIndexesToSelect = row == -1
      ? NSIndexSet()
      : NSIndexSet(index: row)
    
    window?.makeFirstResponder(self)
    selectRowIndexes(rowIndexesToSelect, byExtendingSelection: false)
  }
  
  override func mouseDown(theEvent: NSEvent) {
    super.mouseDown(theEvent)
    
    let row = rowAtPoint(convertPoint(theEvent.locationInWindow, fromView: nil))
    if row != -1 {
      secondDelegate?.tableView(self, didClickRowAtIndex: row)
    }
  }
  
  override func keyDown(theEvent: NSEvent) {
    switch Int(theEvent.keyCode) {
    case kVK_UpArrow where selectedRow == 0:
      window?.selectKeyViewPrecedingView(self)
    case kVK_Space, kVK_Return where selectedRow >= 0:
      secondDelegate?.tableView(self, didClickRowAtIndex: selectedRow)
    default:
      super.keyDown(theEvent)
    }
  }
  
  override func resignFirstResponder() -> Bool {
    if super.resignFirstResponder() {
      deselectAll(self)
      return true
    } else {
      return false
    }
  }
}

@objc protocol TableViewDelegate {
  func tableView(tableView: TableView, didClickRowAtIndex index: Int)
}