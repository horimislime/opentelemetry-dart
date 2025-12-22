// Copyright 2021-2022 Workiva.
// Licensed under the Apache License, Version 2.0. Please see https://github.com/Workiva/opentelemetry-dart/blob/master/LICENSE for more information

import 'dart:async';
import 'dart:math';

import 'package:fixnum/fixnum.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import '../../proto/opentelemetry/proto/collector/metrics/v1/metrics_service.pb.dart'
    as pb_metrics_service;
import '../../proto/opentelemetry/proto/common/v1/common.pb.dart' as pb_common;
import '../../proto/opentelemetry/proto/metrics/v1/metrics.pb.dart'
    as pb_metrics;
import '../../proto/opentelemetry/proto/resource/v1/resource.pb.dart'
    as pb_resource;
import '../../resource/resource.dart';
import '../data/metric_data.dart';
import 'metric_exporter.dart';

/// A MetricExporter that sends metrics to an OpenTelemetry Collector via OTLP/HTTP.
class CollectorExporter implements MetricExporter {
  final Logger _log = Logger('opentelemetry.MetricCollectorExporter');

  final Uri uri;
  final http.Client client;
  final Map<String, String> headers;

  /// Timeout duration for the request in milliseconds.
  /// Default is 10000ms.
  /// Set to 0 or a negative value to disable timeout.
  final int timeoutMilliseconds;
  var _isShutdown = false;

  CollectorExporter(
    this.uri, {
    http.Client? httpClient,
    this.headers = const {},
    this.timeoutMilliseconds = 10000,
  }) : client = httpClient ?? http.Client();

  @override
  void export(List<MetricData> metrics) {
    if (_isShutdown) {
      return;
    }

    if (metrics.isEmpty) {
      return;
    }

    unawaited(_send(uri, metrics));
  }

  Future<void> _send(
    Uri uri,
    List<MetricData> metrics,
  ) async {
    _log.info('Exporting ${metrics.length} metrics to $uri');

    const maxRetries = 3;
    var retries = 0;
    // Retryable status from the spec: https://opentelemetry.io/docs/specs/otlp/#failures-1
    const validRetryCodes = [429, 502, 503, 504];

    final body = pb_metrics_service.ExportMetricsServiceRequest(
        resourceMetrics: _metricsToProtobuf(metrics));
    final requestHeaders = {'Content-Type': 'application/x-protobuf'}
      ..addAll(headers);

    while (retries < maxRetries) {
      try {
        final request = client.post(uri,
            body: body.writeToBuffer(), headers: requestHeaders);
        final response = timeoutMilliseconds > 0
            ? await request.timeout(Duration(milliseconds: timeoutMilliseconds))
            : await request;

        _log.info('Response status: ${response.statusCode}');

        if (response.statusCode == 200) {
          return;
        }
        // If the response is not 200, log a warning
        _log.warning('Failed to export ${metrics.length} metrics. '
            'HTTP status code: ${response.statusCode}');
        // If the response is not a valid retry code, do not retry
        if (!validRetryCodes.contains(response.statusCode)) {
          return;
        }
      } catch (e) {
        _log.warning('Failed to export ${metrics.length} metrics. $e');
        return;
      }
      // Exponential backoff with jitter
      final delay =
          _calculateJitteredDelay(retries++, const Duration(milliseconds: 100));
      await Future.delayed(delay);
    }
    _log.severe(
        'Failed to export ${metrics.length} metrics after $maxRetries retries');
  }

  Duration _calculateJitteredDelay(int retries, Duration baseDelay) {
    final delay = baseDelay.inMilliseconds * pow(2, retries);
    final jitter = Random().nextDouble() * delay;
    return Duration(milliseconds: (delay + jitter).toInt());
  }

