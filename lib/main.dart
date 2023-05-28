import 'package:flutter/material.dart';
import 'package:statsfl/statsfl.dart';

import 'local_import.dart';
import 'data.dart';
import 'controller_dat_gui.dart';
import 'three_widget.dart';

String formatDate(DateTime dateTime) {
  var today = DateTime.now();
  var difference = dateTime.difference(today);

  return switch (difference) {
    Duration(inDays: 0) => 'today',
    Duration(inDays: 1) => 'tomorrow',
    Duration(inDays: -1) => 'yesterday',
    Duration(inDays: var days) when days > 7 => '${days ~/ 7} weeks from now',
    Duration(inDays: var days) when days < -7 =>
      '${days.abs() ~/ 7} weeks from ago',
    Duration(inDays: var days, isNegative: true) => '${days.abs()} days ago',
    Duration(inDays: var days) => '$days days from now',
  };
}

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final controllerDartGui = Get.put(DatGuiController());

    return StatsFl(
        isEnabled: true,
        align: Alignment.topLeft,
        width: 80,
        height: 30,
        child: MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: DocumentScreen(
            document: Document(),
          ),
        ));
  }
}

class DocumentScreen extends StatelessWidget {
  final Document document;

  const DocumentScreen({
    required this.document,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var (title, :modified) = document.getMetadata();
    var formattedModifiedDate = formatDate(modified);
    var blocks = document.getBlocks();
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Column(
        children: [
          Text('Last modified $formattedModifiedDate'),
          ThreeWidget(),
          Expanded(
              child: ListView.builder(
                  itemCount: blocks.length,
                  itemBuilder: (context, index) {
                    return BlockWidget(block: blocks[index]);
                  })),
        ],
      ),
    );
  }
}

class BlockWidget extends StatelessWidget {
  final Block block;

  const BlockWidget({
    required this.block,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TextStyle? textStyle;
    // textStyle = switch (block.type) {
    //   'h1' => Theme.of(context).textTheme.displayMedium,
    //   'p' || 'checkbox' => Theme.of(context).textTheme.bodyMedium,
    //   _ => Theme.of(context).textTheme.bodySmall
    // };

    // return Container(
    //   margin: const EdgeInsets.all(8),
    //   child: Text(
    //     block.text,
    //     style: textStyle,
    //   ),
    // );
    return Container(
      margin: const EdgeInsets.all(8),
      child: switch (block) {
        HeaderBlock(:var text) => Text(
            text,
            style: Theme.of(context).textTheme.displayMedium,
          ),
        ParagraphBlock(:var text) => Text(text),
        CheckboxBlock(:var text, :var isChecked) => Row(
            children: [
              Checkbox(value: isChecked, onChanged: (_) {}),
              Text(text),
            ],
          ),
      },
    );
  }
}
