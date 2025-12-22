// Copyright 2021-2022 Workiva.
// Licensed under the Apache License, Version 2.0. Please see https://github.com/Workiva/opentelemetry-dart/blob/master/LICENSE for more information

import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:opentelemetry/src/sdk/metrics/data/metric_data.dart';
import 'package:opentelemetry/src/sdk/metrics/export/metric_exporter.dart';
import 'package:opentelemetry/src/sdk/time_providers/time_provider.dart';

/// Interface for reading metrics from a MeterProvider.
///
/// MetricReader is analogous to SpanProcessor for traces.
abstract class MetricReader {
  /// Collects and optionally exports metrics.
  void collect();

  /// Forces a flush of any buffered data.
  void forceFlush();

  /// Shuts down the reader.
  void shutdown();
}

/// A MetricReader that periodically collects and exports metrics.
class PeriodicExportingMetricReader implements MetricReader {
  final MetricExporter _exporter;
  final Duration _exportInterval;
  final TimeProvider _timeProvider;
  final List<MetricProducer> _producers = [];

  Timer? _timer;
  bool _isShutdown = false;
  Int64 _lastCollectTime = Int64.ZERO;

  PeriodicExportingMetricReader({
    required MetricExporter exporter,
    Duration exportInterval = const Duration(seconds: 60),
    required TimeProvider timeProvider,
  })  : _exporter = exporter,
        _exportInterval = exportInterval,
        _timeProvider = timeProvider {
    _lastCollectTime = _timeProvider.now;
    _timer = Timer.periodic(_exportInterval, (_) => collect());
  }

  /// Registers a metric producer.
  void registerProducer(MetricProducer producer) {
    _producers.add(producer);
  }

  @override
  void collect() {
    if (_isShutdown) {
      return;
    }

    final now = _timeProvider.now;
    final metrics = <MetricData>[];

    for (final producer in _producers) {
      metrics.addAll(producer.produce(_lastCollectTime, now));
    }

    if (metrics.isNotEmpty) {
      _exporter.export(metrics);
    }

    _lastCollectTime = now;
  }

  @override
  void forceFlush() {
    collect();
  }

  @override
  void shutdown() {
    if (_isShutdown) {
      return;
    }

    forceFlush();
    _isShutdown = true;
    _timer?.cancel();
    _exporter.shutdown();
  }
}

/// Interface for producing metrics.
abstract class MetricProducer {
  /// Produces metrics for the given time range.
  List<MetricData> produce(Int64 startTime, Int64 endTime);
}
