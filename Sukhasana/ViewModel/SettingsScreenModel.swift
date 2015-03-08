//
//  SettingsScreenModel.swift
//  Sukhasana
//
//  Created by Tom Brow on 2/16/15.
//  Copyright (c) 2015 Tom Brow. All rights reserved.
//

import ReactiveCocoa

struct SettingsScreenModel {
  let shortcutViewAssociatedUserDefaultsKey: String
  let APIKeyTextFieldText: MutableProperty<String>
  let saveButtonEnabled, workspacePopUpButtonEnabled, progressIndicatorAnimating: PropertyOf<Bool>
  let workspacePopUpItemsTitles: PropertyOf<[String]>
  let workspacePopupSelectedIndex: PropertyOf<Int>
  let didClickSaveButton: Signal<(), NoError>.Observer
  let workspacePopUpDidSelectItemAtIndex: Signal<Int, NoError>.Observer
  
  static func makeWithSettings(settings: Settings?, globalShortcutDefaultsKey: String) -> (SettingsScreenModel, didSaveSettings: SignalProducer<Settings, NoError>) {
    let (didSaveSettings, didSaveSettingsSink) = SignalProducer<Settings, NoError>.buffer(1)
    
    return (
      SettingsScreenModel(
        settings: settings,
        globalShortcutDefaultsKey: globalShortcutDefaultsKey,
        didSaveSettingsSink: didSaveSettingsSink),
      didSaveSettings: didSaveSettings)
  }
  
  // MARK: private
  
  private init(
    settings: Settings?,
    globalShortcutDefaultsKey: String,
    didSaveSettingsSink: Signal<Settings, NoError>.Observer)
  {
    shortcutViewAssociatedUserDefaultsKey = globalShortcutDefaultsKey
    APIKeyTextFieldText = MutableProperty(settings?.APIKey ?? "")
    
    let workspacesState: SignalProducer<WorkspacesState, NoError> = APIKeyTextFieldText.producer
      |> map { APIClient(APIKey: $0) }
      |> map { $0.requestWorkspaces() }
      |> map { $0 |> map(workspacesFromJSON) }
      |> map { $0
        |> map { .Fetched($0) }
        |> catchTo(.Failed)
        |> startWith(.Fetching)
      }
      |> join(.Latest)
      |> replay(capacity: 1)
    
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
    
    workspacePopupSelectedIndex = propertyOf(0,
      SignalProducer(values: [
        workspaceSelectedIndexes,
        workspacePopUpItemsTitles.producer |> map { _ in 0 }
        ])
        |> join(.Merge)
    )
    
    let (didClickSaveButtonProducer, didClickSaveButtonSink) = SignalProducer<(), NoError>.buffer(1)
    didClickSaveButton = didClickSaveButtonSink
    combineLatest(workspacesState, workspacePopupSelectedIndex.producer, APIKeyTextFieldText.producer)
      |> sampleOn(didClickSaveButtonProducer)
      |> map { workspacesState, workspacePopupSelectedIndex, APIKeyTextFieldText in
        switch workspacesState {
        case .Fetched(let workspaces):
          return Settings(
            APIKey: APIKeyTextFieldText,
            workspaceID: workspaces[workspacePopupSelectedIndex].id)
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
