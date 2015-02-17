//
//  MainViewController.swift
//  Sukhasana
//
//  Created by Tom Brow on 2/12/15.
//  Copyright (c) 2015 Tom Brow. All rights reserved.
//

import Cocoa
import ReactiveCocoa

class MainViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate {
  @IBOutlet var textField: NSTextField?
  @IBOutlet var resultsTableScrollView: TableScrollView?
  weak var delegate: MainViewControllerDelegate?
  
  init?(model: MainViewControllerModel) {
    self.model = model
    
    super.init(nibName: "MainViewController", bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("not supported")
  }

  // MARK: NSTextFieldDelegate
  
  override func controlTextDidChange(obj: NSNotification) {
    model.textFieldText.put(textField!.stringValue)
  }
  
  // MARK: NSTableViewDataSource
  
  func numberOfRowsInTableView(tableView: NSTableView) -> Int {
    return model.numberOfRows()
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
    
    view.stringValue = model.stringForRow(row)
    return view
  }
  
  // MARK: NSViewController
  
  override func loadView() {
    super.loadView()
    
    model.tableViewShouldReloadData.start { _ in
      // FIXME: retain cycle
      self.resultsTableScrollView?.reloadData()
      self.delegate?.mainViewControllerDidChangeFittingSize(self)
    }
  }
  
  // MARK: private
  
  private let model: MainViewControllerModel
}

protocol MainViewControllerDelegate: NSObjectProtocol {
  func mainViewControllerDidChangeFittingSize(mainViewController: MainViewController)
}