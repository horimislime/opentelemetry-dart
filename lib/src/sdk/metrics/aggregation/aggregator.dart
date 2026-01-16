// Copyright 2021-2022 Workiva.
// Licensed under the Apache License, Version 2.0. Please see https://github.com/Workiva/opentelemetry-dart/blob/master/LICENSE for more information

import 'package:fixnum/fixnum.dart';
import 'package:opentelemetry/api.dart' as api;

import '../data/metric_data.dart';

/// Base class for aggregators.
abstract class Aggregator<T extends PointData> {
  /// Records a measurement.
  void record(num value, List<api.Attribute> attributes, Int64 timestamp);

  /// Collects the aggregated data and returns a list of point data.
  List<T> collect(Int64 startTime, Int64 endTime);

  /// Resets the aggregator state.
  void reset();
}

/// Aggregator for sum values.
class SumAggregator extends Aggregator<SumPointData> {
  final bool _isMonotonic;
  final Map<String, _SumAccumulator> _accumulators = {};

  SumAggregator({bool isMonotonic = true}) : _isMonotonic = isMonotonic;

  @override
  void record(num value, List<api.Attribute> attributes, Int64 timestamp) {
    final key = _attributeKey(attributes);
    final accumulator = _accumulators.putIfAbsent(
      key,
      () => _SumAccumulator(attributes: attributes, firstRecordTime: timestamp),
    );
    accumulator.add(value);
  }

  @override
  List<SumPointData> collect(Int64 startTime, Int64 endTime) {
    // For cumulative temporality, use the first recorded timestamp as startTime
    return _accumulators.values.map((acc) {
      return SumPointData(
        startTime: acc.firstRecordTime,
        endTime: endTime,
        attributes: acc.attributes,
        value: acc.value,
        isMonotonic: _isMonotonic,
      );
    }).toList();
  }

  @override
  void reset() {
    _accumulators.clear();
  }

  String _attributeKey(List<api.Attribute> attributes) {
    final sorted = List<api.Attribute>.from(attributes)
      ..sort((a, b) => a.key.compareTo(b.key));
    return sorted.map((a) => '${a.key}=${a.value}').join(',');
  }
}

class _SumAccumulator {
  final List<api.Attribute> attributes;
  final Int64 firstRecordTime;
  num value = 0;

  _SumAccumulator({required this.attributes, required this.firstRecordTime});

  void add(num delta) {
    value += delta;
  }
}

/// Aggregator for last value (gauge).
class LastValueAggregator extends Aggregator<GaugePointData> {
  final Map<String, _LastValueAccumulator> _accumulators = {};

  @override
  void record(num value, List<api.Attribute> attributes, Int64 timestamp) {
    final key = _attributeKey(attributes);
    final accumulator = _accumulators.putIfAbsent(
      key,
      () => _LastValueAccumulator(attributes: attributes),
    );
    accumulator.record(value, timestamp);
  }

  @override
  List<GaugePointData> collect(Int64 startTime, Int64 endTime) {
    return _accumulators.values.map((acc) {
      return GaugePointData(
        startTime: startTime,
        endTime: endTime,
        attributes: acc.attributes,
        value: acc.value,
      );
    }).toList();
  }

  @override
  void reset() {
    _accumulators.clear();
  }

  String _attributeKey(List<api.Attribute> attributes) {
    final sorted = List<api.Attribute>.from(attributes)
      ..sort((a, b) => a.key.compareTo(b.key));
    return sorted.map((a) => '${a.key}=${a.value}').join(',');
  }
}

class _LastValueAccumulator {
  final List<api.Attribute> attributes;
  num value = 0;
  Int64 timestamp = Int64.ZERO;

  _LastValueAccumulator({required this.attributes});

  void record(num newValue, Int64 newTimestamp) {
    if (newTimestamp >= timestamp) {
      value = newValue;
      timestamp = newTimestamp;
    }
  }
}

/// Aggregator for histogram values.
class HistogramAggregator extends Aggregator<HistogramPointData> {
  final List<double> _boundaries;
  final Map<String, _HistogramAccumulator> _accumulators = {};

  HistogramAggregator({
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
  }) : _boundaries = boundaries;

  @override
  void record(num value, List<api.Attribute> attributes, Int64 timestamp) {
    final key = _attributeKey(attributes);
    final accumulator = _accumulators.putIfAbsent(
      key,
      () => _HistogramAccumulator(
        attributes: attributes,
        boundaries: _boundaries,
        firstRecordTime: timestamp,
      ),
    );
    accumulator.record(value);
  }

  @override
  List<HistogramPointData> collect(Int64 startTime, Int64 endTime) {
    // For cumulative temporality, use the first recorded timestamp as startTime
    return _accumulators.values.map((acc) {
      return HistogramPointData(
        startTime: acc.firstRecordTime,
        endTime: endTime,
        attributes: acc.attributes,
        count: acc.count,
        sum: acc.sum,
        min: acc.min,
        max: acc.max,
        boundaries: _boundaries,
        bucketCounts: acc.bucketCounts,
      );
    }).toList();
  }

  @override
  void reset() {
    _accumulators.clear();
  }

  String _attributeKey(List<api.Attribute> attributes) {
    final sorted = List<api.Attribute>.from(attributes)
      ..sort((a, b) => a.key.compareTo(b.key));
    return sorted.map((a) => '${a.key}=${a.value}').join(',');
  }
}

class _HistogramAccumulator {
  final List<api.Attribute> attributes;
  final List<double> boundaries;
  final Int64 firstRecordTime;
  late final List<int> bucketCounts;
  int count = 0;
  num sum = 0;
  num? min;
  num? max;

  _HistogramAccumulator({
    required this.attributes,
    required this.boundaries,
    required this.firstRecordTime,
  }) {
    // Number of buckets = boundaries.length + 1
    bucketCounts = List.filled(boundaries.length + 1, 0);
  }

  void record(num value) {
    count++;
    sum += value;
    min = (min == null || value < min!) ? value : min;
    max = (max == null || value > max!) ? value : max;

    // Find the bucket
    var bucketIndex = boundaries.length;
    for (var i = 0; i < boundaries.length; i++) {
      if (value < boundaries[i]) {
        bucketIndex = i;
        break;
      }
    }
    bucketCounts[bucketIndex]++;
  }
}
