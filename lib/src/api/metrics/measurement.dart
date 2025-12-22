// Copyright 2021-2022 Workiva.
// Licensed under the Apache License, Version 2.0. Please see https://github.com/Workiva/opentelemetry-dart/blob/master/LICENSE for more information

import 'package:opentelemetry/api.dart';

/// Represents a data point captured at a moment in time.
class Measurement<T extends num> {
  /// The value of this measurement.
  final T value;

  /// Attributes associated with this measurement.
  final List<Attribute> attributes;

  /// Creates a new [Measurement] with the given [value] and [attributes].
  const Measurement(this.value, {this.attributes = const []});
}
