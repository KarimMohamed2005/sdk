// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.summary.flat_buffers;

import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

/**
 * A pointer to some data.
 */
class BufferPointer {
  final ByteData _buffer;
  final int _offset;

  factory BufferPointer.fromBytes(List<int> byteList, [int offset = 0]) {
    Uint8List uint8List = _asUint8List(byteList);
    ByteData buf = new ByteData.view(uint8List.buffer);
    return new BufferPointer._(buf, uint8List.offsetInBytes + offset);
  }

  BufferPointer._(this._buffer, this._offset);

  BufferPointer derefObject() {
    int uOffset = _getUint32();
    return _advance(uOffset);
  }

  @override
  String toString() => _offset.toString();

  BufferPointer _advance(int delta) {
    return new BufferPointer._(_buffer, _offset + delta);
  }

  int _getInt32([int delta = 0]) =>
      _buffer.getInt32(_offset + delta, Endianness.LITTLE_ENDIAN);

  int _getInt8([int delta = 0]) => _buffer.getInt8(_offset + delta);

  int _getUint16([int delta = 0]) =>
      _buffer.getUint16(_offset + delta, Endianness.LITTLE_ENDIAN);

  int _getUint32([int delta = 0]) =>
      _buffer.getUint32(_offset + delta, Endianness.LITTLE_ENDIAN);

  /**
   * If the [byteList] is already a [Uint8List] return it.
   * Otherwise return a [Uint8List] copy of the [byteList].
   */
  static Uint8List _asUint8List(List<int> byteList) {
    if (byteList is Uint8List) {
      return byteList;
    } else {
      return new Uint8List.fromList(byteList);
    }
  }
}

/**
 * Class that helps building flat buffers.
 */
class Builder {
  final int initialSize;

  ByteData _buf;

  /**
   * The maximum alignment that has been seen so far.  If [_buf] has to be
   * reallocated in the future (to insert room at its start for more bytes) the
   * reallocation will need to be a multiple of this many bytes.
   */
  int _maxAlign;

  /**
   * The number of bytes that have been written to the buffer so far.  The
   * most recently written byte is this many bytes from the end of [_buf].
   */
  int _tail;

  /**
   * The location of the end of the current table, measured in bytes from the
   * end of [_buf], or `null` if a table is not currently being built.
   */
  int _currentTableEndTail;

  _VTableBuilder _currentVTableBuilder;

  Builder({this.initialSize: 1024}) {
    reset();
  }

  /**
   * Add the [field] with the given 32-bit signed integer [value].  The field is
   * not added if the [value] is equal to [def].
   */
  void addInt32(int field, int value, [int def]) {
    if (_currentVTableBuilder == null) {
      throw new StateError('Start a table before adding values.');
    }
    if (value != def) {
      int size = 4;
      _prepare(size, 1);
      _trackField(field);
      _setInt32AtTail(_buf, _tail, value);
    }
  }

  /**
   * Add the [field] with the given 8-bit signed integer [value].  The field is
   * not added if the [value] is equal to [def].
   */
  void addInt8(int field, int value, [int def]) {
    if (_currentVTableBuilder == null) {
      throw new StateError('Start a table before adding values.');
    }
    if (value != def) {
      int size = 1;
      _prepare(size, 1);
      _trackField(field);
      _buf.setInt8(_buf.lengthInBytes - _tail, value);
    }
  }

  /**
   * Add the [field] referencing an object with the given [offset].
   */
  void addOffset(int field, Offset offset) {
    if (_currentVTableBuilder == null) {
      throw new StateError('Start a table before adding values.');
    }
    if (offset != null) {
      _prepare(4, 1);
      _trackField(field);
      _setUint32AtTail(_buf, _tail, _tail - offset._tail);
    }
  }

  /**
   * End the current table and return its offset.
   */
  Offset endTable() {
    if (_currentVTableBuilder == null) {
      throw new StateError('Start a table before ending it.');
    }
    // Prepare the size of the current table.
    int tableSize = _tail - _currentTableEndTail;
    // Prepare for writing the VTable.
    _prepare(4, 1);
    int tableTail = _tail;
    // Write the VTable.
    // TODO(scheglov) implement VTable(s) sharing
    _prepare(2, _currentVTableBuilder.numOfUint16);
    _currentVTableBuilder.output(
        _buf, _buf.lengthInBytes - _tail, tableTail, tableSize);
    // Set the VTable offset.
    _setInt32AtTail(_buf, tableTail, _tail - tableTail);
    // Done with this table.
    _currentVTableBuilder = null;
    return new Offset(tableTail);
  }

