export 'package:get/get.dart';
import 'dart:developer' as dev;

devLog(String description) {
  dev.log("${description}\n${StackTrace.current.toString().split("#")[2]}",
      name: "myLog");
}

devErr(String error, stackTrace) {
  dev.log("", error: error);
  dev.log("", error: stackTrace.toString());
}
