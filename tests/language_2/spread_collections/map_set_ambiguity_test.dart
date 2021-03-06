// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=set-literals,spread-collections

// Test cases where the syntax is ambiguous between maps and sets.
import 'dart:collection';

import 'package:expect/expect.dart';

import 'helper_classes.dart';

void main() {
  testBottomUpInference();
  testTopDownInference();
}

void testBottomUpInference() {
  Map<int, int> map = {};
  Set<int> set = Set();
  dynamic dyn = map;
  Iterable<int> iterable = [];
  CustomSet customSet = CustomSet();
  CustomMap customMap = CustomMap();

  // Note: The commented out cases are the error cases. They are shown here for
  // completeness and tested in map_set_ambiguity_error_test.dart.
  Expect.type<Map<int, int>>({...map});
  Expect.type<Set<int>>({...set});
  // Expect.type<...>({...dyn});
  Expect.type<Set<int>>({...iterable});
  Expect.type<Set<int>>({...customSet});
  Expect.type<Map<int, int>>({...customMap});

  Expect.type<Map<int, int>>({...map, ...map});
  // Expect.type<...>({...map, ...set});
  Expect.type<Map<dynamic, dynamic>>({...map, ...dyn});
  // Expect.type<...>({...map, ...iterable});
  // Expect.type<...>({...map, ...customSet});
  Expect.type<Map<int, int>>({...map, ...customMap});

  Expect.type<Set<int>>({...set, ...set});
  Expect.type<Set<dynamic>>({...set, ...dyn});
  Expect.type<Set<int>>({...set, ...iterable});
  Expect.type<Set<int>>({...set, ...customSet});
  // Expect.type<...>({...set, ...customMap});

  // Expect.type<...>({...dyn, ...dyn});
  Expect.type<Set<dynamic>>({...dyn, ...iterable});
  Expect.type<Set<dynamic>>({...dyn, ...customSet});
  Expect.type<Map<dynamic, dynamic>>({...dyn, ...customMap});

  Expect.type<Set<int>>({...iterable, ...iterable});
  Expect.type<Set<int>>({...iterable, ...customSet});
  // Expect.type<...>({...iterable, ...customMap});

  Expect.type<Set<int>>({...customSet, ...customSet});
  // Expect.type<...>({...customSet, ...customMap});

  Expect.type<Map<int, int>>({...customMap, ...customMap});
}

void testTopDownInference() {
  dynamic untypedMap = <int, int>{};
  dynamic untypedIterable = <int>[];

  Map<int, int> map = {...untypedMap};
  Set<int> set = {...untypedIterable};
  Iterable<int> iterable = {...untypedIterable};

  Expect.type<Map<int, int>>(map);
  Expect.type<Set<int>>(set);
  Expect.type<Set<int>>(iterable);
}
