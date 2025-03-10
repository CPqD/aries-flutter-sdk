import 'package:did_agent/agent/enums/aries_method.dart';
import 'package:flutter/services.dart';

const channelWallet = MethodChannel("br.gov.serprocpqd/wallet");

class AriesResult<T> {
  final bool success;
  final String error;
  final T? value;

  AriesResult({required this.success, this.error = "", this.value});

  factory AriesResult.fromDynamic(dynamic value) {
    if (value != null && value is Map) {
      final mapValue = Map<String, dynamic>.from(value);

      return AriesResult(
        error: mapValue["error"],
        value: mapValue["result"],
        success: mapValue["error"].isEmpty,
      );
    }

    return AriesResult(error: "Aries Error", value: null, success: false);
  }

  static Future<AriesResult> invoke(AriesMethod method, [dynamic arguments]) async {
    print("\ninvoke ${method.value}");

    try {
      final result = await channelWallet.invokeMethod(method.value, arguments);

      return AriesResult.fromDynamic(result);
    } on PlatformException catch (e) {
      print("Failed to Invoke ${method.value}: '${e.message}'.");

      return AriesResult(error: e.message ?? '', success: false);
    }
  }

  @override
  String toString() {
    return 'AriesResult{success: $success, error: $error, result: $value}';
  }
}
