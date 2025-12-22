// Copyright 2021-2022 Workiva.
// Licensed under the Apache License, Version 2.0. Please see https://github.com/Workiva/opentelemetry-dart/blob/master/LICENSE for more information

import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:quiver/core.dart';

import '../../api/common/attribute.dart';
import '../../experimental_api.dart' as api;
import '../../experimental_sdk.dart' as sdk;
import '../common/instrumentation_scope.dart';
import '../resource/resource.dart';
import '../time_providers/datetime_time_provider.dart';
import '../time_providers/time_provider.dart';
import 'export/metric_reader.dart';

class MeterProvider implements api.MeterProvider {
  final _logger = Logger('opentelemetry.sdk.metrics.meterprovider');

  @protected
  final Map<int, sdk.Meter> meters = {};

  @visibleForTesting
  final Resource resource;

  final TimeProvider _timeProvider;
  final List<MetricReader> _readers = [];

  MeterProvider({
    Resource? resource,
    TimeProvider? timeProvider,
    List<MetricReader>? readers,
  })  : resource = resource ?? Resource([]),
        _timeProvider = timeProvider ?? DateTimeTimeProvider() {
    if (readers != null) {
      for (final reader in readers) {
        addReader(reader);
      }
    }
  }

  /// Adds a [MetricReader] to this provider.
  void addReader(MetricReader reader) {
    _readers.add(reader);
    if (reader is PeriodicExportingMetricReader) {
      // Register all existing meters as producers
      for (final meter in meters.values) {
        reader.registerProducer(meter);
      }
    }
  }

  @override
  api.Meter get(String name,
      {String version = '',
      String schemaUrl = '',
      List<Attribute> attributes = const []}) {
    if (name.isEmpty) {
      _logger.warning('Invalid Meter Name', '', StackTrace.current);
    }

    final key = hash3(name, version, schemaUrl);
    var meter = meters[key];
    if (meter == null) {
      meter = sdk.Meter(
        resource,
        InstrumentationScope(name, version, schemaUrl, attributes),
        _timeProvider,
      );
      meters[key] = meter;

      // Register the new meter with all readers
      for (final reader in _readers) {
        if (reader is PeriodicExportingMetricReader) {
          reader.registerProducer(meter);
        }
      }
    }
    return meter;
  }

  /// Forces a flush of all metric readers.
  void forceFlush() {
    for (final reader in _readers) {
      reader.forceFlush();
    }
  }

  /// Shuts down all metric readers.
  void shutdown() {
    for (final reader in _readers) {
      reader.shutdown();
    }
  }
}