  /**
   * Finish off the creation of the buffer.  The given [offset] is used as the
   * root object offset, and usually references directly or indirectly every
   * written object.
   */
  Uint8List finish(Offset offset) {
    _prepare(4, 1);
    _setUint32AtTail(_buf, _tail, _tail - offset._tail);
    int alignedTail = _tail + ((-_tail) % _maxAlign);
    return _buf.buffer.asUint8List(_buf.lengthInBytes - alignedTail);
  }

  /**
   * This is a low-level method, it should not be invoked by clients.
   */
  Uint8List lowFinish() {
    int alignedTail = _tail + ((-_tail) % _maxAlign);
    return _buf.buffer.asUint8List(_buf.lengthInBytes - alignedTail);
  }

  /**
   * This is a low-level method, it should not be invoked by clients.
   */
  void lowReset() {
    _buf = new ByteData(initialSize);
    _maxAlign = 1;
    _tail = 0;
  }

  /**
   * This is a low-level method, it should not be invoked by clients.
   */
  void lowWriteUint32(int value) {
    _prepare(4, 1);
    _setUint32AtTail(_buf, _tail, value);
  }

  /**
   * This is a low-level method, it should not be invoked by clients.
   */
  void lowWriteUint8(int value) {
    _prepare(1, 1);
    _buf.setUint8(_buf.lengthInBytes - _tail, value);
  }

  /**
   * Reset the builder and make it ready for filling a new buffer.
   */
  void reset() {
    _buf = new ByteData(initialSize);
    _maxAlign = 1;
    _tail = 0;
    _currentVTableBuilder = null;
  }

  /**
   * Start a new table.  Must be finished with [endTable] invocation.
   */
  void startTable() {
    if (_currentVTableBuilder != null) {
      throw new StateError('Inline tables are not supported.');
    }
    _currentVTableBuilder = new _VTableBuilder();
    _currentTableEndTail = _tail;
  }

  /**
   * Write the given list of [values].
   */
  Offset writeList(List<Offset> values) {
    if (_currentVTableBuilder != null) {
      throw new StateError(
          'Cannot write a non-scalar value while writing a table.');
    }
    _prepare(4, 1 + values.length);
    Offset result = new Offset(_tail);
    int tail = _tail;
    _setUint32AtTail(_buf, tail, values.length);
    tail -= 4;
    for (Offset value in values) {
      _setUint32AtTail(_buf, tail, tail - value._tail);
      tail -= 4;
    }
    return result;
  }

  /**
   * Write the given string [value] and return its [Offset], or `null` if
   * the [value] is equal to [def].
   */
  Offset<String> writeString(String value, [String def]) {
    if (_currentVTableBuilder != null) {
      throw new StateError(
          'Cannot write a non-scalar value while writing a table.');
    }
    if (value != def) {
      // TODO(scheglov) optimize for ASCII strings
      List<int> bytes = UTF8.encode(value);
      int length = bytes.length;
      _prepare(4, 1, additionalBytes: length);
      Offset<String> result = new Offset(_tail);
      _setUint32AtTail(_buf, _tail, length);
      int offset = _buf.lengthInBytes - _tail + 4;
      for (int i = 0; i < length; i++) {
        _buf.setUint8(offset++, bytes[i]);
      }
      return result;
    }
    return null;
  }

  /**
   * Prepare for writing the given [count] of scalars of the given [size].
   * Additionally allocate the specified [additionalBytes]. Update the current
   * tail pointer to point at the allocated space.
   */
  void _prepare(int size, int count, {int additionalBytes: 0}) {
    // Update the alignment.
    if (_maxAlign < size) {
      _maxAlign = size;
    }
    // Prepare amount of required space.
    int dataSize = size * count + additionalBytes;
    int alignDelta = (-(_tail + dataSize)) % size;
    int bufSize = alignDelta + dataSize;
    // Ensure that we have the required amount of space.
    {
      int oldCapacity = _buf.lengthInBytes;
      if (_tail + bufSize > oldCapacity) {
        int desiredNewCapacity = (oldCapacity + bufSize) * 2;
        int deltaCapacity = desiredNewCapacity - oldCapacity;
        deltaCapacity += (-deltaCapacity) % _maxAlign;
        int newCapacity = oldCapacity + deltaCapacity;
        ByteData newBuf = new ByteData(newCapacity);
        newBuf.buffer
            .asUint8List()
            .setAll(deltaCapacity, _buf.buffer.asUint8List());
        _buf = newBuf;
      }
    }
    // Update the tail pointer.
    _tail += bufSize;
  }

  /**
   * Record the offset of the given [field].
   */
  void _trackField(int field) {
    _currentVTableBuilder.addField(field, _tail);
  }

  static void _setInt32AtTail(ByteData _buf, int tail, int x) {
    _buf.setInt32(_buf.lengthInBytes - tail, x, Endianness.LITTLE_ENDIAN);
  }

