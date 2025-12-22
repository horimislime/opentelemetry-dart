// Copyright 2021-2022 Workiva.
// Licensed under the Apache License, Version 2.0. Please see https://github.com/Workiva/opentelemetry-dart/blob/master/LICENSE for more information

import 'package:opentelemetry/api.dart';

/// An UpDownCounter instrument that records non-monotonic values.
///
/// UpDownCounter supports both positive and negative values, making it suitable
/// for tracking values that can increase or decrease, such as the number of
/// active requests or items in a queue.
abstract class UpDownCounter<T extends num> {
  /// Adds a value to the counter.
  ///
  /// [value] The increment/decrement amount. Can be positive or negative.
  /// [attributes] A set of attributes to associate with the value.
  /// [context] The explicit context to associate with this measurement.
  void add(T value, {List<Attribute> attributes, Context context});
}
