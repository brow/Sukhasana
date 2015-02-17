//
//  SettingsViewController.swift
//  Sukhasana
//
//  Created by Tom Brow on 2/16/15.
//  Copyright (c) 2015 Tom Brow. All rights reserved.
//

import Cocoa

class SettingsViewController: NSViewController, NSTextFieldDelegate {
  @IBOutlet var APIKeyTextField: NSTextField?
  @IBOutlet var workspacePopUpButton: NSPopUpButton?
  @IBOutlet var saveButton: NSButton?
  
  init?(model: SettingsViewControllerModel) {
    self.model = model
    
    super.init(nibName: "SettingsViewController", bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("not supported")
  }
  
  // MARK: NSTextFieldDelegate
  
  override func controlTextDidChange(obj: NSNotification) {
    println(APIKeyTextField?.stringValue)
  }
  
  // MARK: private
  
  private let model: SettingsViewControllerModel
}
