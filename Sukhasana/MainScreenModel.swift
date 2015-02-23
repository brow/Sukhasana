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
  let tableViewShouldReloadData: SignalProducer<(), NoError>
  let didClickSettingsButton: () -> ()
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
      return results[row]
    case .Initial, .Fetching, .Failed:
      fatalError("no rows should be displayed in this state")
    }
  }
  
  // MARK: private
  
  private let resultsState = MutableProperty(ResultsState.Initial)
  
  private init(
    settings: Settings,
    didClickSettingsButtonSink: Signal<(), NoError>.Observer,
    URLsToOpenSink: Signal<NSURL, NoError>.Observer)
  {
    let client = APIClient(APIKey: settings.APIKey)
    
    resultsState <~ textFieldText.producer
      |> map { client.requestTasksInWorkspace(settings.workspaceID, matchingQuery: $0) }
      |> map { $0 |> map(namesFromResultsJSON) }
      |> map { $0
        |> map { .Fetched($0) }
        |> catchTo(.Failed)
        |> startWith(.Fetching)
      }
      |> latest
    
    tableViewShouldReloadData = resultsState.producer |> map { _ in () }
    
    didClickSettingsButton = { sendNext(didClickSettingsButtonSink, ()) }
    
    let (didClickRowAtIndexProducer, didClickRowAtIndex) = SignalProducer<Int, NoError>.buffer(1)
    self.didClickRowAtIndex = didClickRowAtIndex
    resultsState.producer
      |> sampleOn(didClickRowAtIndexProducer |> map {_ in ()})
      |> map { resultsState in
        switch resultsState {
        case .Fetched(let results):
          return NSURL(string: "https://app.asana.com/0/27089193997842/27089193997842")!
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
  case Fetched([String])
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

