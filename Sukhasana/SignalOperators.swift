//
//  SignalOperators.swift
//  Sukhasana
//
//  Created by Tom Brow on 2/16/15.
//  Copyright (c) 2015 Tom Brow. All rights reserved.
//

import ReactiveCocoa

func startWith<T, E>(value: T)(producer: ReactiveCocoa.SignalProducer<T, E>) -> ReactiveCocoa.SignalProducer<T, E> {
  return SignalProducer(value: value) |> concat(producer)
}

func catchTo<T, E>(value: T)(producer: ReactiveCocoa.SignalProducer<T, E>) -> ReactiveCocoa.SignalProducer<T, NoError> {
  return catch({ _ in SignalProducer<T, NoError>(value: value) })(producer: producer)
}

func propertyOf<T>(initialValue: T, producer: SignalProducer<T, NoError>) -> PropertyOf<T> {
  let mutableProperty = MutableProperty(initialValue)
  mutableProperty <~ producer
  return PropertyOf(mutableProperty)
}

func replay<T, E>(capacity: Int = Int.max)(producer: ReactiveCocoa.SignalProducer<T, E>) -> ReactiveCocoa.SignalProducer<T, E> {
  let (returnedProducer, sink) = SignalProducer<T, E>.buffer(capacity)
  producer.start(sink)
  return returnedProducer
}