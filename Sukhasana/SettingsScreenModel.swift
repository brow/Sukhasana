//
//  SettingsScreenModel.swift
//  Sukhasana
//
//  Created by Tom Brow on 2/16/15.
//  Copyright (c) 2015 Tom Brow. All rights reserved.
//

import ReactiveCocoa

struct SettingsScreenModel {
  let APIKeyTextFieldText = MutableProperty("")
  let saveButtonEnabled, workspacePopUpButtonEnabled, progressIndicatorAnimating: PropertyOf<Bool>
  let workspacePopUpItemsTitles: PropertyOf<[String]>
  let didClickSaveButton: () -> ()
  
  static func make() -> (SettingsScreenModel, savedSettings: SignalProducer<Settings, NoError>) {
    let (savedSettings, savedSettingSink) = SignalProducer<Settings, NoError>.buffer()
    return (SettingsScreenModel(savedSettingsSink: savedSettingSink), savedSettings)
  }
  
  // MARK: private
  
  private init(savedSettingsSink: Signal<Settings, NoError>.Observer) {
    let enteredAPIKey = MutableProperty("")
    enteredAPIKey <~ APIKeyTextFieldText.producer
    
    workspacesState <~ enteredAPIKey.producer
      |> map { APIClient(APIKey: $0) }
      |> map { $0.requestWorkspaces() }
      |> map { $0 |> map(workspacesFromJSON) }
      |> map { $0
        |> map { .Fetched($0) }
        |> catchTo(.Failed)
        |> startWith(.Fetching)
      }
      |> latest
    
    workspacePopUpButtonEnabled = propertyOf(false, workspacesState.producer
      |> map { switch $0 {
      case .Fetched(let workspaces):
        return !isEmpty(workspaces)
      case .Initial, .Fetching, .Failed:
        return false
        }
      })
    
    saveButtonEnabled = workspacePopUpButtonEnabled
    
    progressIndicatorAnimating = propertyOf(false, workspacesState.producer
      |> map { switch $0 {
      case .Fetching:
        return true
      case .Initial, .Fetched, .Failed:
        return false
        }
      })
    
    workspacePopUpItemsTitles = propertyOf([], workspacesState.producer
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
    
    didClickSaveButton = {
      sendNext(
        savedSettingsSink,
        Settings(
          APIKey: enteredAPIKey.value,
          workspaceID: "FIXME"))
      return
    }
  }

  private let workspacesState = MutableProperty(WorkspacesState.Initial)
}

struct Settings {
  let APIKey, workspaceID: String
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
