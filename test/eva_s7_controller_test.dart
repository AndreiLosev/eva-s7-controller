import 'dart:io';

import 'package:eva_s7_controller/config/check_config.dart';
import 'package:eva_s7_controller/config/config.dart';
import 'package:eva_s7_controller/config/utils.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  test('parse-config', () async {
    final file = File('examle-config.yaml');
    final str = await file.readAsString();
    final conf = loadYaml(str)['config'];
    checkConfig(conf);
    final c = Config(conf);
    expect(c.ip, '127.0.0.1');
    expect(c.port, 102);
    expect(c.rack, 0);
    expect(c.slot, 0);
    expect(c.connectionType, 3);
    expect(c.pullCache.toString(), Duration(hours: 1).toString());
    expect(c.pullInterval.toString(), Duration(seconds: 1, milliseconds: 500).toString());
    expect(c.pull.length, 5);
    expect(c.pull[0].area, S7Area.dataBlock);
    expect(c.pull[0].dbNum, 2);
    expect(c.pull[1].area, S7Area.merkers);
    expect(c.pull[1].dbNum, 0);
    expect(c.pull[0].map.length, 8);
    expect(c.pull[0].map[2].offset, (22, 2));
    expect(c.pull[0].map[2].delta, null);
    expect(c.pull[0].map[2].type, S7Type.bool);
    expect(c.pull[0].map[2].oid.asString(), 'sensor:tank1/level_max');
    expect(c.pull[0].start, 22);
    expect(c.pull[0].size, 20);
    expect(c.pull[1].start, 34);
    expect(c.pull[1].size, 12);
    expect(c.pull[0].map[6].offset, (30, null));
    expect(c.pull[0].map[6].delta, 0.15);
    expect(c.pull[0].map[6].type, S7Type.real);
    expect(c.pull[0].map[6].oid.asString(), 'sensor:tank1/temp_in');
    expect(c.actionMap.keys.length, 4);
    expect(c.actionMap['unit:tank1/pump2_speed']!.area, S7Area.merkers);
    expect(c.actionMap['unit:tank1/pump2_speed']!.offset, (38, null));
    expect(c.actionMap['unit:tank1/pump2_speed']!.type, S7Type.real);
    expect(c.actionMap['unit:tank1/pump2_run']!.area, S7Area.dataBlock);
    expect(c.actionMap['unit:tank1/pump2_run']!.dbNum, 4);
    expect(c.actionMap['unit:tank1/pump2_run']!.offset, (40, 1));
    expect(c.actionMap['unit:tank1/pump2_run']!.type, S7Type.bool);
  });
}
