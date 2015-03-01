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
    return countElements(resultsTable.value.rows)
  }
  
  func stringForRow(row: Int) -> String {
    switch resultsTable.value.rows[row] {
    case let .Item(text: text, clickURL: _):
      return text
    }
  }
  
  // MARK: private
  
  private let resultsTable: PropertyOf<ResultsTable>
  
  private init(
    settings: Settings,
    didClickSettingsButtonSink: Signal<(), NoError>.Observer,
    URLsToOpenSink: Signal<NSURL, NoError>.Observer)
  {
    let client = APIClient(APIKey: settings.APIKey)
    
    let fetchState: SignalProducer<FetchState, NoError> = textFieldText.producer
      |> map { query -> SignalProducer<Results, NSError> in
        if query == "" {
          // The empty query always returns no results, so don't bother
          return SignalProducer(value: Results(projects: [], tasks: []))
        } else {
          let request = { type in
            client.requestTypeaheadResultsInWorkspace(settings.workspaceID, ofType: type, matchingQuery: query)
              |> map(resultsFromJSON)
          }
          return zip(request(.Project), request(.Task))
            |> map { projects, tasks in Results(projects: projects, tasks: tasks) }
        }
      }
      |> map { request in
        request
          |> map { results in .Fetched(results) }
          |> catchTo(.Failed)
          |> startWith(.Fetching)
      }
      |> join(.Latest)
      |> replay(capacity: 1)
    
    resultsTable = propertyOf(ResultsTable(), fetchState
      |> map { fetchState in
        switch fetchState {
        case .Fetched(let results):
          return ResultsTable(results: results)
        case .Initial, .Failed, .Fetching:
          return ResultsTable()
        }
      })
    
    activityIndicatorIsAnimating = propertyOf(false, fetchState
      |> map { resultsState in
        switch resultsState {
        case .Fetching:
          return true
        case .Initial, .Failed, .Fetched:
          return false
        }
      })
    
    tableViewShouldReloadData = resultsTable.producer |> map { _ in () }
    
    didClickSettingsButton = didClickSettingsButtonSink
    
    let (didClickRowAtIndexProducer, didClickRowAtIndexSink) = SignalProducer<Int, NoError>.buffer(1)
    didClickRowAtIndex = didClickRowAtIndexSink
    resultsTable.producer
      |> sampleOn(didClickRowAtIndexProducer |> map { _ in ()})
      |> zipWith(didClickRowAtIndexProducer)
      |> map { resultsTable, index in
        switch resultsTable.rows[index] {
        case .Item(text: _, clickURL: let URL):
          return URL
        }
      }
      |> start(URLsToOpenSink)
  }
}

private enum FetchState {
  case Initial
  case Fetching
  case Failed
  case Fetched(Results)
}

private struct Results {
  let projects, tasks: [Result]
}

private struct ResultsTable {
  enum Row {
    case Item(text: String, clickURL: NSURL)
  }
  
  let rows: [Row]
  
  init () {
    rows = []
  }
  
  init(results: Results) {
    rows = (results.projects + results.tasks).map { result in
      .Item(
        text: result.name.stringByReplacingOccurrencesOfString("\n", withString: "⏎"),
        clickURL: result.URL)
    }
  }
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

