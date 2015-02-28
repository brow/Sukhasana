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
  let shouldOpenURL: SignalProducer<NSURL, NoError>
  
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
    let mainModelAndProducers = didRestoreSettings
      |> concat(didSaveSettings)
      |> map(MainScreenModel.makeWithSettings)
      |> replay(capacity: 1)
    let shouldDisplayMainScreen = mainModelAndProducers
      |> map { Screen.Main($0.0) }
    
    // Show the settings screen after the Settings button is clicked, and on
    // launch if no settings have been restored
    let shouldDisplaySettingsScreen = SignalProducer(values: restoredSettings == nil ? [()] : [])
      |> concat (mainModelAndProducers |> joinMap(.Latest) { $0.didClickSettingsButton })
      |> map { _ in Screen.Settings(settingsModel) }
  
    shouldDisplayScreen = SignalProducer(values: [shouldDisplayMainScreen, shouldDisplaySettingsScreen])
      |> join(.Merge)
    
    shouldOpenURL = mainModelAndProducers |> joinMap(.Latest) { $0.URLsToOpen}
  }
}

protocol SettingsStore {
  func saveSettings(settings: Settings) -> ()
  func restoreSettings() -> Settings?
}
