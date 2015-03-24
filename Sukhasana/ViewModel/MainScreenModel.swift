//
//  MainScreenModel.swift
//  Sukhasana
//
//  Created by Tom Brow on 2/8/15.
//  Copyright (c) 2015 Tom Brow. All rights reserved.
//

import ReactiveCocoa

struct MainScreenModel {
  enum Effect {
    case OpenSettings
    case Results(ResultsTableViewModel.Effect)
  }
  
  let textFieldText = MutableProperty("")
  let activityIndicatorIsAnimating: PropertyOf<Bool>
  let resultsTableViewModel: PropertyOf<ResultsTableViewModel>
  let didClickSettingsButton: Signal<(), NoError>.Observer
  
  static func makeWithSettings(settings: Settings) -> (
    MainScreenModel,
    effects: SignalProducer<Effect, NoError>)
  {
    let (effects, effectsSink) = SignalProducer<Effect, NoError>.buffer(1)
    
    return (
      MainScreenModel(
        settings: settings,
        effectsSink: effectsSink),
      effects: effects
    )
  }
  
  // MARK: private
  
  private init(
    settings: Settings,
    effectsSink: Signal<Effect, NoError>.Observer)
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
    
    let resultsTableViewModelsAndEffects: SignalProducer<(ResultsTableViewModel, SignalProducer<ResultsTableViewModel.Effect, NoError>), NoError> =
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
      resultsTableViewModelsAndEffects |> map { $0.0 } )
    
    resultsTableViewModelsAndEffects
      |> joinMap(.Latest) { $0.1 }
      |> map { .Results($0) }
      |> start(effectsSink)
    
    activityIndicatorIsAnimating = propertyOf(false, fetchState
      |> map { resultsState in
        switch resultsState {
        case .Fetching:
          return true
        case .Initial, .Failed, .Fetched:
          return false
        }
      })
    
    didClickSettingsButton = {
      let buffer = SignalProducer<(), NoError>.buffer(1)
      buffer.0
        |> map { _ in .OpenSettings}
        |> start(effectsSink)
      return buffer.1
    }()
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

