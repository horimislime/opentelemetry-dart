// Copyright 2021-2022 Workiva.
// Licensed under the Apache License, Version 2.0. Please see https://github.com/Workiva/opentelemetry-dart/blob/master/LICENSE for more information

import 'package:fixnum/fixnum.dart';
import 'package:meta/meta.dart';

import '../../experimental_api.dart' as api;
import '../../experimental_sdk.dart' as sdk;
import '../common/instrumentation_scope.dart';
import '../resource/resource.dart';
import '../time_providers/time_provider.dart';
import 'data/metric_data.dart';
import 'export/metric_reader.dart';

/// SDK implementation of [api.Meter].
class Meter implements api.Meter, MetricProducer {
  final Resource _resource;
  final InstrumentationScope _instrumentationScope;
  final TimeProvider _timeProvider;

  final List<sdk.Counter> _counters = [];
  final List<sdk.UpDownCounter> _upDownCounters = [];
  final List<sdk.Histogram> _histograms = [];
  final List<sdk.Gauge> _gauges = [];

  @protected
  Meter(this._resource, this._instrumentationScope, this._timeProvider);

  @override
  api.Counter<T> createCounter<T extends num>(String name,
      {String? description, String? unit}) {
    final counter = sdk.Counter<T>(
      name: name,
      description: description,
      unit: unit,
      timeProvider: _timeProvider,
    );
    _counters.add(counter);
    return counter;
  }

  @override
  api.UpDownCounter<T> createUpDownCounter<T extends num>(String name,
      {String? description, String? unit}) {
    final upDownCounter = sdk.UpDownCounter<T>(
      name: name,
      description: description,
      unit: unit,
      timeProvider: _timeProvider,
    );
    _upDownCounters.add(upDownCounter);
    return upDownCounter;
  }

  @override
  api.Histogram<T> createHistogram<T extends num>(String name,
      {String? description, String? unit}) {
    final histogram = sdk.Histogram<T>(
      name: name,
      description: description,
      unit: unit,
      timeProvider: _timeProvider,
    );
    _histograms.add(histogram);
    return histogram;
  }

  @override
  api.Gauge<T> createGauge<T extends num>(String name,
      {String? description, String? unit}) {
    final gauge = sdk.Gauge<T>(
      name: name,
      description: description,
      unit: unit,
      timeProvider: _timeProvider,
    );
    _gauges.add(gauge);
    return gauge;
  }

  @override
  List<MetricData> produce(Int64 startTime, Int64 endTime) {
    final metrics = <MetricData>[];

    for (final counter in _counters) {
      final points = counter.aggregator.collect(startTime, endTime);
      if (points.isNotEmpty) {
        metrics.add(MetricData(
          resource: _resource,
          instrumentationScope: _instrumentationScope,
          name: counter.name,
          description: counter.description ?? '',
          unit: counter.unit ?? '',
          aggregationType: AggregationType.sum,
          points: points,
        ));
      }
    }

    for (final upDownCounter in _upDownCounters) {
      final points = upDownCounter.aggregator.collect(startTime, endTime);
      if (points.isNotEmpty) {
        metrics.add(MetricData(
          resource: _resource,
          instrumentationScope: _instrumentationScope,
          name: upDownCounter.name,
          description: upDownCounter.description ?? '',
          unit: upDownCounter.unit ?? '',
          aggregationType: AggregationType.sum,
          points: points,
        ));
      }
    }

    for (final histogram in _histograms) {
      final points = histogram.aggregator.collect(startTime, endTime);
      if (points.isNotEmpty) {
        metrics.add(MetricData(
          resource: _resource,
          instrumentationScope: _instrumentationScope,
          name: histogram.name,
          description: histogram.description ?? '',
          unit: histogram.unit ?? '',
          aggregationType: AggregationType.histogram,
          points: points,
        ));
      }
    }

    for (final gauge in _gauges) {
      final points = gauge.aggregator.collect(startTime, endTime);
      if (points.isNotEmpty) {
        metrics.add(MetricData(
          resource: _resource,
          instrumentationScope: _instrumentationScope,
          name: gauge.name,
          description: gauge.description ?? '',
          unit: gauge.unit ?? '',
          aggregationType: AggregationType.lastValue,
          points: points,
        ));
      }
    }

    return metrics;
  }
}
