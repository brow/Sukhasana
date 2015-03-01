//
//  MainScreenModel.swift
//  Sukhasana
//
//  Created by Tom Brow on 2/8/15.
//  Copyright (c) 2015 Tom Brow. All rights reserved.
//

import ReactiveCocoa

struct MainScreenModel {
  let textFieldText = MutableProperty("")
  let activityIndicatorIsAnimating: PropertyOf<Bool>
  let tableViewShouldReloadData: SignalProducer<(), NoError>
  let didClickSettingsButton: Signal<(), NoError>.Observer
  let didClickRowAtIndex: Signal<Int, NoError>.Observer
  
  static func makeWithSettings(settings: Settings) -> (
    MainScreenModel,
    didClickSettingsButton: SignalProducer<(), NoError>,
    URLsToOpen: SignalProducer<NSURL, NoError>)
  {
    let (didClickSettingsButton, didClickSettingsButtonSink) = SignalProducer<(), NoError>.buffer(1)
    let (URLsToOpen, URLsToOpenSink) = SignalProducer<NSURL, NoError>.buffer(1)
    
    return (
      MainScreenModel(
        settings: settings,
        didClickSettingsButtonSink: didClickSettingsButtonSink,
        URLsToOpenSink: URLsToOpenSink),
      didClickSettingsButton: didClickSettingsButton,
      URLsToOpen: URLsToOpen
    )
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
      return results[row].name.stringByReplacingOccurrencesOfString("\n", withString: "⏎")
    case .Initial, .Fetching, .Failed:
      fatalError("no rows should be displayed in this state")
    }
  }
  
  // MARK: private
  
  private let resultsState: PropertyOf<ResultsState>
  
  private init(
    settings: Settings,
    didClickSettingsButtonSink: Signal<(), NoError>.Observer,
    URLsToOpenSink: Signal<NSURL, NoError>.Observer)
  {
    let client = APIClient(APIKey: settings.APIKey)
    
    resultsState = propertyOf(.Initial, textFieldText.producer
      |> map { query in
        query == ""
          ? SignalProducer<[Result], NSError>(value: []) // The empty query always returns no results, so don't bother
          : (client.requestTasksInWorkspace(settings.workspaceID, matchingQuery: query) |> map(resultsFromJSON))
      }
      |> map { request in
        request
          |> map { results in .Fetched(results) }
          |> catchTo(.Failed)
          |> startWith(.Fetching)
      }
      |> join(.Latest))
    
    activityIndicatorIsAnimating = propertyOf(false, resultsState.producer
      |> map { resultsState in
        switch resultsState {
        case .Fetching:
          return true
        case .Initial, .Failed, .Fetched:
          return false
        }
      })
    
    tableViewShouldReloadData = resultsState.producer |> map { _ in () }
    
    didClickSettingsButton = didClickSettingsButtonSink
    
    let (didClickRowAtIndexProducer, didClickRowAtIndexSink) = SignalProducer<Int, NoError>.buffer(1)
    didClickRowAtIndex = didClickRowAtIndexSink
    resultsState.producer
      |> sampleOn(didClickRowAtIndexProducer |> map {_ in ()})
      |> zipWith(didClickRowAtIndexProducer)
      |> map { resultsState, index in
        switch resultsState {
        case .Fetched(let results):
          return results[index].URL
        case .Initial, .Fetching, .Failed:
          fatalError()
        }}
      |> start(URLsToOpenSink)
  }
}

private enum ResultsState {
  case Initial
  case Fetching
  case Failed
  case Fetched([Result])
}

private struct Result {
  let name, id: String
  var URL: NSURL {
    // FIXME: escape id
    return NSURL(string: "https://app.asana.com/0/\(id)/\(id)")!
  }
}

private func resultsFromJSON(JSON: NSDictionary) -> [Result] {
  var names = [Result]()
  if let data = JSON["data"] as? Array<Dictionary<String, AnyObject>> {
    for object in data {
      if let name = object["name"] as? String {
        if let id = object["id"] as? NSNumber {
          names.append(Result(name: name, id: id.stringValue))
        }
      }
    }
  }
  return names
}

