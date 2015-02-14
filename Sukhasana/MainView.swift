//
//  MainView.swift
//  Sukhasana
//
//  Created by Tom Brow on 2/12/15.
//  Copyright (c) 2015 Tom Brow. All rights reserved.
//

import Cocoa

class MainView: NSView, NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate {
  
  @IBOutlet var textField: NSTextField!
  @IBOutlet var resultsTableScrollView: TableScrollView!
  weak var delegate: MainViewDelegate?

  // MARK: NSTextFieldDelegate
  
  override func controlTextDidChange(obj: NSNotification) {
    resultsTableScrollView.reloadData()
    delegate?.mainViewDidChangeFittingSize(self)
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
  
}

protocol MainViewDelegate: NSObjectProtocol {
  func mainViewDidChangeFittingSize(mainView: MainView)
}