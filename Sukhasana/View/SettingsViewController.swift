//
//  SettingsViewController.swift
//  Sukhasana
//
//  Created by Tom Brow on 2/16/15.
//  Copyright (c) 2015 Tom Brow. All rights reserved.
//

import Cocoa
import ReactiveCocoa

class SettingsViewController: NSViewController, ViewController, NSTextFieldDelegate {
  @IBOutlet var APIKeyTextField: NSTextField!
  @IBOutlet var workspacePopUpButton: NSPopUpButton!
  @IBOutlet var saveButton: NSButton!
  @IBOutlet var progressIndicator: NSProgressIndicator!
  
  init?(model: SettingsScreenModel) {
    self.model = model
    
    super.init(nibName: "SettingsViewController", bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("not supported")
  }
  
  @IBAction func didClickSaveButton(sender: AnyObject?) {
    sendNext(model.didClickSaveButton, ())
  }
  
  @IBAction func workspacePopUpButtonDidSelectItem(sender: AnyObject?) {
    sendNext(model.workspacePopUpDidSelectItemAtIndex, workspacePopUpButton.indexOfSelectedItem)
  }
  
  // MARK: ViewController
  
  func viewDidDisplay() {
    view.window?.makeFirstResponder(APIKeyTextField)
  }
  
  // MARK: NSTextFieldDelegate
  
  override func controlTextDidChange(obj: NSNotification) {
    model.APIKeyTextFieldText.put(APIKeyTextField.stringValue)
  }
  
  // MARK: NSViewController
  
  override func loadView() {
    super.loadView()
    
    model.saveButtonEnabled.producer.start { [weak self] enabled in
      self?.saveButton?.enabled = enabled
      return
    }
    model.progressIndicatorAnimating.producer.start { [weak self] animating in
      if animating {
        self?.progressIndicator.startAnimation(nil)
      } else {
        self?.progressIndicator.stopAnimation(nil)
      }
    }
    model.workspacePopUpButtonEnabled.producer.start { [weak self] enabled in
      self?.workspacePopUpButton?.enabled = enabled
      return
    }
    model.workspacePopUpItemsTitles.producer.start { [weak self] titles in
      self?.workspacePopUpButton.removeAllItems()
      self?.workspacePopUpButton.addItemsWithTitles(titles)
    }
    
    APIKeyTextField.stringValue = model.APIKeyTextFieldText.value
    workspacePopUpButton.selectItemAtIndex(model.workspacePopupSelectedIndex.value)
  }
  
  // MARK: private
  
  private let model: SettingsScreenModel
}
