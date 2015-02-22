//
//  NSUserDefaults+SettingsStore.swift
//  Sukhasana
//
//  Created by Tom Brow on 2/21/15.
//  Copyright (c) 2015 Tom Brow. All rights reserved.
//

import Foundation

private let APIKeyKey = "APIKey", workspaceIDKey = "workspaceID"

extension NSUserDefaults: SettingsStore {
  
  func saveSettings(settings: Settings) -> () {
    setObject(settings.APIKey, forKey: APIKeyKey)
    setObject(settings.workspaceID, forKey: workspaceIDKey)
  }
  
  func restoreSettings() -> Settings? {
    if let APIKey = stringForKey(APIKeyKey) {
      if let workspaceID = stringForKey(workspaceIDKey) {
        return Settings(APIKey: APIKey, workspaceID: workspaceID)
      }
    }
    return nil
  }
}