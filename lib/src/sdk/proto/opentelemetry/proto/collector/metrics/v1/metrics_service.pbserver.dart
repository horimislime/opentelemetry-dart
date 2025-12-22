// This is a generated file - do not edit.
//
// Generated from opentelemetry/proto/collector/metrics/v1/metrics_service.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'metrics_service.pb.dart' as $3;
import 'metrics_service.pbjson.dart';

export 'metrics_service.pb.dart';

abstract class MetricsServiceBase extends $pb.GeneratedService {
  $async.Future<$3.ExportMetricsServiceResponse> export(
      $pb.ServerContext ctx, $3.ExportMetricsServiceRequest request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'Export':
        return $3.ExportMetricsServiceRequest();
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx,
      $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'Export':
        return export(ctx, request as $3.ExportMetricsServiceRequest);
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => MetricsServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
      get $messageJson => MetricsServiceBase$messageJson;
}
