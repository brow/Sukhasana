//
//  SettingsScreenModel.swift
//  Sukhasana
//
//  Created by Tom Brow on 2/16/15.
//  Copyright (c) 2015 Tom Brow. All rights reserved.
//

import ReactiveCocoa

struct SettingsScreenModel {
  let APIKeyTextFieldText: MutableProperty<String>
  let saveButtonEnabled, workspacePopUpButtonEnabled, progressIndicatorAnimating: PropertyOf<Bool>
  let workspacePopUpItemsTitles: PropertyOf<[String]>
  let workspacePopupSelectedIndex: PropertyOf<Int>
  let didClickSaveButton: Signal<(), NoError>.Observer
  let workspacePopUpDidSelectItemAtIndex: Signal<Int, NoError>.Observer
  
  static func makeWithSettings(settings: Settings?) -> (SettingsScreenModel, didSaveSettings: SignalProducer<Settings, NoError>) {
    let (didSaveSettings, didSaveSettingsSink) = SignalProducer<Settings, NoError>.buffer(1)
    
    return (
      SettingsScreenModel(settings: settings, didSaveSettingsSink: didSaveSettingsSink),
      didSaveSettings: didSaveSettings)
  }
  
  // MARK: private
  
  private init(settings: Settings?, didSaveSettingsSink: Signal<Settings, NoError>.Observer) {
    APIKeyTextFieldText = MutableProperty(settings?.APIKey ?? "")
    
    let enteredAPIKey = MutableProperty(settings?.APIKey ?? "")
    enteredAPIKey <~ APIKeyTextFieldText.producer
    
    let workspacesState: SignalProducer<WorkspacesState, NoError> = enteredAPIKey.producer
      |> map { APIClient(APIKey: $0) }
      |> map { $0.requestWorkspaces() }
      |> map { $0 |> map(workspacesFromJSON) }
      |> map { $0
        |> map { .Fetched($0) }
        |> catchTo(.Failed)
        |> startWith(.Fetching)
      }
      |> latest
    
    workspacePopUpButtonEnabled = propertyOf(false, workspacesState
      |> map { switch $0 {
      case .Fetched(let workspaces):
        return !isEmpty(workspaces)
      case .Initial, .Fetching, .Failed:
        return false
        }
      })
    
    saveButtonEnabled = workspacePopUpButtonEnabled
    
    progressIndicatorAnimating = propertyOf(false, workspacesState
      |> map { switch $0 {
      case .Fetching:
        return true
      case .Initial, .Fetched, .Failed:
        return false
        }
      })
    
    workspacePopUpItemsTitles = propertyOf([], workspacesState
      |> map { switch $0 {
      case .Fetched(let workspaces):
        return isEmpty(workspaces)
          ? ["(no workspaces)"]
          : workspaces.map { $0.name }
      case .Initial, .Fetching, .Failed:
        // Placeholder text for when popup is disabled
        return ["Workspace"]
        }
      })
    
    let (workspaceSelectedIndexes, workspaceSelectedIndexSink) = SignalProducer<Int, NoError>.buffer(1)
    workspacePopUpDidSelectItemAtIndex = workspaceSelectedIndexSink
    
    workspacePopupSelectedIndex = propertyOf(0, merge(SignalProducer(values: [
      workspaceSelectedIndexes,
      workspacePopUpItemsTitles.producer |> map { _ in 0 }
      ])))
    
    let (didClickSaveButtonProducer, didClickSaveButtonSink) = SignalProducer<(), NoError>.buffer(1)
    didClickSaveButton = didClickSaveButtonSink
    workspacesState
      |> combineLatestWith(workspacePopupSelectedIndex.producer)
      |> sampleOn(didClickSaveButtonProducer)
      |> map { workspacesState, selectedWorkspaceIndex in
        switch workspacesState {
        case .Fetched(let workspaces):
          return Settings(
            APIKey: enteredAPIKey.value,
            workspaceID: workspaces[selectedWorkspaceIndex].id)
        default:
          fatalError("can't save with no workspaces loaded")
        }}
      |> start(didSaveSettingsSink)

  }
}

private struct Workspace {
  let id, name: String
}

private enum WorkspacesState {
  case Initial
  case Fetching
  case Failed
  case Fetched([Workspace])
}

private func workspacesFromJSON(JSON: NSDictionary) -> [Workspace] {
  var workspaces = [Workspace]()
  if let data = JSON["data"] as? Array<Dictionary<String, AnyObject>> {
    for object in data {
      if let name = object["name"] as? String {
        if let id = object["id"] as? NSNumber {
          workspaces.append(Workspace(id: id.stringValue, name: name))
        }
      }
    }
  }
  return workspaces
}
