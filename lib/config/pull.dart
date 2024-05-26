import 'dart:async';

import 'package:eva_s7_controller/config/utils.dart';
import 'package:eva_sdk/eva_sdk.dart';

class Pull {
  late final S7Area area;
  late final int dbNum;
  late final int start;
  late final int size;
  final map = <PullItem>[];

  Pull(Map<dynamic, dynamic> config) {
    final val = parsArea(config['area']);
    area = val.$1;
    dbNum = val.$2;
    if (config['map'] == null) {
      return;
    }
    for (var item in config['map']) {
      map.add(PullItem(item));
    }

    _setStartAndSize();
  }

  void _setStartAndSize() {
    int minAddr = map.first.offset.$1;
    int maxAddr = map.first.offset.$1;
    int maxAddrsize = map.first.type.dataLen();

    for (var item in map) {
      if (item.offset.$1 < minAddr) {
        minAddr = item.offset.$1;
      }

      if (item.offset.$1 > maxAddr) {
        maxAddr = item.offset.$1;
        maxAddrsize = item.type.dataLen();
      }
    }

    start = minAddr;
    size = maxAddr - minAddr + maxAddrsize;
  }
}

class PullItem {
  final (int, int?) offset;
  final Oid oid;
  final S7Type type;
  List<Function>? transform;
  double? delta;
  dynamic _oldValue;
  final _timer = Stopwatch();

  PullItem(Map<dynamic, dynamic> config)
      : offset = parseOffset(config),
        oid = Oid(config['oid']),
        type = S7Type.fromString(config['type']) {
    if (config['transform'] != null) {
      transform = [];
      for (var item in config['transform']) {
        transform!.add(_transforCallbeck(item));
      }
    }

    if (type.isFloat()) {
      delta = config['value_delta'] ?? 0.1;
    }
  }

  bool isChanget(dynamic value) {
    if (_oldValue == null) {
      return true;
    }
    return switch (type.isFloat()) {
      true => ((_oldValue - value) as double).abs() > delta!,
      false => _oldValue != value,
    };
  }

  Future<void> publish(dynamic value) async {
    _oldValue = value;
    await svc().rpc.bus.publish(
          EapiTopic.rawStateTopic.resolve(oid.asPath()),
          serialize({'value': value, 'status': 1}),
        );
  }

  Future<void> piblishErrorStatus() async {
    await svc().rpc.bus.publish(
          EapiTopic.rawStateTopic.resolve(oid.asPath()),
          serialize({'status': -1}),
        );
  }

  bool timerIsExpired(Duration pullCache) {
    return _timer.elapsed >= pullCache;
  }

  void startTimer() => _timer.start();

  void stopAndResetTimer() {
    _timer.stop();
    _timer.reset();
  }
}

Function _transforCallbeck(Map<dynamic, dynamic> transform) {
  final func = transform['func'];
  final List params = transform['params'];
  switch (func) {
    case 'invert':
      return (bool v) => !v;
    case 'add':
      if (params[0] is! num) {
        throw Exception("invalid transform params $transform");
      }
      return (num v) => v + params[0];
    case 'subtract':
      if (params[0] is! num) {
        throw Exception("invalid transform params $transform");
      }
      return (num v) => v - params[0];
    case 'multiply':
      if (params[0] is! num) {
        throw Exception("invalid transform params $transform");
      }
      return (num v) => v * params[0];
    case 'divide':
      if (params[0] is! num) {
        throw Exception("invalid transform params $transform");
      }
      return (num v) => v / params[0];
    default:
      throw Exception("invalid transform func $transform");
  }
}
