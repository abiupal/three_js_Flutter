import 'package:flutter/material.dart';
import 'local_import.dart';

class DatGuiInfo {
  String name;
  double value;
  double min;
  double max;

  DatGuiInfo(
      {required this.name,
      required this.value,
      required this.min,
      required this.max});
}

class DatGuiController extends GetxController {
  // DatGuiController.to. でアクセス
  static DatGuiController get to => Get.find<DatGuiController>();

  final stateUpdate = false.obs; //更新フラグ
  final Map<String, DatGuiInfo> _infos = {}; //項目管理
  double step = 0; //bouncingSpeed

  //項目の追加
  void add(final String name, final value, final double min, final double max) {
    DatGuiInfo newInfo =
        DatGuiInfo(name: name, value: value, min: min, max: max);
    _infos[name] = newInfo;
  }

  //値の更新
  void updateValue(final String name, final value) {
    _infos[name]?.value = value;
  }

  //値の取得
  double? getValue(final String name) {
    return _infos[name]?.value;
  }
}

class DatGuiWidget extends StatelessWidget {
  const DatGuiWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Map<String, DatGuiInfo> gui = DatGuiController.to._infos;
    final List<DatGuiInfo> listGui = gui.entries
        .map((e) => DatGuiInfo(
            name: e.value.name,
            value: e.value.value,
            min: e.value.min,
            max: e.value.max))
        .toList();
    double width = 300;
    return SizedBox(
      width: width,
      child: Expanded(
        child: ListView.builder(
          itemCount: listGui.length,
          itemBuilder: (BuildContext context, int index) {
            DatGuiInfo info = listGui[index];
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  info.name,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Slider(
                  value: info.value,
                  min: info.min,
                  max: info.max,
                  onChanged: (value) {
                    DatGuiController.to.updateValue(info.name, value);
                  },
                )
              ],
            );
          },
        ),
      ),
    );
  }
}
