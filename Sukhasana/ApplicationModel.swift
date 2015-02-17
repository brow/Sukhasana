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
  }
  
  let shouldDisplayScreen: SignalProducer<Screen, NoError>
  
  init() {
    let (settingsViewModel, savedSettings) = SettingsScreenModel.make()
    shouldDisplayScreen = SignalProducer(value: .Settings(settingsViewModel))
    savedSettings.start { settings in
      
    }
  }
}