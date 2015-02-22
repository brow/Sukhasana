//
//  ApplicationModel.swift
//  Sukhasana
//
//  Created by Tom Brow on 2/16/15.
//  Copyright (c) 2015 Tom Brow. All rights reserved.
//

import ReactiveCocoa

struct ApplicationModel {
  enum Screen {
    case Settings(SettingsScreenModel)
    case Main(MainScreenModel)
  }
  
  let shouldDisplayScreen: SignalProducer<Screen, NoError>
  
  init(settingsStore: SettingsStore) {
    let restoredSettings = settingsStore.restoreSettings()
    let (settingsModel, didSaveSettings) = SettingsScreenModel.makeWithSettings(restoredSettings)
    
    // Persist saved settings
    didSaveSettings.start { settings in
      settingsStore.saveSettings(settings)
    }
    
    // Show the main screen on launch if settings are restored
    let didRestoreSettings: SignalProducer<Settings, NoError> = {
      if let restoredSettings = restoredSettings {
        return SignalProducer(value: restoredSettings)
      } else {
        return SignalProducer.empty
      }
    }()
    
    // Show the main screen after settings are saved
    let mainModelAndDidClickSettingsButton = didRestoreSettings
      |> concat(didSaveSettings)
      |> map(MainScreenModel.makeWithSettings)
      |> replay(capacity: 1)
    let shouldDisplayMainScreen = mainModelAndDidClickSettingsButton
      |> map { (mainModel, _) in Screen.Main(mainModel) }
    
    // Show the settings screen after the Settings button is clicked, and on
    // launch if no settings have been restored
    let shouldDisplaySettingsScreen = SignalProducer(values: restoredSettings == nil ? [()] : [])
      |> concat (mainModelAndDidClickSettingsButton |> latestMap { $0.1 })
      |> map { _ in Screen.Settings(settingsModel) }
  
    shouldDisplayScreen = SignalProducer(values: [shouldDisplayMainScreen, shouldDisplaySettingsScreen])
      |> merge
  }
}

protocol SettingsStore {
  func saveSettings(settings: Settings) -> ()
  func restoreSettings() -> Settings?
}
