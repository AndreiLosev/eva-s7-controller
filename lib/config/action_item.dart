import 'package:eva_s7_controller/config/utils.dart';

class ActionItem {
  late final S7Area area;
  late final int dbNum;
  late final (int, int?) offset;
  late final S7Type type;

  ActionItem(Map<dynamic, dynamic> config) {
    final areaAndDbNum = parsArea(config['area']);
    area = areaAndDbNum.$1;
    dbNum = areaAndDbNum.$2;
    offset = parseOffset(config);
    type = S7Type.fromString(config['type'], offset);
  }
}
