import 'dart:typed_data';

import 'package:dart_snap7/dart_snap7.dart';
import 'package:eva_s7_controller/config/utils.dart';
import 'package:eva_sdk/eva_sdk.dart';

class TagSet {
  static const name = "tag.set";
  static const description = "set valuer in plc";

  final AsyncClient _client;

  TagSet(this._client);

  Future<Null> call(Map<String, dynamic> params) async {
    svc().needReady();
    if (params.isEmpty) {
      throw EvaError(
          EvaErrorKind.invalidParams, "required params: area, offset, type");
    }

    final (area, dbNum, byte, bit, type, value) = TagSet.getParams(params);

    if (type == S7Type.bool) {
      switch (area) {
        case S7Area.dataBlock:
          await _client.writeDataBlockBit(dbNum, byte, bit!, value);
        case S7Area.outputs:
          await _client.writeOutputsBit(byte, bit!, value);
        case S7Area.merkers:
          await _client.writeMerkersBit(byte, bit!, value);
        default:
          throw EvaError(EvaErrorKind.invalidParams, "invalid area");
      }
      return null;
    }

    final buffer = Uint8List.view(
        type.setValue(ByteData(type.dataLen()), 0, value).buffer);

    switch (area) {
      case S7Area.dataBlock:
        await _client.writeDataBlock(dbNum, byte, buffer);
      case S7Area.outputs:
        await _client.writeOutputs(byte, buffer);
      case S7Area.merkers:
        await _client.writeMerkers(byte, buffer);
      case S7Area.inputs:
        await _client.writeInputs(byte, buffer);
    }

    return null;
  }

  static ServiceMethod createMethod(AsyncClient s7client) {
    return ServiceMethod(name, TagSet(s7client).call, description)
      ..required('area', 'String', "example DB2 | M | I | Q")
      ..required('type', 'String', "bool, sint, int, dint, real ....")
      ..required('offset', 'String|u64',
          'String (for bool type) other u64, example for bool: 25/4')
      ..required('value', "bool|int|real ...", "value for set");
  }

  static (S7Area, int, int, int?, S7Type, dynamic) getParams(
      Map<String, dynamic> params) {
    try {
      final (area, dbNum) = parsArea(params['area']);
      final (byte, bit) = parseOffset(params['offset']);
      final type = S7Type.fromString(params['type']);
      final value = params['value'];

      if (type == S7Type.bool && (bit == null || value is! bool)) {
        throw EvaError(EvaErrorKind.invalidParams,
            "unspecified bit: $bit or value: $value");
      }

      return (area, dbNum, byte, bit, type, value);
    } catch (e) {
      throw EvaError(
          EvaErrorKind.invalidParams,
          "$e, parms => ${{
            'area': params['area'],
            'offset': params['offset'],
            'type': params['type'],
            'value': params['value'],
          }}");
    }
  }
}
