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
  
  let didClickRowAtIndex: Signal<Int, NoError>.Observer
  
  static func makeWithResults(results: Results) -> (
    ResultsTableViewModel,
    URLsToOpen: SignalProducer<NSURL, NoError>)
  {
    let (URLsToOpen, URLsToOpenSink) = SignalProducer<NSURL, NoError>.buffer(1)
    
    return (
      ResultsTableViewModel(
        results: results,
        URLsToOpenSink: URLsToOpenSink),
      URLsToOpen: URLsToOpen)
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
  
  init(results: Results, URLsToOpenSink: Signal<NSURL, NoError>.Observer) {
    let resultsTable = ResultsTable(results: results)
    self.resultsTable = resultsTable
    
    let (didClickRowAtIndexProducer, didClickRowAtIndexSink) = SignalProducer<Int, NoError>.buffer(1)
    didClickRowAtIndex = didClickRowAtIndexSink
    didClickRowAtIndexProducer
      |> mapOptional { index in
        switch self.resultsTable.rows[index] {
        case .Item(text: _, clickURL: let URL):
          return URL
        case .Separator:
          return nil
        }
      }
      |> start(URLsToOpenSink)
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