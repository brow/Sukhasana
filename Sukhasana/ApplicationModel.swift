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
    let (settingsModel, didSaveSettings) = SettingsScreenModel.makeWithSettings(settingsStore.restoreSettings())
    
    // Persist saved settings
    didSaveSettings.start { settings in
      settingsStore.saveSettings(settings)
    }
    
    // Show the main screen after settings are saved
    let mainModelAndDidClickSettingsButton = didSaveSettings
      |> map(MainScreenModel.makeWithSettings)
      |> replay(capacity: 1)
    let shouldDisplayMainScreen = mainModelAndDidClickSettingsButton
      |> map { (mainModel, _) in Screen.Main(mainModel) }
    
    // Show the settings screen immediately and whenever the Settings button is clicked
    let shouldDisplaySettingsScreen = mainModelAndDidClickSettingsButton
      |> latestMap { (_, didClickSettingsButton) in didClickSettingsButton }
      |> startWith(())
      |> map { _ in Screen.Settings(settingsModel) }
  
    shouldDisplayScreen = SignalProducer(values: [shouldDisplayMainScreen, shouldDisplaySettingsScreen])
      |> merge
  }
}

protocol SettingsStore {
  func saveSettings(settings: Settings) -> ()
  func restoreSettings() -> Settings?
}
