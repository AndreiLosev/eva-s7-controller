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

void main(List<String> arguments) async {
  int exitCode = 1;
  final s7client = AsyncClient();
  late final Map<String, ActionItem> actionMap;

  try {
    final info = ServiceInfo(author, version, description)
      ..addMethod(TagGet.createMethod(s7client))
      ..addMethod(TagSet.createMethod(s7client))
      ..addMethod(SvcAction.createMethod(s7client, (oid) => actionMap[oid]))
      ..addMethod(Terminate.createMethod())
      ..addMethod(Kill.createMethod());

    await svc().load();
    await svc().init(info);

    final config = Config(svc().config.config);
    actionMap = config.actionMap;

    PullHandler? pullHandler;

    try {
      await s7client.init();
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
  } finally {
    await s7client.destroy();
  }

  exit(exitCode);
}
