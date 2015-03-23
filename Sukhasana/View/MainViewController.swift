//
//  MainViewController.swift
//  Sukhasana
//
//  Created by Tom Brow on 2/12/15.
//  Copyright (c) 2015 Tom Brow. All rights reserved.
//

import Cocoa
import ReactiveCocoa

class MainViewController: NSViewController, ViewController, NSTextFieldDelegate {
  @IBOutlet var textField: NSTextField!
  @IBOutlet var resultsTableView: TableView!
  @IBOutlet var resultsTableViewHeightConstraint: NSLayoutConstraint!
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
  
  func control(control: NSControl, textView: NSTextView, doCommandBySelector commandSelector: Selector) -> Bool {
    switch commandSelector {
    case "moveDown:":
      // Down arrow key moves from search field to results table
      control.window?.selectKeyViewFollowingView(control)
      return true
    default:
      return false
    }
  }
  
  // MARK: NSViewController
  
  override func loadView() {
    super.loadView()
    
    resultsTableView.model <~ model.resultsTableViewModel
    
    resultsTableView.fittingHeightDidChange.start { [weak self] _ in
      if let _self = self {
        _self.resultsTableViewHeightConstraint.constant = _self.resultsTableView.fittingHeight
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