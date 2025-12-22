// Copyright 2021-2022 Workiva.
// Licensed under the Apache License, Version 2.0. Please see https://github.com/Workiva/opentelemetry-dart/blob/master/LICENSE for more information

import 'package:opentelemetry/src/experimental_api.dart';

abstract class Meter {
  /// Creates a new [Counter] instrument named [name]. Additional details about
  /// this metric can be captured in [description] and units can be specified in
  /// [unit].
  ///
  /// See https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/metrics/api.md#instrument-naming-rule
  Counter<T> createCounter<T extends num>(String name,
      {String description, String unit});

  /// Creates a new [UpDownCounter] instrument named [name]. Additional details
  /// about this metric can be captured in [description] and units can be
  /// specified in [unit].
  ///
  /// UpDownCounter supports both positive and negative values.
  UpDownCounter<T> createUpDownCounter<T extends num>(String name,
      {String description, String unit});

  /// Creates a new [Histogram] instrument named [name]. Additional details
  /// about this metric can be captured in [description] and units can be
  /// specified in [unit].
  ///
  /// Histogram is used to record measurements that are expected to be
  /// aggregated into a distribution.
  Histogram<T> createHistogram<T extends num>(String name,
      {String description, String unit});

  /// Creates a new [Gauge] instrument named [name]. Additional details
  /// about this metric can be captured in [description] and units can be
  /// specified in [unit].
  ///
  /// Gauge is used to record non-additive values.
  Gauge<T> createGauge<T extends num>(String name,
      {String description, String unit});
}
