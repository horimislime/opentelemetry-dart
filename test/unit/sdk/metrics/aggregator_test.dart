// Copyright 2021-2022 Workiva.
// Licensed under the Apache License, Version 2.0. Please see https://github.com/Workiva/opentelemetry-dart/blob/master/LICENSE for more information

@TestOn('vm')
import 'package:fixnum/fixnum.dart';
import 'package:opentelemetry/src/api/common/attribute.dart';
import 'package:opentelemetry/src/sdk/metrics/aggregation/aggregator.dart';
import 'package:test/test.dart';

void main() {
  group('SumAggregator', () {
    test('records and collects values correctly', () {
      final aggregator = SumAggregator(isMonotonic: true);
      final now = Int64(DateTime.now().millisecondsSinceEpoch * 1000);

      aggregator.record(10, [], now);
      aggregator.record(5, [], now);
      aggregator.record(3, [], now);

      final points = aggregator.collect(Int64.ZERO, now);

      expect(points.length, 1);
      expect(points.first.value, 18);
      expect(points.first.isMonotonic, true);
    });

    test('groups values by attributes', () {
      final aggregator = SumAggregator(isMonotonic: true);
      final now = Int64(DateTime.now().millisecondsSinceEpoch * 1000);

      aggregator.record(10, [Attribute.fromString('method', 'GET')], now);
      aggregator.record(5, [Attribute.fromString('method', 'POST')], now);
      aggregator.record(3, [Attribute.fromString('method', 'GET')], now);

      final points = aggregator.collect(Int64.ZERO, now);

      expect(points.length, 2);

      final getPoint = points.firstWhere((p) =>
          p.attributes.any((a) => a.key == 'method' && a.value == 'GET'));
      final postPoint = points.firstWhere((p) =>
          p.attributes.any((a) => a.key == 'method' && a.value == 'POST'));

      expect(getPoint.value, 13);
      expect(postPoint.value, 5);
    });
  });

  group('LastValueAggregator', () {
    test('keeps only the last value', () {
      final aggregator = LastValueAggregator();
      final now = Int64(DateTime.now().millisecondsSinceEpoch * 1000);

      aggregator.record(10, [], now);
      aggregator.record(25, [], now + Int64(1000));
      aggregator.record(15, [], now + Int64(2000));

      final points = aggregator.collect(Int64.ZERO, now + Int64(2000));

      expect(points.length, 1);
      expect(points.first.value, 15);
    });
  });

  group('HistogramAggregator', () {
    test('records values in buckets', () {
      final aggregator =
          HistogramAggregator(boundaries: [10, 50, 100, 500, 1000]);
      final now = Int64(DateTime.now().millisecondsSinceEpoch * 1000);

      aggregator.record(5, [], now);
      aggregator.record(25, [], now);
      aggregator.record(75, [], now);
      aggregator.record(200, [], now);
      aggregator.record(1500, [], now);

      final points = aggregator.collect(Int64.ZERO, now);

      expect(points.length, 1);
      expect(points.first.count, 5);
      expect(points.first.sum, 5 + 25 + 75 + 200 + 1500);
      expect(points.first.min, 5);
      expect(points.first.max, 1500);
      expect(points.first.bucketCounts, [1, 1, 1, 1, 0, 1]); // 6 buckets
    });
  });
}
