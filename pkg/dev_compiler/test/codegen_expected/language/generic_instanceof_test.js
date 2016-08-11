dart_library.library('language/generic_instanceof_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__generic_instanceof_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const generic_instanceof_test = Object.create(null);
  let Foo = () => (Foo = dart.constFn(generic_instanceof_test.Foo$()))();
  let FooOfString = () => (FooOfString = dart.constFn(generic_instanceof_test.Foo$(core.String)))();
  let ListOfObject = () => (ListOfObject = dart.constFn(core.List$(core.Object)))();
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let ListOfnum = () => (ListOfnum = dart.constFn(core.List$(core.num)))();
  let ListOfString = () => (ListOfString = dart.constFn(core.List$(core.String)))();
  let FooOfList = () => (FooOfList = dart.constFn(generic_instanceof_test.Foo$(core.List)))();
  let FooOfListOfObject = () => (FooOfListOfObject = dart.constFn(generic_instanceof_test.Foo$(ListOfObject())))();
  let FooOfListOfint = () => (FooOfListOfint = dart.constFn(generic_instanceof_test.Foo$(ListOfint())))();
  let FooOfListOfnum = () => (FooOfListOfnum = dart.constFn(generic_instanceof_test.Foo$(ListOfnum())))();
  let FooOfListOfString = () => (FooOfListOfString = dart.constFn(generic_instanceof_test.Foo$(ListOfString())))();
  let FooOfObject = () => (FooOfObject = dart.constFn(generic_instanceof_test.Foo$(core.Object)))();
  let FooOfint = () => (FooOfint = dart.constFn(generic_instanceof_test.Foo$(core.int)))();
  let FooOfnum = () => (FooOfnum = dart.constFn(generic_instanceof_test.Foo$(core.num)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  generic_instanceof_test.main = function() {
    for (let i = 0; i < 5; i++) {
      generic_instanceof_test.GenericInstanceof.testMain();
    }
  };
  dart.fn(generic_instanceof_test.main, VoidTodynamic());
  generic_instanceof_test.Foo$ = dart.generic(T => {
    let ListOfT = () => (ListOfT = dart.constFn(core.List$(T)))();
    class Foo extends core.Object {
      new() {
      }
      isT(x) {
        return T.is(x);
      }
      isListT(x) {
        return ListOfT().is(x);
      }
    }
    dart.addTypeTests(Foo);
    dart.setSignature(Foo, {
      constructors: () => ({new: dart.definiteFunctionType(generic_instanceof_test.Foo$(T), [])}),
      methods: () => ({
        isT: dart.definiteFunctionType(core.bool, [dart.dynamic]),
        isListT: dart.definiteFunctionType(core.bool, [dart.dynamic])
      })
    });
    return Foo;
  });
  generic_instanceof_test.Foo = Foo();
  generic_instanceof_test.GenericInstanceof = class GenericInstanceof extends core.Object {
    static testMain() {
      let fooObject = new (FooOfString())();
      expect$.Expect.equals(true, fooObject.isT("string"));
      expect$.Expect.equals(false, fooObject.isT(1));
      let fooString = new (FooOfString())();
      expect$.Expect.equals(true, fooString.isT("string"));
      expect$.Expect.equals(false, fooString.isT(1));
      {
        let foo = new (FooOfString())();
        expect$.Expect.equals(true, foo.isT("string"));
        expect$.Expect.equals(false, foo.isT(1));
      }
      {
        let foo = new generic_instanceof_test.Foo();
        expect$.Expect.equals(true, foo.isT(core.List.new(5)));
        expect$.Expect.equals(true, foo.isT(ListOfObject().new(5)));
        expect$.Expect.equals(true, foo.isT(ListOfint().new(5)));
        expect$.Expect.equals(true, foo.isT(ListOfnum().new(5)));
        expect$.Expect.equals(true, foo.isT(ListOfString().new(5)));
      }
      {
        let foo = new (FooOfList())();
        expect$.Expect.equals(true, foo.isT(core.List.new(5)));
        expect$.Expect.equals(true, foo.isT(ListOfObject().new(5)));
        expect$.Expect.equals(true, foo.isT(ListOfint().new(5)));
        expect$.Expect.equals(true, foo.isT(ListOfnum().new(5)));
        expect$.Expect.equals(true, foo.isT(ListOfString().new(5)));
      }
      {
        let foo = new (FooOfListOfObject())();
        expect$.Expect.equals(true, foo.isT(core.List.new(5)));
        expect$.Expect.equals(true, foo.isT(ListOfObject().new(5)));
        expect$.Expect.equals(true, foo.isT(ListOfint().new(5)));
        expect$.Expect.equals(true, foo.isT(ListOfnum().new(5)));
        expect$.Expect.equals(true, foo.isT(ListOfString().new(5)));
      }
      {
        let foo = new (FooOfListOfint())();
        expect$.Expect.equals(true, foo.isT(core.List.new(5)));
        expect$.Expect.equals(false, foo.isT(ListOfObject().new(5)));
        expect$.Expect.equals(true, foo.isT(ListOfint().new(5)));
        expect$.Expect.equals(false, foo.isT(ListOfnum().new(5)));
        expect$.Expect.equals(false, foo.isT(ListOfString().new(5)));
      }
      {
        let foo = new (FooOfListOfnum())();
        expect$.Expect.equals(true, foo.isT(core.List.new(5)));
        expect$.Expect.equals(false, foo.isT(ListOfObject().new(5)));
        expect$.Expect.equals(true, foo.isT(ListOfint().new(5)));
        expect$.Expect.equals(true, foo.isT(ListOfnum().new(5)));
        expect$.Expect.equals(false, foo.isT(ListOfString().new(5)));
      }
      {
        let foo = new (FooOfListOfString())();
        expect$.Expect.equals(true, foo.isT(core.List.new(5)));
        expect$.Expect.equals(false, foo.isT(ListOfObject().new(5)));
        expect$.Expect.equals(false, foo.isT(ListOfint().new(5)));
        expect$.Expect.equals(false, foo.isT(ListOfnum().new(5)));
        expect$.Expect.equals(true, foo.isT(ListOfString().new(5)));
      }
      {
        let foo = new generic_instanceof_test.Foo();
        expect$.Expect.equals(true, foo.isListT(core.List.new(5)));
        expect$.Expect.equals(true, foo.isListT(ListOfObject().new(5)));
        expect$.Expect.equals(true, foo.isListT(ListOfint().new(5)));
        expect$.Expect.equals(true, foo.isListT(ListOfnum().new(5)));
        expect$.Expect.equals(true, foo.isListT(ListOfString().new(5)));
      }
      {
        let foo = new (FooOfObject())();
        expect$.Expect.equals(true, foo.isListT(core.List.new(5)));
        expect$.Expect.equals(true, foo.isListT(ListOfObject().new(5)));
        expect$.Expect.equals(true, foo.isListT(ListOfint().new(5)));
        expect$.Expect.equals(true, foo.isListT(ListOfnum().new(5)));
        expect$.Expect.equals(true, foo.isListT(ListOfString().new(5)));
      }
      {
        let foo = new (FooOfint())();
        expect$.Expect.equals(true, foo.isListT(core.List.new(5)));
        expect$.Expect.equals(false, foo.isListT(ListOfObject().new(5)));
        expect$.Expect.equals(true, foo.isListT(ListOfint().new(5)));
        expect$.Expect.equals(false, foo.isListT(ListOfnum().new(5)));
        expect$.Expect.equals(false, foo.isListT(ListOfString().new(5)));
      }
      {
        let foo = new (FooOfnum())();
        expect$.Expect.equals(true, foo.isListT(core.List.new(5)));
        expect$.Expect.equals(false, foo.isListT(ListOfObject().new(5)));
        expect$.Expect.equals(true, foo.isListT(ListOfint().new(5)));
        expect$.Expect.equals(true, foo.isListT(ListOfnum().new(5)));
        expect$.Expect.equals(false, foo.isListT(ListOfString().new(5)));
      }
      {
        let foo = new (FooOfString())();
        expect$.Expect.equals(true, foo.isListT(core.List.new(5)));
        expect$.Expect.equals(false, foo.isListT(ListOfObject().new(5)));
        expect$.Expect.equals(false, foo.isListT(ListOfint().new(5)));
        expect$.Expect.equals(false, foo.isListT(ListOfnum().new(5)));
        expect$.Expect.equals(true, foo.isListT(ListOfString().new(5)));
      }
    }
  };
  dart.setSignature(generic_instanceof_test.GenericInstanceof, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.void, [])}),
    names: ['testMain']
  });
  // Exports:
  exports.generic_instanceof_test = generic_instanceof_test;
});
