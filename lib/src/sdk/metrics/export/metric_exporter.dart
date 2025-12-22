// Copyright 2021-2022 Workiva.
// Licensed under the Apache License, Version 2.0. Please see https://github.com/Workiva/opentelemetry-dart/blob/master/LICENSE for more information

import 'package:opentelemetry/src/sdk/metrics/data/metric_data.dart';

/// Interface for exporting metrics.
///
/// MetricExporter is analogous to SpanExporter for traces.
abstract class MetricExporter {
  /// Exports a batch of metrics.
  ///
  /// [metrics] The list of [MetricData] to export.
  void export(List<MetricData> metrics);

  /// Shuts down the exporter.
  void shutdown();
}
