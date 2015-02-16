//
//  MainViewModel.swift
//  Sukhasana
//
//  Created by Tom Brow on 2/8/15.
//  Copyright (c) 2015 Tom Brow. All rights reserved.
//

import ReactiveCocoa
import Alamofire

class MainViewModel {
  let textFieldText = MutableProperty("")
  let tableViewShouldReloadData: SignalProducer<(), NoError>
  
  init() {
    tableViewShouldReloadData = textFieldText.producer |> map { _ in () }
    
    let resultsState: SignalProducer<SignalProducer<ResultsState, NSError>, NoError> = textFieldText.producer
      |> map { requestTasks($0) }
      |> map { $0 |> map(namesFromResultsJSON) }
      |> map { requestSignal in
        requestSignal
          |> map { ResultsState.Fetched($0) }
          |> startWith(ResultsState.Fetching)
      }
  }
  
  func numberOfRows() -> Int {
    return countElements(textFieldText.value)
  }
  
  func stringForRow(row: Int) -> String {
    return "Row \(row)"
  }
}

private func startWith<T, E>(value: T)(producer: ReactiveCocoa.SignalProducer<T, E>) -> ReactiveCocoa.SignalProducer<T, E> {
  return SignalProducer(value: value) |> concat(producer)
}
  
private enum ResultsState {
  case Fetching
  case Fetched([String])
  case Failed
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

private func namesFromResultsJSON(resultsJSON: NSDictionary) -> [String] {
  var names = [String]()
  if let data = resultsJSON["data"] as? Array<Dictionary<String, AnyObject>> {
    for object in data {
      if let name = object["name"] as? String {
        names.append(name)
      }
    }
  }
  return names
}