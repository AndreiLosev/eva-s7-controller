import 'package:eva_sdk/eva_sdk.dart';

class Kill {
  static const name = 'kill';
  static const description = "facke method";

  Future<Null> call(Map<String, dynamic> params) {
    return Future.value(null);
  }

  static ServiceMethod createMethod() {
    return ServiceMethod(name, Kill().call, description)
      ..required('uuid', 'List<u8>');
  }
}
