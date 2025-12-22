// Copyright 2021-2022 Workiva.
// Licensed under the Apache License, Version 2.0. Please see https://github.com/Workiva/opentelemetry-dart/blob/master/LICENSE for more information

import 'package:opentelemetry/api.dart' as api;
import 'package:opentelemetry/src/experimental_api.dart' as api;
import 'package:opentelemetry/src/sdk/metrics/aggregation/aggregator.dart';
import 'package:opentelemetry/src/sdk/time_providers/time_provider.dart';

/// SDK implementation of [api.Gauge].
class Gauge<T extends num> implements api.Gauge<T> {
  final String name;
  final String? description;
  final String? unit;
  final LastValueAggregator _aggregator;
  final TimeProvider _timeProvider;

  Gauge({
    required this.name,
    this.description,
    this.unit,
    required TimeProvider timeProvider,
  })  : _aggregator = LastValueAggregator(),
        _timeProvider = timeProvider;

  @override
  void record(T value,
      {List<api.Attribute>? attributes, api.Context? context}) {
    _aggregator.record(value, attributes ?? [], _timeProvider.now);
  }

  /// Returns the aggregator for this gauge.
  LastValueAggregator get aggregator => _aggregator;
}
