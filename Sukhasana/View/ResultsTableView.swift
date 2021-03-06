//
//  TableView.swift
//  Sukhasana
//
//  Created by Tom Brow on 2/22/15.
//  Copyright (c) 2015 Tom Brow. All rights reserved.
//

import Cocoa
import Carbon
import ReactiveCocoa

class ResultsTableView: NSTableView, NSTableViewDataSource, NSTableViewDelegate {
  let model: MutableProperty<ResultsTableViewModel>
  let fittingHeight: SignalProducer<CGFloat, NoError>
  
  required init?(coder: NSCoder) {
    model = MutableProperty(ResultsTableViewModel.makeWithResults(Results.empty).0)
    
    fittingHeight = model.producer
      |> map { model in
        let numberOfRows = model.numberOfRows()
        let bottomPadding = CGFloat(numberOfRows > 0 ? 4 : 0)
        return bottomPadding +
          map(0..<numberOfRows) { row in
            heightForCell(model.cellForRow(row))
          }.reduce(0, +)
      }
    
    super.init(coder: coder)
    
    self.setDataSource(self)
    self.setDelegate(self)
    self.allowsTypeSelect = false
    
    addTrackingArea(
      NSTrackingArea(
        rect: NSZeroRect, // ignored due to .InVisibleRect option
        options: .ActiveAlways | .InVisibleRect | .MouseEnteredAndExited | .MouseMoved,
        owner: self,
        userInfo: nil))
    
    model.producer.start { [weak self] _ in
      self?.reloadData()
      return
    }
  }
  
  func copy(sender: AnyObject?) {
    if selectedRow >= 0 {
      // For some reason, the flashHighlightedRowsThen animation's timing is off
      // if initiated in the same event loop iteration `self.copy` is called.
      dispatch_async(dispatch_get_main_queue()) {
        self.didRecognizeAction(.Copy, onRowAtIndex: self.selectedRow)
      }
    }
  }
  
  func didRecognizeAction(action: ResultsTableViewModel.Action, onRowAtIndex index: Int) {
    flashHighlightedRowsThen {
      sendNext(self.model.value.didRecognizeActionOnRowAtIndex, (action, index))
    }
  }
  
  // MARK: NSTableViewDataSource
  
  func numberOfRowsInTableView(tableView: NSTableView) -> Int {
    return model.value.numberOfRows()
  }
  
  // MARK: NSTableViewDelegate
  
  func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
    switch model.value.cellForRow(row) {
    case .Selectable(let text):
      let view = tableView.makeViewWithIdentifier("SelectableCell", owner: self) as NSTableCellView
      view.textField?.stringValue = text
      return view
    case .Separator:
      return tableView.makeViewWithIdentifier("SeparatorView", owner: self) as? NSView
    }
  }
  
  func tableView(tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
    switch model.value.cellForRow(row) {
    case .Selectable:
      return true
    case .Separator:
      return false
    }
  }
  
  func tableView(tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
    return heightForCell(model.value.cellForRow(row))
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
      didRecognizeAction(.Click, onRowAtIndex: row)
    }
  }
  
  override func keyDown(theEvent: NSEvent) {
    switch Int(theEvent.keyCode) {
    case kVK_UpArrow where selectedRow == 0:
      window?.selectKeyViewPrecedingView(self)
    case kVK_Space, kVK_Return where selectedRow >= 0:
      didRecognizeAction(.Click, onRowAtIndex: selectedRow)
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

private func heightForCell(cell: ResultsTableViewModel.Cell) -> CGFloat {
  switch cell {
  case .Selectable:
    return 22
  case .Separator:
    return 1
  }
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