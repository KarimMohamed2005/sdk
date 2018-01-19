// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/type_environment.dart';
import 'package:test/test.dart';
import 'package:vm/transformations/type_flow/native_code.dart';
import 'package:vm/transformations/type_flow/summary_collector.dart';

import 'common_test_utils.dart';

final String pkgVmDir = Platform.script.resolve('../../..').toFilePath();

class PrintSummaries extends RecursiveVisitor<Null> {
  final SummaryCollector _summaryColector;
  final StringBuffer _buf = new StringBuffer();

  PrintSummaries(TypeEnvironment environment)
      : _summaryColector = new SummaryCollector(
            environment, new EntryPointsListener(), new NativeCodeOracle(null));

  String print(TreeNode node) {
    visitLibrary(node);
    return _buf.toString();
  }

  @override
  defaultMember(Member member) {
    if (!member.isAbstract) {
      _buf.writeln("------------ $member ------------");
      _buf.writeln(_summaryColector.createSummary(member));
    }
  }
}

runTestCase(Uri source) async {
  final Program program = await compileTestCaseToKernelProgram(source);
  final Library library = program.mainMethod.enclosingLibrary;

  // Make sure the library name is the same and does not depend on the order
  // of test cases.
  library.name = '#lib';

  final typeEnvironment =
      new TypeEnvironment(new CoreTypes(program), new ClassHierarchy(program));

  final actual = new PrintSummaries(typeEnvironment).print(library);

  compareResultWithExpectationsFile(source, actual);
}

main() {
  group('collect-summary', () {
    final testCasesDir = new Directory(
        pkgVmDir + '/testcases/transformations/type_flow/summary_collector');

    for (var entry
        in testCasesDir.listSync(recursive: true, followLinks: false)) {
      if (entry.path.endsWith(".dart")) {
        test(entry.path, () => runTestCase(entry.uri));
      }
    }
  });
}
