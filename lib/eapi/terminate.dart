import 'package:eva_sdk/eva_sdk.dart';

class Terminate {
  static const name = 'terminate';
  static const description = "facke method";

  Future<Null> call(Map<String, dynamic> params) {
    return Future.value(null);
  }

  static ServiceMethod createMethod() {
    return ServiceMethod(name, Terminate().call, description)
      ..required('i', 'String');
  }
}
