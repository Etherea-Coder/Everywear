import 'package:flutter/services.dart';

Future<bool> requestOwnerSessionCheckpoint(
  MethodChannel channel, {
  required String checkpoint,
}) async {
  return await channel.invokeMethod<bool>('confirmOwnerSessionCheckpoint', {
        'checkpoint': checkpoint,
      }) ==
      true;
}
