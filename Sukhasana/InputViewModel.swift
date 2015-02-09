//
//  InputViewModel.swift
//  Sukhasana
//
//  Created by Tom Brow on 2/8/15.
//  Copyright (c) 2015 Tom Brow. All rights reserved.
//

import ReactiveCocoa
import Alamofire

class InputViewModel {
  let textFieldText = MutableProperty("")
  
  init() {
    let taskRequests: SignalProducer<SignalProducer<NSDictionary, NSError>, NoError> = textFieldText.producer
      |> map { text in requestTasks(text) }
    
    taskRequests.start { request in
      request.start { dict in
        println("\(dict)")
      }
      return
    }
  }
  
  func numberOfRows() -> Int {
    return 1
  }
  
  func stringForRow(row: Int) -> String {
    return "Hello"
  }
}

private let requestManager: Alamofire.Manager = {
  let APIKey = "4cAUaVhk.Vt70w5u6rOHQgsy3fsLoX9v"
  
  let config = NSURLSessionConfiguration.defaultSessionConfiguration()
  config.HTTPAdditionalHeaders = ["Authorization": "Basic " + ("\(APIKey):" as NSString)
    .dataUsingEncoding(NSUTF8StringEncoding)!
    .base64EncodedStringWithOptions(NSDataBase64EncodingOptions.allZeros)]
  
  return Manager(configuration: config)
}()

private func requestTasks(query: String) -> SignalProducer<NSDictionary, NSError> {
  let workspaceID = 14801884099708
  let typeaheadType = "task"
  
  return SignalProducer { observer, _ in
    requestManager
      .request(
        .GET,
        "https://app.asana.com/api/1.0/workspaces/\(workspaceID)/typeahead",
        parameters: ["type": typeaheadType, "query": query])
      .responseJSON {_, _, JSON, error in
        if let error = error {
          sendError(observer, error)
        } else {
          if let dict = JSON as? NSDictionary {
            sendNext(observer, dict)
          }
          sendCompleted(observer)
        }
    }
    return
  }
}

