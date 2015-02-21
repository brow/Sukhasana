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
    let (settingsViewModel, savedSettings) = SettingsScreenModel.make()
    shouldDisplayScreen = savedSettings
      |> map { .Main(MainScreenModel(settings: $0)) }
      |> startWith(.Settings(settingsViewModel))
  }
}