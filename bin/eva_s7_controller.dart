import 'dart:io';

import 'package:dart_snap7/dart_snap7.dart';
import 'package:eva_s7_controller/config/action_item.dart';
import 'package:eva_s7_controller/config/config.dart';
import 'package:eva_s7_controller/eapi/kill.dart';
import 'package:eva_s7_controller/eapi/svc_action.dart';
import 'package:eva_s7_controller/eapi/tag_get.dart';
import 'package:eva_s7_controller/eapi/tag_set.dart';
import 'package:eva_s7_controller/eapi/terminate.dart';
import 'package:eva_s7_controller/pull_handler.dart';
import 'package:eva_sdk/eva_sdk.dart';

const author = "Losev Andrei";
const version = "0.1.0";
const description = "S7 legacy client";

int exitCode = 1;

void main(List<String> arguments) async {
  final s7client = AsyncClient();
  late final Map<String, ActionItem> actionMap;

  try {
    final info = ServiceInfo(author, version, description)
      ..addMethod(TagGet.createMethod(s7client))
      ..addMethod(TagSet.createMethod(s7client))
      ..addMethod(SvcAction.createMethod(s7client, (oid) => actionMap[oid]))
      ..addMethod(Terminate.createMethod())
      ..addMethod(Kill.createMethod());

    if (arguments.contains('--local')) {
      await svc().debugLoad(
        '/home/andrei/documents/my/eva-s7-controller/bin/config.yaml',
        'softkip.s7controller.s1',
      );
    } else {
      await svc().load();
    }
    await svc().init(info);

    final config = Config(svc().config.config);
    actionMap = config.actionMap;

    PullHandler? pullHandler;

    try {
      final path = await File('/opt/eva4/lib/libsnap7.so').exists()
          ? '/opt/eva4/lib/libsnap7.so'
          : null;
      await s7client.init(path);
      await s7client.setConnectionType(config.connectionType);
      await s7client.connect(config.ip, config.rack, config.slot, config.port);

      pullHandler = PullHandler(s7client, config);
      pullHandler.run();
    } catch (e) {
      if (svc().config.reactToFail) {
        await pullHandler?.setErrorStatus();
      }
      rethrow;
    }

    await svc().block();
    pullHandler.stop();
    await s7client.disconnect();
    exitCode = 0;
  } catch (e, s) {
    print({"err": e, "trace": s});
  } finally {
    await s7client.destroy();
    exit(exitCode);
  }
}
