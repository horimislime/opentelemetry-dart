// Copyright 2021-2022 Workiva.
// Licensed under the Apache License, Version 2.0. Please see https://github.com/Workiva/opentelemetry-dart/blob/master/LICENSE for more information

/// Example demonstrating the usage of OpenTelemetry Metrics API with Collector.
library;

import 'package:opentelemetry/src/api/common/attribute.dart';
import 'package:opentelemetry/src/experimental_sdk.dart' as exp_sdk;

void main() async {
  // Example 1: Using Console Exporter (for development/debugging)
  await runWithConsoleExporter();

  // Example 2: Using Collector Exporter (for production - sends to OpenTelemetry Collector)
  // await runWithCollectorExporter();
}

/// Example using ConsoleMetricExporter for local debugging
Future<void> runWithConsoleExporter() async {
  print('=== Console Exporter Example ===');

  final exporter = exp_sdk.ConsoleMetricExporter();
  final reader = exp_sdk.PeriodicExportingMetricReader(
    exporter: exporter,
    exportInterval: const Duration(seconds: 5),
    timeProvider: exp_sdk.DateTimeTimeProvider(),
  );

  final meterProvider = exp_sdk.MeterProvider(
    resource: exp_sdk.Resource([
      Attribute.fromString('service.name', 'my-service'),
      Attribute.fromString('service.version', '1.0.0'),
    ]),
    readers: [reader],
  );

  await _recordMetrics(meterProvider);

  meterProvider.forceFlush();
  meterProvider.shutdown();
}

/// Example using CollectorExporter to send metrics to OpenTelemetry Collector
Future<void> runWithCollectorExporter() async {
  print('=== Collector Exporter Example ===');

  // Configure the Collector endpoint
  // Default OTLP/HTTP endpoint for metrics: http://localhost:4318/v1/metrics
  final exporter = exp_sdk.CollectorExporter(
    Uri.parse('http://localhost:4318/v1/metrics'),
    headers: {
      // Add authentication headers if needed
      // 'Authorization': 'Bearer your-token',
    },
    timeoutMilliseconds: 10000,
  );

  final reader = exp_sdk.PeriodicExportingMetricReader(
    exporter: exporter,
    exportInterval: const Duration(seconds: 10),
    timeProvider: exp_sdk.DateTimeTimeProvider(),
  );

  final meterProvider = exp_sdk.MeterProvider(
    resource: exp_sdk.Resource([
      Attribute.fromString('service.name', 'my-service'),
      Attribute.fromString('service.version', '1.0.0'),
      Attribute.fromString('deployment.environment', 'production'),
    ]),
    readers: [reader],
  );

  await _recordMetrics(meterProvider);

  meterProvider.forceFlush();
  meterProvider.shutdown();
}

/// Record sample metrics for demonstration
Future<void> _recordMetrics(exp_sdk.MeterProvider meterProvider) async {
  final meter = meterProvider.get(
    'example-meter',
    version: '1.0.0',
    schemaUrl: 'https://opentelemetry.io/schemas/1.0.0',
  );

  // Create instruments
  final requestCounter = meter.createCounter<int>(
    'http.requests',
    description: 'Number of HTTP requests',
    unit: '1',
  );

  final activeRequests = meter.createUpDownCounter<int>(
    'http.active_requests',
    description: 'Number of active HTTP requests',
    unit: '1',
  );

  final requestDuration = meter.createHistogram<double>(
    'http.request.duration',
    description: 'HTTP request duration',
    unit: 'ms',
  );

  final cpuUsage = meter.createGauge<double>(
    'system.cpu.usage',
    description: 'Current CPU usage',
    unit: '%',
  );

  // Simulate recording metrics
  print('Recording metrics...');

  // Record counter values with attributes
  requestCounter.add(1, attributes: [
    Attribute.fromString('http.method', 'GET'),
    Attribute.fromString('http.route', '/api/users'),
  ]);
  requestCounter.add(1, attributes: [
    Attribute.fromString('http.method', 'POST'),
    Attribute.fromString('http.route', '/api/users'),
  ]);
  requestCounter.add(3, attributes: [
    Attribute.fromString('http.method', 'GET'),
    Attribute.fromString('http.route', '/api/users'),
  ]);

  // Record up/down counter values
  activeRequests.add(5);
  activeRequests.add(-2);
  activeRequests.add(3);

  // Record histogram values
  requestDuration.record(25.5, attributes: [
    Attribute.fromString('http.method', 'GET'),
  ]);
  requestDuration.record(150.3, attributes: [
    Attribute.fromString('http.method', 'POST'),
  ]);
  requestDuration.record(42.1, attributes: [
    Attribute.fromString('http.method', 'GET'),
  ]);

  // Record gauge values
  cpuUsage.record(45.5);
  cpuUsage.record(52.3);
  cpuUsage.record(48.7);

  print('Metrics recorded!');
}
