import 'dart:typed_data';

(int, int?) parseOffset(Map<dynamic, dynamic> config) {
  var offset = config['offset'];
  if (offset is int) {
    return (offset, null);
  }

  if (offset is! String) {
    throw Exception("invalid config: $config");
  }

  try {
    final result = offset.split("/").map((String e) => int.parse(e)).toList();
    return (result[0], result[1]);
  } catch (_) {
    throw Exception("invalid config: $config");
  }
}

typedef Bit = bool;
typedef I64 = int;

enum S7Type {
  bool,
  byte,
  sint,
  usint,
  world,
  int,
  uint,
  dworld,
  dint,
  udint,
  real,
  lreal;

  static S7Type fromString(String? type, (I64, I64?) offset) {
    if (offset.$2 != null) {
      return bool;
    }

    if (type == null) {
      return int;
    }

    type = type.trim().toLowerCase();
    return switch (type) {
      'bool' => bool,
      'byte' => byte,
      'sint' => sint,
      'usint' => usint,
      'world' => world,
      'int' => int,
      'uint' => uint,
      'dworld' => dworld,
      'dint' => dint,
      'udint' => udint,
      'real' => real,
      'lreal' => lreal,
      _ => throw Exception("undefinet type $type"),
    };
  }

  Bit isFloat() => this == S7Type.real || this == S7Type.lreal;

  I64 dataLen() {
    return switch (this) {
      S7Type.bool => 1,
      S7Type.byte => 1,
      S7Type.sint => 1,
      S7Type.usint => 1,
      S7Type.world => 2,
      S7Type.int => 2,
      S7Type.uint => 2,
      S7Type.dworld => 4,
      S7Type.dint => 4,
      S7Type.udint => 4,
      S7Type.real => 4,
      S7Type.lreal => 8,
    };
  }

  num getValue(ByteData data, I64 start) => switch (this) {
        S7Type.bool => data.getUint8(start),
        S7Type.byte => data.getUint8(start),
        S7Type.sint => data.getInt8(start),
        S7Type.usint => data.getUint8(start),
        S7Type.world => data.getUint16(start),
        S7Type.int => data.getInt16(start),
        S7Type.dworld => data.getUint32(start),
        S7Type.uint => data.getUint16(start),
        S7Type.dint => data.getInt32(start),
        S7Type.udint => data.getUint32(start),
        S7Type.real => data.getFloat32(start),
        S7Type.lreal => data.getFloat64(start),
      };

  ByteData setValue(ByteData data, I64 start, dynamic value) {
    switch (this) {
      case S7Type.bool:
        data.setUint8(start, value);
        return data;
      case S7Type.byte:
        data.setUint8(start, value);
        return data;
      case S7Type.sint:
        data.setInt8(start, value);
        return data;
      case S7Type.usint:
        data.setUint8(start, value);
        return data;
      case S7Type.world:
        data.setUint16(start, value);
        return data;
      case S7Type.int:
        data.setInt16(start, value);
        return data;
      case S7Type.dworld:
        data.setUint32(start, value);
        return data;
      case S7Type.uint:
        data.setUint16(start, value);
        return data;
      case S7Type.dint:
        data.setInt32(start, value);
        return data;
      case S7Type.udint:
        data.setUint32(start, value);
        return data;
      case S7Type.real:
        data.setFloat32(start, value);
        return data;
      case S7Type.lreal:
        data.setFloat64(start, value);
        return data;
    }
  }
}

(S7Area, int) parsArea(String area) {
  try {
    area = area.toUpperCase();
    if (area.startsWith("DB")) {
      final dbNum = int.parse(area.replaceFirst('DB', ''));
      return (S7Area.fromString("DB"), dbNum);
    }

    return (S7Area.fromString(area), 0);
  } catch (_) {
    throw Exception("invalid map pull area $area");
  }
}

enum S7Area {
  dataBlock,
  merkers,
  inputs,
  outputs;

  @override
  String toString() => switch (this) {
        S7Area.dataBlock => "DB",
        S7Area.merkers => "M",
        S7Area.inputs => "I",
        S7Area.outputs => "Q",
      };

  static S7Area fromString(String area) => switch (area) {
        "DB" => S7Area.dataBlock,
        "M" => S7Area.merkers,
        "I" => S7Area.inputs,
        "Q" => S7Area.outputs,
        _ => throw Exception("invalid s7 area: $area"),
      };
}
