//
//  InputViewModel.swift
//  Sukhasana
//
//  Created by Tom Brow on 2/8/15.
//  Copyright (c) 2015 Tom Brow. All rights reserved.
//

import ReactiveCocoa

class InputViewModel {
  let textFieldText = MutableProperty("")
  
  init() {
    let workspaceID = 15793206719
    let typeaheadType = "task"
    
    let taskTypeaheadURLs: SignalProducer<NSURL, NoError> = textFieldText.producer
      |> map { text in NSURL(string: "https://app.asana.com/api/1.0/workspaces/\(workspaceID)/typeahead?type=\(typeaheadType)&query=\(text)")! }
    
    taskTypeaheadURLs.start { next in
      println("\(next)")
    }
  }
}
