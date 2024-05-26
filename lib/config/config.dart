import 'package:eva_s7_controller/config/action_item.dart';
import 'package:eva_s7_controller/config/pull.dart';
import 'package:eva_sdk/eva_sdk.dart';

class Config {
  final String ip;
  final int port;
  final int rack;
  final int slot;
  final int connectionType;
  final Duration pullCache;
  final Duration pullInterval;
  final List<Pull> pull;
  final List<Pull> singlePull;
  final Map<String, ActionItem> actionMap;

  Config(Map<dynamic, dynamic> config)
      : ip = config['ip'],
        port = config['port'],
        rack = config['rack'],
        slot = config['slot'],
        connectionType = config['connection_type'],
        pullCache = _fromDoubleSeconds(config['pull_cache_sec'] as num),
        pullInterval = _fromDoubleSeconds(config['pull_interval'] as num),
        pull = (config['pull'] as List)
          .where((e) => e['single_request'] == null || !e['single_request'])
          .map((e) => Pull(e)).toList(),
        singlePull = (config['pull'] as List)
          .where((e) => e['single_request'] != null && e['single_request'])
          .map((e) => Pull(e)).toList(),

        actionMap = config['action_map'] == null
            ? {}
            : _parsActionMap(config['action_map']);

  static Duration _fromDoubleSeconds(num sec) {
    final seconds = sec.toInt();
    final miliseconds = ((sec - seconds) * 1000).toInt();

    return Duration(seconds: seconds, milliseconds: miliseconds);
  }

  static Map<String, ActionItem> _parsActionMap(Map<dynamic, dynamic> actionMap) {
    final result = <String, ActionItem>{};
    for (var item in actionMap.entries) {
      
      result[Oid(item.key).asString()] = ActionItem(item.value);
    }

    return result;
  }
}
