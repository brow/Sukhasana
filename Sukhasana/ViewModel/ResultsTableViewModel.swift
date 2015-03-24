//
//  ResultsScreenModel.swift
//  Sukhasana
//
//  Created by Tom Brow on 3/22/15.
//  Copyright (c) 2015 Tom Brow. All rights reserved.
//

import Cocoa
import ReactiveCocoa

struct ResultsTableViewModel {
  enum Cell {
    case Selectable(String)
    case Separator
  }
  
  enum Action {
    case Click
    case Copy
  }
  
  enum Effect {
    case OpenURL(NSURL)
    case WriteObjectsToPasteboard([NSPasteboardWriting])
  }
  
  let didRecognizeActionOnRowAtIndex: Signal<(Action, Int), NoError>.Observer
    
  static func makeWithResults(results: Results) -> (
    ResultsTableViewModel,
    effects: SignalProducer<Effect, NoError>)
  {
    let (effects, effectsSink) = SignalProducer<Effect, NoError>.buffer(1)
    
    return (
      ResultsTableViewModel(
        results: results,
        effectsSink: effectsSink),
      effects: effects)
  }
  
  func numberOfRows() -> Int {
    return countElements(resultsTable.rows)
  }
  
  func cellForRow(row: Int) -> Cell {
    switch resultsTable.rows[row] {
    case let .Item(text: text, clickURL: _):
      return .Selectable(text)
    case .Separator:
      return .Separator
    }
  }
  
  func pasteboardObjectsForRow(row: Int) -> [NSPasteboardWriting]? {
    switch resultsTable.rows[row] {
      
    case let .Item(text: text, clickURL: URL):
      let hyperlink = NSAttributedString(
        string: text,
        attributes: [NSLinkAttributeName: URL])
      let item = NSPasteboardItem()
      item.setData(
        hyperlink.RTFFromRange(
          NSMakeRange(0, hyperlink.length),
          documentAttributes: nil ),
        forType: NSPasteboardTypeRTF)
      item.setString(
        URL.absoluteString,
        forType: NSPasteboardTypeString)
      return [item]
      
    case .Separator:
      return nil
    }
  }
  
  // MARK: private
  
  private let resultsTable: ResultsTable
  
  private init(results: Results, effectsSink: Signal<Effect, NoError>.Observer) {
    let resultsTable = ResultsTable(results: results)
    self.resultsTable = resultsTable
    
    didRecognizeActionOnRowAtIndex = {
      let buffer = SignalProducer<(Action, Int), NoError>.buffer(1)
      buffer.0
        |> mapOptional { (action, index) in
          switch resultsTable.rows[index] {
          case let .Item(text: text, clickURL: clickURL):
            switch action {
            case .Click:
              return .OpenURL(clickURL)
            case .Copy:
              let pasteboardItem = pasteboardItemForLinkWithText(text, URL: clickURL)
              return .WriteObjectsToPasteboard([pasteboardItem])
            }
          case .Separator:
            return nil
          }
        }
        |> start(effectsSink)
      return buffer.1
    }()

  }
}

private struct ResultsTable {
  enum Row {
    case Item(text: String, clickURL: NSURL)
    case Separator
  }
  
  let rows: [Row]
  
  init () {
    rows = []
  }
  
  init(results: Results) {
    let sections: [[Row]] = [results.projects, results.tasks]
      .filter { !$0.isEmpty }
      .map { section in
        section.map { result in
          .Item(
            text: result.name.stringByReplacingOccurrencesOfString("\n", withString: "⏎"),
            clickURL: result.URL)
        }}
    
    rows = [.Separator].join(sections)
  }
}

private func pasteboardItemForLinkWithText(text: String, #URL: NSURL) -> NSPasteboardItem {
  let hyperlink = NSAttributedString(
    string: text,
    attributes: [NSLinkAttributeName: URL])
  
  let item = NSPasteboardItem()
  item.setData(
    hyperlink.RTFFromRange(
      NSMakeRange(0, hyperlink.length),
      documentAttributes: nil ),
    forType: NSPasteboardTypeRTF)
  item.setString(
    URL.absoluteString,
    forType: NSPasteboardTypeString)
  
  return item
}
