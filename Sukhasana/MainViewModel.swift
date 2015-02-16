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
    tableViewShouldReloadData = resultsState.producer |> map { _ in () }

    resultsState <~ textFieldText.producer
      |> map { requestTasks($0) }
      |> map { $0 |> map(namesFromResultsJSON) }
      |> map { $0
          |> map { .Fetched($0) }
          |> catchTo(.Failed)
          |> startWith(.Fetching)
      }
      |> latest
  }
  
  func numberOfRows() -> Int {
    switch resultsState.value {
    case .Fetched(let results):
      return countElements(results)
    case .Initial, .Fetching, .Failed:
      return 0
    }
  }
  
  func stringForRow(row: Int) -> String {
    switch resultsState.value {
    case .Fetched(let results):
      return results[row]
    case .Initial, .Fetching, .Failed:
      fatalError("no rows should be displayed in this state")
    }
  }
  
  // MARK: private
  
  private let resultsState = MutableProperty(ResultsState.Initial)
}

private func startWith<T, E>(value: T)(producer: ReactiveCocoa.SignalProducer<T, E>) -> ReactiveCocoa.SignalProducer<T, E> {
  return SignalProducer(value: value) |> concat(producer)
}

private func catchTo<T, E>(value: T)(producer: ReactiveCocoa.SignalProducer<T, E>) -> ReactiveCocoa.SignalProducer<T, NoError> {
  return catch({ _ in SignalProducer<T, NoError>(value: value) })(producer: producer)
}
  
private enum ResultsState {
  case Initial
  case Fetching
  case Failed
  case Fetched([String])
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