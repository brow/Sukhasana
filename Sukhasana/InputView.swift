//
//  InputView.swift
//  Sukhasana
//
//  Created by Tom Brow on 2/5/15.
//  Copyright (c) 2015 Tom Brow. All rights reserved.
//

import Cocoa
import Cartography

class InputView: NSView, NSTextFieldDelegate, NSTableViewDataSource, NSTableViewDelegate {
  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    
    textField.font = NSFont.systemFontOfSize(20)
    textField.focusRingType = NSFocusRingType.None
//    textField.drawsBackground = false
    textField.backgroundColor = NSColor.redColor()
    textField.bezeled = false
    textField.wantsLayer = true
    textField.delegate = self
    self.addSubview(textField)
    
    searchResultsTableView.rowHeight = 40
    searchResultsTableView.addTableColumn(
      NSTableColumn(identifier: "1"))
    searchResultsTableView.setDataSource(self)
    searchResultsTableView.setDelegate(self)
    self.addSubview(searchResultsTableView)
  }
  
  required init(coder aDecoder: NSCoder) {
    fatalError("nope")
  }
  
  func reloadTableData() {
    searchResultsTableView.reloadData()
  }
  
  // MARK: private
  
  private let model = InputViewModel()
  private let textField = NSTextField()
  private let searchResultsTableView = TableView()
  
  // MARK: NSTableViewDataSource
  
  func numberOfRowsInTableView(tableView: NSTableView) -> Int {
    return 5
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

  // MARK: NSTextFieldDelegate
  
  override func controlTextDidChange(obj: NSNotification) {
    model.textFieldText.put(textField.stringValue)
    searchResultsTableView.reloadData()
  }
  
  // MARK: NSView
  
  override func updateConstraints() {
    let textFieldInset: Float = 10

    constrain(self, textField, searchResultsTableView) { view, textField, searchResultsTableView in
      textField.bottom == view.bottom// - textFieldInset
      textField.leading == view.leading// + textFieldInset
      textField.trailing == view.trailing// - textFieldInset
      
      searchResultsTableView.leading == view.leading
      searchResultsTableView.trailing == view.trailing
      searchResultsTableView.top == view.top
      searchResultsTableView.bottom == textField.top
    }
    
    super.updateConstraints()
  }
  
  override func layout() {
    super.layout()
  }

}
