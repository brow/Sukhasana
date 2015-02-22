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
  
  init() {
    let (settingsModel, didSaveSettings) = SettingsScreenModel.make()
    
    // Show the main screen after settings are saved
    let mainModelAndDidClickSettingsButton = didSaveSettings
      |> map(MainScreenModel.makeWithSettings)
      |> replay(capacity: 1)
    
    let shouldDisplayMainScreen: SignalProducer<Screen, NoError> = mainModelAndDidClickSettingsButton
      |> map { (mainModel, _) in .Main(mainModel) }
    
    // Show the settings screen immediately and whenever the Settings button is clicked
    let shouldDisplaySettingsScreen: SignalProducer<Screen, NoError> = mainModelAndDidClickSettingsButton
      |> latestMap { (_, didClickSettingsButton) in didClickSettingsButton }
      |> startWith(())
      |> map { _ in .Settings(settingsModel) }
  
    shouldDisplayScreen = SignalProducer(values: [shouldDisplayMainScreen, shouldDisplaySettingsScreen])
      |> merge
  }
}