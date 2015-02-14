//
//  MainView.swift
//  Sukhasana
//
//  Created by Tom Brow on 2/12/15.
//  Copyright (c) 2015 Tom Brow. All rights reserved.
//

import Cocoa

class MainView: NSView, NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate {
  
  @IBOutlet var resultsTableView: NSTableView!
  @IBOutlet var resultsScrollView: NSScrollView!
  @IBOutlet var textField: NSTextField!
  
  override func awakeFromNib() {
    self.updateWindowFrame()
  }
  
  // MARK: NSTextFieldDelegate
  
  override func controlTextDidChange(obj: NSNotification) {
    resultsTableView.reloadData()
    resultsScrollView.invalidateIntrinsicContentSize()
    self.updateWindowFrame()
  }
  
  // MARK: NSTableViewDataSource
  
  func numberOfRowsInTableView(tableView: NSTableView) -> Int {
    return countElements(textField.stringValue)
  }
  
  // MARK: NSTableViewDelegate
  
  func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
    let identifier = "View"
    let view: NSTextField = {
      if let view = tableView.makeViewWithIdentifier(identifier, owner: self) as? NSTextField {
        return view
      } else {
        let view = NSTextField()
        view.editable = false
        view.identifier = identifier
        return view
      }
      }()
    
    view.stringValue = "Hi there \(row)"
    return view
  }
  
  // MARK: private
  
  private func updateWindowFrame() {
    if let window = self.window {
      let topLeft = CGPointMake(
        window.frame.origin.x,
        window.frame.origin.y + window.frame.size.height)
      let newSize = self.fittingSize
      let newFrame = NSMakeRect(
        topLeft.x,
        topLeft.y - newSize.height,
        newSize.width,
        newSize.height)
      window.setFrame(newFrame, display: true)
    }
  }
}