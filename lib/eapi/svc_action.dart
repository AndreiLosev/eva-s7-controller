import 'dart:async';
import 'dart:typed_data';

import 'package:dart_snap7/dart_snap7.dart';
import 'package:eva_s7_controller/config/action_item.dart';
import 'package:eva_s7_controller/config/utils.dart';
import 'package:eva_sdk/eva_sdk.dart';

class SvcAction {
  static const name = "action";
  static const description = "set valuer in plc";

  final AsyncClient _client;
  final ActionItem? Function(String) _getAction;

  SvcAction(this._client, this._getAction);

  Future<Null> call(Map<String, dynamic> params) async {
    svc().needReady();
    final uAction = Action(params);

    await svc().controller.eventPending(uAction);
    final item = _getAction(uAction.oid.asString());

    if (item == null) {
      await nullError(uAction);
      return;
    } else if (item.type == S7Type.bool && uAction.params!.value is! bool) {
      await boolError(uAction);
      return null;
    }


    final run = switch (item.type) {
      S7Type.bool => _writeBit(item, uAction),
      _ => _writeBytes(item, uAction),
    };

    await svc().controller.eventRunning(uAction);

    try {
      await run;
    } catch (e) {
      await anyError(uAction, e);
      return null;
    }
    await svc().controller.eventCompleted(uAction, uAction.oid.asString());

    await svc().rpc.bus.publish(
          EapiTopic.rawStateTopic.resolve(uAction.oid.asPath()),
          serialize({'status': 1, 'value': uAction.params!.value}),
        );

    return null;
  }

  Future<void> nullError(Action uAction) async {
    await svc().controller.eventFailed(
          uAction,
          out: "unit action",
          err: "undefined oid: ${uAction.oid.asString()}",
          exitcode: EvaErrorKind.invalidParams.code(),
        );
  }

  Future<void> boolError(Action uAction) async {
    final val = uAction.params!.value;
    final oidS = uAction.oid.asString();
    await svc().controller.eventFailed(
          uAction,
          out: "unit action",
          err: "undefined value for $oidS expected bool, give $val",
          exitcode: EvaErrorKind.invalidParams.code(),
        );
  }

  Future<void> anyError(Action uAction, Object e) async {
    await svc().controller.eventFailed(
          uAction,
          out: 'unit action',
          err: e,
          exitcode: EvaErrorKind.io.code(),
        );
  }

  Uint8List _value(ActionItem item, Action uAction) {
    return Uint8List.view(item.type
        .setValue(ByteData(item.type.dataLen()), item.offset.$1,
            uAction.params!.value)
        .buffer);
  }

  Future<void> _writeBit(ActionItem item, Action uAction) =>
      switch (item.area) {
        S7Area.dataBlock => _client.writeDataBlockBit(item.dbNum,
            item.offset.$1, item.offset.$2!, uAction.params!.value as bool),
        S7Area.merkers => _client.writeMerkersBit(
            item.offset.$1, item.offset.$2!, uAction.params!.value as bool),
        S7Area.outputs => _client.writeOutputsBit(
            item.offset.$1, item.offset.$2!, uAction.params!.value as bool),
        _ => throw EvaError(
            EvaErrorKind.invalidParams, "set inputs bit not implemented"),
      };

  Future<void> _writeBytes(ActionItem item, Action uAction) =>
      switch (item.area) {
        S7Area.dataBlock => _client.writeDataBlock(
            item.dbNum, item.offset.$1, _value(item, uAction)),
        S7Area.merkers =>
          _client.writeMerkers(item.offset.$1, _value(item, uAction)),
        S7Area.inputs =>
          _client.writeInputs(item.offset.$1, _value(item, uAction)),
        S7Area.outputs =>
          _client.writeOutputs(item.offset.$1, _value(item, uAction)),
      };

  static ServiceMethod createMethod(
      AsyncClient s7client, ActionItem? Function(String) getAction) {
    return ServiceMethod(name, SvcAction(s7client, getAction).call, description)
      ..required('uuid', 'List<u8>')
      ..required('i', 'String')
      ..required('timeout', 'u64')
      ..required("priority", 'u8')
      ..required("params", "dict")
      ..optional('config', "dict");
  }
}
