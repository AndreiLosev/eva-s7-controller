import 'dart:typed_data';

import 'package:dart_snap7/dart_snap7.dart';
import 'package:eva_s7_controller/config/config.dart';
import 'package:eva_s7_controller/config/pull.dart';
import 'package:eva_s7_controller/config/utils.dart';
import 'package:eva_s7_controller/utils/bit_map.dart';
import 'package:eva_s7_controller/utils/periodic_timer.dart';

class PullHandler {
  final AsyncClient _s7client;
  final _multiRequest = MultiReadRequest();
  final List<Pull> _multi;
  final List<Pull> _single;
  late final ByteData _data;
  final Duration _pullCache;
  final Duration _pullInterval;
  PeriodicTimer? _timerMulti;
  PeriodicTimer? _timerSingle;

  PullHandler(this._s7client, Config config)
      : _multi = config.pull,
        _single = config.singlePull,
        _pullCache = config.pullCache,
        _pullInterval = config.pullInterval {
    _setMultiREquest();
  }

  void run() {
    if (_multi.isNotEmpty) {
      _timerMulti = PeriodicTimer(_pullInterval, (_) async {
        await _readMulti();
      });
    }

    if (_single.isNotEmpty) {
      _timerSingle = PeriodicTimer(_pullInterval, (_) async {
        await _readSingle();
      });
    }
  }

  void stop() {
    _timerMulti?.cancel();
    _timerSingle?.cancel();
  }

  Future<void> setErrorStatus() async {
    for (var pull in _multi) {
      for (var item in pull.map) {
        await item.piblishErrorStatus();
      }
    }
  }

  void _setMultiREquest() {
    int sum = 0;
    for (var item in _multi) {
      sum += item.size;
      switch (item.area) {
        case S7Area.dataBlock:
          _multiRequest.readDataBlock(item.dbNum, item.start, item.size);
        case S7Area.merkers:
          _multiRequest.readMerkers(item.start, item.size);
        case S7Area.inputs:
          _multiRequest.readInputs(item.start, item.size);
        case S7Area.outputs:
          _multiRequest.readOutputs(item.start, item.size);
      }
    }

    _data = ByteData(sum);
  }

  Future<void> _readMulti() async {
    final response = await _s7client.readMultiVars(_multiRequest);
    final error = response.where((e) => e.$1 is S7Error).firstOrNull;

    if (error != null) {
      throw error;
    }

    int i = 0;
    for (var (_, data) in response) {
      for (var byte in data) {
        _data.setUint8(i, byte);
        i += 1;
      }
    }

    i = 0;
    for (var pull in _multi) {
      for (var item in pull.map) {
        dynamic value =
            item.type.getValue(_data, i + item.offset.$1 - pull.start);
        if (item.type == S7Type.bool) {
          value = (value as int).getBit(item.offset.$2!);
        }

        if (item.isChanget(value) || item.timerIsExpired(_pullCache)) {
          item.publish(value);
          item.stopAndResetTimer();
        } else {
          item.startTimer();
        }
      }

      i += pull.size;
    }
  }

  Future<void> _readSingle() async {
    for (var pull in _single) {
      final response = await switch (pull.area) {
        S7Area.dataBlock =>
          _s7client.readDataBlock(pull.dbNum, pull.start, pull.size),
        S7Area.merkers => _s7client.readMerkers(pull.start, pull.size),
        S7Area.inputs => _s7client.readInputs(pull.start, pull.size),
        S7Area.outputs => _s7client.readOutputs(pull.start, pull.size),
      };

      final data = ByteData.view(response.buffer);

      for (var item in pull.map) {
        dynamic value = item.type.getValue(data, item.offset.$1 - pull.start);
        if (item.type == S7Type.bool) {
          value = (value as int).getBit(item.offset.$2!);
        }

        if (item.isChanget(value) || item.timerIsExpired(_pullCache)) {
          item.publish(value);
          item.stopAndResetTimer();
        } else {
          item.startTimer();
        }
      }
    }
  }
}
