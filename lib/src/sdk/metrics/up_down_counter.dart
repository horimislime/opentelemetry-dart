// Copyright 2021-2022 Workiva.
// Licensed under the Apache License, Version 2.0. Please see https://github.com/Workiva/opentelemetry-dart/blob/master/LICENSE for more information

import 'package:opentelemetry/api.dart' as api;
import 'package:opentelemetry/src/experimental_api.dart' as api;
import 'package:opentelemetry/src/sdk/metrics/aggregation/aggregator.dart';
import 'package:opentelemetry/src/sdk/time_providers/time_provider.dart';

/// SDK implementation of [api.UpDownCounter].
class UpDownCounter<T extends num> implements api.UpDownCounter<T> {
  final String name;
  final String? description;
  final String? unit;
  final SumAggregator _aggregator;
  final TimeProvider _timeProvider;

  UpDownCounter({
    required this.name,
    this.description,
    this.unit,
    required TimeProvider timeProvider,
  })  : _aggregator = SumAggregator(isMonotonic: false),
        _timeProvider = timeProvider;

  @override
  void add(T value, {List<api.Attribute>? attributes, api.Context? context}) {
    _aggregator.record(value, attributes ?? [], _timeProvider.now);
  }

  /// Returns the aggregator for this counter.
  SumAggregator get aggregator => _aggregator;
}
