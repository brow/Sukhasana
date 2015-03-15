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
  
  func copy(sender: AnyObject?) {
    if selectedRow >= 0 {
      let row = selectedRow
      flashHighlightedRowsThen {
        self.secondDelegate?.tableView(self, wantsToCopyRowAtIndex: row)
        return
      }
    }
  }
  
  func clickRow(row: Int) {
    flashHighlightedRowsThen {
      self.secondDelegate?.tableView(self, didClickRowAtIndex: row)
      return
    }
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
    if row >= 0 {
      clickRow(row)
    }
  }
  
  override func keyDown(theEvent: NSEvent) {
    switch Int(theEvent.keyCode) {
    case kVK_UpArrow where selectedRow == 0:
      window?.selectKeyViewPrecedingView(self)
    case kVK_Space, kVK_Return where selectedRow >= 0:
      clickRow(selectedRow)
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
  func tableView(tableView: TableView, wantsToCopyRowAtIndex index: Int)
}

extension NSTableView {
  func flashHighlightedRowsThen(callback: () -> ()) {
    // Simulate NSMenu's flash on selecting a row, not without jank
    let baseHighlightStyle = selectionHighlightStyle
    let mainQueue = dispatch_get_main_queue()
    let toggleInterval = Int64(NSEC_PER_SEC) / 20
    let numberOfToggles: Int64 = 3
    
    for i: Int64 in 0...numberOfToggles {
      let time = dispatch_time(DISPATCH_TIME_NOW, toggleInterval * i)
      dispatch_after(time, mainQueue) {
        if i < numberOfToggles {
          self.selectionHighlightStyle = i % 2 == 0
            ? NSTableViewSelectionHighlightStyle.None
            : baseHighlightStyle
        } else {
          self.selectionHighlightStyle = baseHighlightStyle
          callback()
        }
      }
    }
  }
}