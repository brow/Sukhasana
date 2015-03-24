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
  
  enum Effect {
    case DisplayScreen(Screen)
    case MainScreen(MainScreenModel.Effect)
  }
  
  let effects: SignalProducer<Effect, NoError>
  let shouldOpenPanelOnLaunch: Bool
  
  init(settingsStore: SettingsStore, globalShortcutDefaultsKey: String) {
    let restoredSettings = settingsStore.restoreSettings()
    let (settingsModel, didSaveSettings) = SettingsScreenModel.makeWithSettings(
      restoredSettings,
      globalShortcutDefaultsKey: globalShortcutDefaultsKey)
    
    // Persist saved settings
    didSaveSettings.start { settings in
      settingsStore.saveSettings(settings)
    }
    
    // Show the main screen right away if settings already exist
    let didRestoreSettings: SignalProducer<Settings, NoError> = {
      if let restoredSettings = restoredSettings {
        return SignalProducer(value: restoredSettings)
      } else {
        return SignalProducer.empty
      }
      }()
    
    // Show the main screen after new settings are saved
    let mainModelsAndEffects = didRestoreSettings
      |> concat(didSaveSettings)
      |> map(MainScreenModel.makeWithSettings)
      |> replay(capacity: 1)
    let shouldDisplayMainScreen = mainModelsAndEffects
      |> map { Screen.Main($0.0) }
    
    // Show the settings screen after the Settings button is clicked, and on
    // launch if no settings have been restored
    let shouldDisplaySettingsScreen = SignalProducer(values: restoredSettings == nil ? [()] : [])
      |> concat (
        mainModelsAndEffects
          |> joinMap(.Latest) { $0.effects }
          |> filter {
            switch $0 {
            case .OpenSettings:
              return true
            default:
              return false
            }
          }
          |> map { _ in () }
      )
      |> map { _ in Screen.Settings(settingsModel) }
    
    // If settings haven't been entered yet, this is probably the first launch.
    // We should open the panel to show the user where it is.
    shouldOpenPanelOnLaunch = restoredSettings == nil
    
    effects = SignalProducer(values: [
      shouldDisplayMainScreen
        |> map { .DisplayScreen($0) },
      shouldDisplaySettingsScreen
        |> map { .DisplayScreen($0) },
      mainModelsAndEffects
        |> joinMap(.Latest) { $0.effects}
        |> map { .MainScreen($0) },
      ])
      |> join(.Merge)
  }
}

protocol SettingsStore {
  func saveSettings(settings: Settings) -> ()
  func restoreSettings() -> Settings?
}
