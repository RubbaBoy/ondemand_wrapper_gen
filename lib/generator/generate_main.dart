import 'dart:io';

import 'package:ondemand_wrapper_gen/creating.dart';

class GenerateMain {

  Future<void> generate(List<CreatedFile> createdFiles, File file) =>
      file.writeAsString(generateString(createdFiles));

  String generateString(List<CreatedFile> createdFiles) => '''
library ondemand;

export 'ondemand_requests.dart';
export 'shared_classes.dart';
export 'base.dart';
export 'helper/constants.dart';
export 'helper/init.dart';
export 'helper/kitchen_helper.dart';
export 'helper/account_inquiry_helper.dart';
''';
}