  static void _setUint32AtTail(ByteData _buf, int tail, int x) {
    _buf.setUint32(_buf.lengthInBytes - tail, x, Endianness.LITTLE_ENDIAN);
  }
}

/**
 * The reader of 32-bit signed integers.
 */
class Int32Reader extends Reader<int> {
  const Int32Reader() : super();

  @override
  int get size => 2;

  @override
  int read(BufferPointer bp) => bp._getInt32();
}

/**
 * The reader of 8-bit signed integers.
 */
class Int8Reader extends Reader<int> {
  const Int8Reader() : super();

  @override
  int get size => 1;

  @override
  int read(BufferPointer bp) => bp._getInt8();
}

/**
 * The reader of object.
 *
 * The returned unmodifiable lists lazily read objects on access.
 */
class ListReader<E> extends Reader<List<E>> {
  final Reader<E> _elementReader;

  const ListReader(this._elementReader);

  @override
  int get size => 4;

  @override
  List<E> read(BufferPointer bp) =>
      new _FbList<E>(_elementReader, bp.derefObject());
}

/**
 * The offset from the end of the buffer to a serialized object of the type [T].
 */
class Offset<T> {
  final int _tail;

  Offset(this._tail);
}

/**
 * Object that can read a value at a [BufferPointer].
 */
abstract class Reader<T> {
  const Reader();

  /**
   * The size of the value in bytes.
   */
  int get size;

  /**
   * Read the value at the given pointer.
   */
  T read(BufferPointer bp);

  /**
   * Read the value of the given [field] in the given [object].
   */
  T vTableGet(BufferPointer object, int field, [T defaultValue]) {
    int vTableSOffset = object._getInt32();
    BufferPointer vTable = object._advance(-vTableSOffset);
    int vTableSize = vTable._getUint16();
    int vTableFieldOffset = (1 + 1 + field) * 2;
    if (vTableFieldOffset < vTableSize) {
      int fieldOffsetInObject = vTable._getUint16(vTableFieldOffset);
      if (fieldOffsetInObject != 0) {
        BufferPointer fieldPointer = object._advance(fieldOffsetInObject);
        return read(fieldPointer);
      }
    }
    return defaultValue;
  }
}

/**
 * The reader of string values.
 */
class StringReader extends Reader<String> {
  const StringReader() : super();

  @override
  int get size => 4;

  @override
  String read(BufferPointer ref) {
    BufferPointer object = ref.derefObject();
    int length = object._getUint32();
    return UTF8
        .decode(ref._buffer.buffer.asUint8List(object._offset + 4, length));
  }
}

/**
 * An abstract reader for tables.
 */
abstract class TableReader<T extends TableReader<T>> extends Reader<T> {
  const TableReader();

  @override
  int get size => 4;

  /**
   * Return the [Reader] for reading fields of the object at [bp].
   */
  T createReader(BufferPointer bp);

  @override
  T read(BufferPointer bp) {
    bp = bp.derefObject();
    return createReader(bp);
  }
}

class _FbList<E> extends Object with ListMixin<E> implements List<E> {
  final Reader<E> elementReader;
  final BufferPointer bp;

  _FbList(this.elementReader, this.bp);

  @override
  int get length => bp._getUint32();

  @override
  void set length(int i) =>
      throw new StateError('Attempt to modify immutable list');

  @override
  E operator [](int i) {
    BufferPointer ref = bp._advance(4 + elementReader.size * i);
    return elementReader.read(ref);
  }

  @override
  void operator []=(int i, E e) =>
      throw new StateError('Attempt to modify immutable list');
}

/**
 * Class for building VTable(s).
 */
class _VTableBuilder {
  final List<int> fieldTails = <int>[];

  int get numOfUint16 => 1 + 1 + fieldTails.length;

  void addField(int field, int offset) {
    while (fieldTails.length <= field) {
      fieldTails.add(null);
    }
    fieldTails[field] = offset;
  }

  /**
   * Outputs this VTable to [buf], which is is expected to be aligned to 16-bit
   * and have at least [numOfUint16] 16-bit words available.
   */
  void output(ByteData buf, int bufOffset, int tableTail, int tableSize) {
    // VTable size.
    buf.setUint16(bufOffset, numOfUint16 * 2, Endianness.LITTLE_ENDIAN);
    bufOffset += 2;
    // Table size.
    buf.setUint16(bufOffset, tableSize, Endianness.LITTLE_ENDIAN);
    bufOffset += 2;
    // Field offsets.
    for (int fieldTail in fieldTails) {
      int fieldOffset = fieldTail == null ? 0 : tableTail - fieldTail;
      buf.setUint16(bufOffset, fieldOffset, Endianness.LITTLE_ENDIAN);
      bufOffset += 2;
    }
  }
}
