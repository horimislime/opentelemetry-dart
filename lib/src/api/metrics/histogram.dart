// Copyright 2021-2022 Workiva.
// Licensed under the Apache License, Version 2.0. Please see https://github.com/Workiva/opentelemetry-dart/blob/master/LICENSE for more information

import 'package:opentelemetry/api.dart';

/// A Histogram instrument that records distributions of values.
///
/// Histogram is used to record measurements that are expected to be
/// aggregated into a distribution, such as request durations or response sizes.
abstract class Histogram<T extends num> {
  /// Records a value.
  ///
  /// [value] The measurement value to record.
  /// [attributes] A set of attributes to associate with the value.
  /// [context] The explicit context to associate with this measurement.
  void record(T value, {List<Attribute> attributes, Context context});
}
