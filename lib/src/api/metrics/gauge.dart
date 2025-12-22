// Copyright 2021-2022 Workiva.
// Licensed under the Apache License, Version 2.0. Please see https://github.com/Workiva/opentelemetry-dart/blob/master/LICENSE for more information

import 'package:opentelemetry/api.dart';

/// A Gauge instrument that records non-additive values.
///
/// Gauge is used to record the current value of something, such as
/// temperature, CPU usage, or the current speed of a car. Unlike counters,
/// gauge values are not summed across different label sets.
abstract class Gauge<T extends num> {
  /// Records a value.
  ///
  /// [value] The measurement value to record.
  /// [attributes] A set of attributes to associate with the value.
  /// [context] The explicit context to associate with this measurement.
  void record(T value, {List<Attribute> attributes, Context context});
}
