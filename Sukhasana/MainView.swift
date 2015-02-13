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
  
  // MARK: NSTextFieldDelegate
  
  override func controlTextDidChange(obj: NSNotification) {
    resultsTableView.reloadData()
    resultsScrollView.invalidateIntrinsicContentSize()
    self.window?.setContentSize(self.fittingSize)
  }
  
  // MARK: NSTableViewDataSource
  
  func numberOfRowsInTableView(tableView: NSTableView) -> Int {
    return 10 - countElements(textField.stringValue)
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
    
    view.stringValue = "Hi there"
    return view
  }
  
}