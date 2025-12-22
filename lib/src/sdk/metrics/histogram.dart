// Copyright 2021-2022 Workiva.
// Licensed under the Apache License, Version 2.0. Please see https://github.com/Workiva/opentelemetry-dart/blob/master/LICENSE for more information

import 'package:opentelemetry/api.dart' as api;
import 'package:opentelemetry/src/experimental_api.dart' as api;
import 'package:opentelemetry/src/sdk/metrics/aggregation/aggregator.dart';
import 'package:opentelemetry/src/sdk/time_providers/time_provider.dart';

/// SDK implementation of [api.Histogram].
class Histogram<T extends num> implements api.Histogram<T> {
  final String name;
  final String? description;
  final String? unit;
  final HistogramAggregator _aggregator;
  final TimeProvider _timeProvider;

  Histogram({
    required this.name,
    this.description,
    this.unit,
    required TimeProvider timeProvider,
    List<double> boundaries = const [
      0,
      5,
      10,
      25,
      50,
      75,
      100,
      250,
      500,
      750,
      1000,
      2500,
      5000,
      7500,
      10000
    ],
  })  : _aggregator = HistogramAggregator(boundaries: boundaries),
        _timeProvider = timeProvider;

  @override
  void record(T value,
      {List<api.Attribute>? attributes, api.Context? context}) {
    _aggregator.record(value, attributes ?? [], _timeProvider.now);
  }

  /// Returns the aggregator for this histogram.
  HistogramAggregator get aggregator => _aggregator;
}