  /// Group and construct the protobuf equivalent of the given list of [MetricData].
  /// Metrics are grouped by resource and instrumentation scope.
  Iterable<pb_metrics.ResourceMetrics> _metricsToProtobuf(
      List<MetricData> metrics) {
    // Group metrics by resource
    final resourceMap = <String, List<MetricData>>{};
    for (final metric in metrics) {
      final resourceKey = _resourceKey(metric.resource);
      resourceMap.putIfAbsent(resourceKey, () => []).add(metric);
    }

    final resourceMetricsList = <pb_metrics.ResourceMetrics>[];

    for (final entry in resourceMap.entries) {
      final metricsForResource = entry.value;
      if (metricsForResource.isEmpty) continue;

      // Build resource attributes
      final resource = metricsForResource.first.resource;
      final resourceAttrs = <pb_common.KeyValue>[];
      for (final key in resource.attributes.keys) {
        resourceAttrs.add(pb_common.KeyValue(
            key: key,
            value: _attributeValueToProtobuf(resource.attributes.get(key)!)));
      }

      // Group by instrumentation scope
      final scopeMap = <String, List<MetricData>>{};
      for (final metric in metricsForResource) {
        final scopeKey =
            '${metric.instrumentationScope.name}:${metric.instrumentationScope.version}';
        scopeMap.putIfAbsent(scopeKey, () => []).add(metric);
      }

      final scopeMetricsList = <pb_metrics.ScopeMetrics>[];
      for (final scopeEntry in scopeMap.entries) {
        final metricsForScope = scopeEntry.value;
        if (metricsForScope.isEmpty) continue;

        final scope = metricsForScope.first.instrumentationScope;
        final pbMetrics = metricsForScope.map(_metricToProtobuf).toList();

        scopeMetricsList.add(pb_metrics.ScopeMetrics(
          scope: pb_common.InstrumentationScope(
            name: scope.name,
            version: scope.version,
          ),
          metrics: pbMetrics,
          schemaUrl: scope.schemaUrl,
        ));
      }

      resourceMetricsList.add(pb_metrics.ResourceMetrics(
        resource: pb_resource.Resource(attributes: resourceAttrs),
        scopeMetrics: scopeMetricsList,
      ));
    }

    return resourceMetricsList;
  }

  String _resourceKey(Resource resource) {
    final attrs = resource.attributes;
    final sortedKeys = attrs.keys.toList()..sort();
    return sortedKeys.map((k) => '$k=${attrs.get(k)}').join(',');
  }

  pb_metrics.Metric _metricToProtobuf(MetricData metric) {
    final pbMetric = pb_metrics.Metric(
      name: metric.name,
      description: metric.description,
      unit: metric.unit,
    );

    switch (metric.aggregationType) {
      case AggregationType.sum:
        final dataPoints = <pb_metrics.NumberDataPoint>[];
        for (final point in metric.points) {
          if (point is SumPointData) {
            dataPoints.add(_sumPointToProtobuf(point));
          }
        }
        final isMonotonic = metric.points.isNotEmpty &&
            metric.points.first is SumPointData &&
            (metric.points.first as SumPointData).isMonotonic;
        pbMetric.sum = pb_metrics.Sum(
          dataPoints: dataPoints,
          aggregationTemporality: pb_metrics
              .AggregationTemporality.AGGREGATION_TEMPORALITY_CUMULATIVE,
          isMonotonic: isMonotonic,
        );
        break;

      case AggregationType.lastValue:
        final dataPoints = <pb_metrics.NumberDataPoint>[];
        for (final point in metric.points) {
          if (point is GaugePointData) {
            dataPoints.add(_gaugePointToProtobuf(point));
          }
        }
        pbMetric.gauge = pb_metrics.Gauge(dataPoints: dataPoints);
        break;

      case AggregationType.histogram:
        final dataPoints = <pb_metrics.HistogramDataPoint>[];
        for (final point in metric.points) {
          if (point is HistogramPointData) {
            dataPoints.add(_histogramPointToProtobuf(point));
          }
        }
        pbMetric.histogram = pb_metrics.Histogram(
          dataPoints: dataPoints,
          aggregationTemporality: pb_metrics
              .AggregationTemporality.AGGREGATION_TEMPORALITY_CUMULATIVE,
        );
        break;
    }

    return pbMetric;
  }

