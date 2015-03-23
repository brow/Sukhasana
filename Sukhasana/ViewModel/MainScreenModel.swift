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
  let resultsTableViewModel: PropertyOf<ResultsTableViewModel>
  let didClickSettingsButton: Signal<(), NoError>.Observer
  
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
  
  // MARK: private
  
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
    
    let resultsTableViewModelsAndSignals: SignalProducer<(ResultsTableViewModel, SignalProducer<NSURL, NoError>), NoError> =
    fetchState
      |> map { fetchState in
        switch fetchState {
        case .Fetched(let results):
          return ResultsTableViewModel.makeWithResults(results)
        case .Initial, .Failed, .Fetching:
          return ResultsTableViewModel.makeWithResults(Results.empty)
        }
      }
      |> replay(capacity: 1)
    
    resultsTableViewModel = propertyOf(
      ResultsTableViewModel.makeWithResults(Results.empty).0,
      resultsTableViewModelsAndSignals |> map { $0.0 } )
    
    resultsTableViewModelsAndSignals
      |> map { $0.1 }
      |> join(.Latest)
      |> start(URLsToOpenSink)
    
    activityIndicatorIsAnimating = propertyOf(false, fetchState
      |> map { resultsState in
        switch resultsState {
        case .Fetching:
          return true
        case .Initial, .Failed, .Fetched:
          return false
        }
      })
    
    didClickSettingsButton = didClickSettingsButtonSink
  }
}

private enum FetchState {
  case Initial
  case Fetching
  case Failed
  case Fetched(Results)
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

