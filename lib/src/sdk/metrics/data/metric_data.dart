// Copyright 2021-2022 Workiva.
// Licensed under the Apache License, Version 2.0. Please see https://github.com/Workiva/opentelemetry-dart/blob/master/LICENSE for more information

import 'package:fixnum/fixnum.dart';
import 'package:opentelemetry/api.dart' as api;
import 'package:opentelemetry/src/sdk/common/instrumentation_scope.dart';
import 'package:opentelemetry/src/sdk/resource/resource.dart';

/// The type of aggregation for a metric.
enum AggregationType {
  /// Sum aggregation.
  sum,

  /// Last value aggregation.
  lastValue,

  /// Histogram aggregation.
  histogram,
}

/// Base class for point data.
abstract class PointData {
  /// The start time of the measurement.
  final Int64 startTime;

  /// The end time of the measurement.
  final Int64 endTime;

  /// The attributes associated with this point.
  final List<api.Attribute> attributes;

  const PointData({
    required this.startTime,
    required this.endTime,
    this.attributes = const [],
  });
}

/// Point data for sum aggregation.
class SumPointData extends PointData {
  /// The sum value.
  final num value;

  /// Whether the sum is monotonic.
  final bool isMonotonic;

  const SumPointData({
    required super.startTime,
    required super.endTime,
    super.attributes,
    required this.value,
    this.isMonotonic = true,
  });
}

/// Point data for gauge (last value) aggregation.
class GaugePointData extends PointData {
  /// The last recorded value.
  final num value;

  const GaugePointData({
    required super.startTime,
    required super.endTime,
    super.attributes,
    required this.value,
  });
}

/// Point data for histogram aggregation.
class HistogramPointData extends PointData {
  /// The count of values.
  final int count;

  /// The sum of values.
  final num sum;

  /// The minimum value.
  final num? min;

  /// The maximum value.
  final num? max;

  /// The bucket boundaries.
  final List<double> boundaries;

  /// The bucket counts.
  final List<int> bucketCounts;

  const HistogramPointData({
    required super.startTime,
    required super.endTime,
    super.attributes,
    required this.count,
    required this.sum,
    this.min,
    this.max,
    this.boundaries = const [],
    this.bucketCounts = const [],
  });
}

/// Represents a collection of metric data points.
class MetricData {
  /// The resource associated with this metric.
  final Resource resource;

  /// The instrumentation scope that created this metric.
  final InstrumentationScope instrumentationScope;

  /// The name of the metric.
  final String name;

  /// The description of the metric.
  final String description;

  /// The unit of the metric.
  final String unit;

  /// The type of aggregation.
  final AggregationType aggregationType;

  /// The data points.
  final List<PointData> points;

  const MetricData({
    required this.resource,
    required this.instrumentationScope,
    required this.name,
    this.description = '',
    this.unit = '',
    required this.aggregationType,
    this.points = const [],
  });
}