  pb_metrics.NumberDataPoint _sumPointToProtobuf(SumPointData point) {
    final attrs = point.attributes
        .map((a) => pb_common.KeyValue(
            key: a.key, value: _attributeValueToProtobuf(a.value)))
        .toList();

    final dataPoint = pb_metrics.NumberDataPoint(
      startTimeUnixNano: point.startTime,
      timeUnixNano: point.endTime,
      attributes: attrs,
    );

    // Set value based on type
    if (point.value is int) {
      dataPoint.asInt = Int64(point.value as int);
    } else {
      dataPoint.asDouble = point.value.toDouble();
    }

    return dataPoint;
  }

  pb_metrics.NumberDataPoint _gaugePointToProtobuf(GaugePointData point) {
    final attrs = point.attributes
        .map((a) => pb_common.KeyValue(
            key: a.key, value: _attributeValueToProtobuf(a.value)))
        .toList();

    final dataPoint = pb_metrics.NumberDataPoint(
      startTimeUnixNano: point.startTime,
      timeUnixNano: point.endTime,
      attributes: attrs,
    );

    // Set value based on type
    if (point.value is int) {
      dataPoint.asInt = Int64(point.value as int);
    } else {
      dataPoint.asDouble = point.value.toDouble();
    }

    return dataPoint;
  }

  pb_metrics.HistogramDataPoint _histogramPointToProtobuf(
      HistogramPointData point) {
    final attrs = point.attributes
        .map((a) => pb_common.KeyValue(
            key: a.key, value: _attributeValueToProtobuf(a.value)))
        .toList();

    return pb_metrics.HistogramDataPoint(
      startTimeUnixNano: point.startTime,
      timeUnixNano: point.endTime,
      attributes: attrs,
      count: Int64(point.count),
      sum: point.sum.toDouble(),
      min: point.min?.toDouble(),
      max: point.max?.toDouble(),
      explicitBounds: point.boundaries,
      bucketCounts: point.bucketCounts.map((c) => Int64(c)).toList(),
    );
  }

  pb_common.AnyValue _attributeValueToProtobuf(Object value) {
    switch (value.runtimeType) {
      case String:
        return pb_common.AnyValue(stringValue: value as String);
      case bool:
        return pb_common.AnyValue(boolValue: value as bool);
      case double:
        return pb_common.AnyValue(doubleValue: value as double);
      case int:
        return pb_common.AnyValue(intValue: Int64(value as int));
      case List:
        final list = value as List;
        if (list.isNotEmpty) {
          switch (list[0].runtimeType) {
            case String:
              final values = <pb_common.AnyValue>[];
              for (final str in list) {
                values.add(pb_common.AnyValue(stringValue: str));
              }
              return pb_common.AnyValue(
                  arrayValue: pb_common.ArrayValue(values: values));
            case bool:
              final values = <pb_common.AnyValue>[];
              for (final b in list) {
                values.add(pb_common.AnyValue(boolValue: b));
              }
              return pb_common.AnyValue(
                  arrayValue: pb_common.ArrayValue(values: values));
            case double:
              final values = <pb_common.AnyValue>[];
              for (final d in list) {
                values.add(pb_common.AnyValue(doubleValue: d));
              }
              return pb_common.AnyValue(
                  arrayValue: pb_common.ArrayValue(values: values));
            case int:
              final values = <pb_common.AnyValue>[];
              for (final i in list) {
                values.add(pb_common.AnyValue(intValue: i));
              }
              return pb_common.AnyValue(
                  arrayValue: pb_common.ArrayValue(values: values));
          }
        }
    }
    return pb_common.AnyValue();
  }

  @override
  void shutdown() {
    _isShutdown = true;
    client.close();
  }
}
