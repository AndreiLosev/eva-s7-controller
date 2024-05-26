import 'dart:typed_data';

import 'package:dart_snap7/dart_snap7.dart';
import 'package:eva_s7_controller/config/utils.dart';
import 'package:eva_s7_controller/utils/bit_map.dart';
import 'package:eva_sdk/eva_sdk.dart';

class TagGet {
  static const name = "tag.get";
  static const description = "get valuer from plc";

  final AsyncClient _client;

  TagGet(this._client);

  Future<Map<String, dynamic>> call(Map<String, dynamic> params) async {
    svc().needReady();
    if (params.isEmpty) {
      throw EvaError(
          EvaErrorKind.invalidParams, "required params: area, offset, type");
    }

    final (area, dbNum, byte, bit, type) = TagGet.getParams(params);

    final response = switch (area) {
      S7Area.dataBlock =>
        await _client.readDataBlock(dbNum, byte, type.dataLen()),
      S7Area.inputs => await _client.readInputs(byte, type.dataLen()),
      S7Area.outputs => await _client.readOutputs(byte, type.dataLen()),
      S7Area.merkers => await _client.readMerkers(byte, type.dataLen()),
    };

    final (value, key) = switch (type) {
      S7Type.bool => (
          (type.getValue(ByteData.view(response.buffer), 0) as int)
              .getBit(bit!),
          "$area$byte/$bit"
        ),
      _ => (type.getValue(ByteData.view(response.buffer), 0), "$area$byte"),
    };

    return {key: value};
  }

  static ServiceMethod createMethod(AsyncClient s7client) {
    return ServiceMethod(name, TagGet(s7client).call, description)
      ..required('area', 'String', "example DB2 | M | I | Q")
      ..required('type', 'String', "bool, sint, int, dint, real ....")
      ..required('offset', 'String|u64',
          'String (for bool type) other u64, example for bool: 25/4');
  }

  static (S7Area, int, int, int?, S7Type) getParams(
      Map<String, dynamic> params) {
    try {
      final (area, dbNum) = parsArea(params['area']);
      final (byte, bit) = parseOffset(params['offset']);
      final type = S7Type.fromString(params['type'], (byte, bit));

      if (type == S7Type.bool && bit == null) {
        throw EvaError(EvaErrorKind.invalidParams, "unspecified bit: $bit");
      }

      return (area, dbNum, byte, bit, type);
    } catch (e) {
      throw EvaError(
          EvaErrorKind.invalidParams,
          "$e, parms => ${{
            'area': params['area'],
            'offset': params['offset'],
            'type': params['type'],
          }}");
    }
  }
}
