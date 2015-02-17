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
  @IBOutlet var progressIndicator: NSProgressIndicator?
  
  init?(model: SettingsViewControllerModel) {
    self.model = model
    
    super.init(nibName: "SettingsViewController", bundle: nil)
    
    // FIXME: retain cycles
    model.saveButtonEnabled.producer.start { self.saveButton?.enabled = $0; return}
    model.progressIndicatorAnimating.producer.start { animating in
      if animating {
        self.progressIndicator?.startAnimation(nil)
      } else {
        self.progressIndicator?.stopAnimation(nil)
      }
    }
    model.workspacePopUpButtonEnabled.producer.start { self.workspacePopUpButton?.enabled = $0; return }
    model.workspacePopUpItemsTitles.producer.start { titles in
      self.workspacePopUpButton?.removeAllItems()
      self.workspacePopUpButton?.addItemsWithTitles(titles)
    }
  }
  
  required init?(coder: NSCoder) {
    fatalError("not supported")
  }
  
  // MARK: NSTextFieldDelegate
  
  override func controlTextDidChange(obj: NSNotification) {
    model.APIKeyTextFieldText.put(APIKeyTextField!.stringValue)
  }
  
  // MARK: private
  
  private let model: SettingsViewControllerModel
}
