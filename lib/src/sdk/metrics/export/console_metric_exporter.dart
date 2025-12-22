// Copyright 2021-2022 Workiva.
// Licensed under the Apache License, Version 2.0. Please see https://github.com/Workiva/opentelemetry-dart/blob/master/LICENSE for more information

import 'package:opentelemetry/src/sdk/metrics/data/metric_data.dart';
import 'package:opentelemetry/src/sdk/metrics/export/metric_exporter.dart';

/// A MetricExporter that prints metrics to the console.
class ConsoleMetricExporter implements MetricExporter {
  bool _isShutdown = false;

  @override
  void export(List<MetricData> metrics) {
    if (_isShutdown) {
      return;
    }

    for (final metric in metrics) {
      final resourceAttrs = metric.resource.attributes;
      final resourceStr =
          resourceAttrs.keys.map((k) => '$k=${resourceAttrs.get(k)}').join(',');
      print({
        'resource': resourceStr,
        'scope': metric.instrumentationScope.name,
        'name': metric.name,
        'description': metric.description,
        'unit': metric.unit,
        'type': metric.aggregationType.name,
        'points': metric.points.map(_formatPoint).toList(),
      });
    }
  }

  Map<String, dynamic> _formatPoint(PointData point) {
    final base = {
      'startTime': point.startTime.toString(),
      'endTime': point.endTime.toString(),
      'attributes':
          point.attributes.map((a) => '${a.key}=${a.value}').join(','),
    };

    if (point is SumPointData) {
      return {
        ...base,
        'value': point.value,
        'isMonotonic': point.isMonotonic,
      };
    } else if (point is GaugePointData) {
      return {
        ...base,
        'value': point.value,
      };
    } else if (point is HistogramPointData) {
      return {
        ...base,
        'count': point.count,
        'sum': point.sum,
        'min': point.min,
        'max': point.max,
        'boundaries': point.boundaries,
        'bucketCounts': point.bucketCounts,
      };
    }

    return base;
  }

  @override
  void shutdown() {
    _isShutdown = true;
  }
}
