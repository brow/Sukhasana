//
//  MainViewController.swift
//  Sukhasana
//
//  Created by Tom Brow on 2/12/15.
//  Copyright (c) 2015 Tom Brow. All rights reserved.
//

import Cocoa
import ReactiveCocoa

class MainViewController: NSViewController, ViewController, NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate, TableViewDelegate {
  @IBOutlet var textField: NSTextField!
  @IBOutlet var resultsTableScrollView: TableScrollView!
  @IBOutlet var progressIndicator: NSProgressIndicator!
  
  init?(model: MainScreenModel, delegate: MainViewControllerDelegate) {
    self.model = model
    self.delegate = delegate
    
    super.init(nibName: "MainViewController", bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("not supported")
  }
  
  @IBAction func didClickSettingsButton(sender: AnyObject?) {
    sendNext(model.didClickSettingsButton, ())
  }
  
  // MARK: ViewController
  
  func viewDidDisplay() {
    view.window?.makeFirstResponder(textField)
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
    let view = tableView.makeViewWithIdentifier("CellIdentifier", owner: self) as NSTableCellView
    view.textField?.stringValue = model.stringForRow(row)
    return view
  }
  
  // MARK: TableViewDelegate
  func tableView(tableView: TableView, didClickRowAtIndex index: Int) {
    sendNext(model.didClickRowAtIndex, index)
  }
  
  // MARK: NSViewController
  
  override func loadView() {
    super.loadView()
    
    model.tableViewShouldReloadData.start { [weak self] _ in
      self?.resultsTableScrollView.reloadData()
      if let _self = self {
        _self.delegate?.mainViewControllerDidChangeFittingSize(_self)
      }
    }
    
    model.activityIndicatorIsAnimating.producer.start { [weak self] animating in
      if animating {
        self?.progressIndicator.startAnimation(self)
      } else {
        self?.progressIndicator.stopAnimation(self)
      }
    }
  }
  
  // MARK: private
  
  private let model: MainScreenModel
  private weak var delegate: MainViewControllerDelegate?
}

protocol MainViewControllerDelegate: NSObjectProtocol {
  func mainViewControllerDidChangeFittingSize(mainViewController: MainViewController)
}