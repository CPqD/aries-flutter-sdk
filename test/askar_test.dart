// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:import_so_libaskar/askar/askar_callbacks.dart';
import 'package:import_so_libaskar/askar/askar_wrapper.dart';
import 'package:import_so_libaskar/askar/enums/askar_entry_operation.dart';
import 'package:import_so_libaskar/askar/enums/askar_error_code.dart';
import 'package:import_so_libaskar/askar/enums/askar_key_algorithm.dart';
import 'package:import_so_libaskar/askar/enums/askar_key_backend.dart';
import 'package:import_so_libaskar/askar/enums/askar_signature_algorithm.dart';
import 'package:import_so_libaskar/askar/enums/askar_store_key_method.dart';

void main() {
  group('Askar Tests', () {
    late int storeHandle;
    late int sessionHandle;

    setUpAll(() async {
      final result = askarVersion();
      print(result);
      expect(result, equals('0.3.2'));

      await storeProvisionTest();

      final storeOpenResult = await storeOpenTest();
      storeHandle = storeOpenResult.handle;
    });

    tearDownAll(() async {
      await storeCloseTest(storeHandle);
    });

    setUp(() async {
      final sessionStartResult = await sessionStartTest(storeHandle);
      sessionHandle = sessionStartResult.handle;
    });

    tearDown(() async {
      await sessionCloseTest(sessionHandle);
    });

    test('Attempt to read from an unexisting category', () async {
      await sessionFetchTest(sessionHandle, expectSuccess: false);
    });

    test('Writing and reading from session', () async {
      String value = 'foobar';
      String name = 'testEntry';
      String category = 'category-one';
      Map<String, String> tags = {'~plaintag': 'a', 'enctag': 'b'};

      await sessionUpdateTest(
          sessionHandle, EntryOperation.insert, value, tags, name, category);

      await sessionCountTest(sessionHandle, category, tags);

      final sessionFetchResult = await sessionFetchTest(sessionHandle);
      final entryListHandle = sessionFetchResult.handle;

      entryListGetValueTest(entryListHandle, 0, expectedValue: value);
      entryListGetTagsTest(entryListHandle, 0, expectedTags: tags);
      entryListGetNameTest(entryListHandle, 0, expectedName: name);
      entryListGetCategoryTest(entryListHandle, 0, expectedCategory: category);

      askarEntryListFree(entryListHandle);
    });

    test('Inserting and reading Key', () async {
      String name = 'testEntry2';
      String metadata = 'meta';
      Map<String, String> tags = {'~plaintag': 'a', 'enctag': 'b'};

      final keyGenerateResult =
          keyGenerateTest(KeyAlgorithm.ed25519, KeyBackend.software);

      final localKeyHandle = keyGenerateResult.value;

      await sessionInsertKeyTest(sessionHandle, localKeyHandle, name, metadata, tags);

      final fetchKeyResult = await sessionFetchKeyTest(sessionHandle, name);
      final keyEntryListHandle = fetchKeyResult.handle;

      keyEntryListGetMetadataTest(keyEntryListHandle, 0, metadata);
      keyEntryListGetNameTest(keyEntryListHandle, 0, expectedValue: name);
      keyEntryListGetTagsTest(keyEntryListHandle, 0, expectedValue: tags);

      askarKeyEntryListFree(keyEntryListHandle);
      askarKeyFree(localKeyHandle);

      await expectLater(
          () => keyEntryListGetMetadataTest(fetchKeyResult.handle, 0, metadata),
          throwsA(isA<Exception>()),
          reason:
              "Trying to read from keyEntryList after freeing should cause an exception");
    });

    test('Sign Message and Verify Signature', () async {
      final keyGenerateResult =
          keyGenerateTest(KeyAlgorithm.ed25519, KeyBackend.software);

      final localKeyHandle = keyGenerateResult.value;

      keyGetAlgorithmTest(localKeyHandle, expectedValue: KeyAlgorithm.ed25519.value);

      final message = utf8.encode("This is a message!");
      final otherMessage = utf8.encode("This is another message!");

      final signAlgorithm = SignatureAlgorithm.edDSA;

      final signResult = keySignMessageTest(localKeyHandle, message, signAlgorithm);

      keyVerifySignatureTest(localKeyHandle, message, signResult.value, signAlgorithm);

      keyVerifySignatureTest(
          localKeyHandle, otherMessage, signResult.value, signAlgorithm,
          expectSuccess: false);
    });

    test('Removing Key', () async {
      final keyGenerateResult =
          keyGenerateTest(KeyAlgorithm.ed25519, KeyBackend.software);
      final localKeyHandle = keyGenerateResult.value;
      String name = 'testEntry3';
      String metadata = 'meta';
      Map<String, String> tags = {'~plaintag': 'a', 'enctag': 'b'};

      await sessionInsertKeyTest(sessionHandle, localKeyHandle, name, metadata, tags);

      final fetchKeyResult =
          await sessionFetchKeyTest(sessionHandle, name, expectSuccess: true);

      await sessionRemoveKeyTest(sessionHandle, name);

      await sessionFetchKeyTest(sessionHandle, name, expectSuccess: false);

      keyEntryListCountTest(fetchKeyResult.handle, expectedValue: 0);
    });
  });
}

Future<CallbackResult> storeProvisionTest() async {
  final String specUri = 'sqlite://storage.db';
  final String passKey = 'mySecretKey';
  final String profile = 'rekey';
  final bool recreate = true;

  final result = await askarStoreProvision(
      specUri, StoreKeyMethod.argon2IMod, passKey, profile, recreate);

  printResult('StoreProvision', result);

  expect(result.errorCode, equals(ErrorCode.success));
  expect(result.finished, equals(true));

  return result;
}

Future<CallbackResult> storeOpenTest() async {
  final String specUri = 'sqlite://storage.db';
  final String passKey = 'mySecretKey';
  final String profile = 'rekey';

  final result =
      await askarStoreOpen(specUri, StoreKeyMethod.argon2IMod, passKey, profile);

  printResult('StoreOpen', result);

  expect(result.errorCode, equals(ErrorCode.success));
  expect(result.finished, equals(true));

  return result;
}

Future<CallbackResult> sessionStartTest(int handle) async {
  String profile = 'rekey';
  bool asTransaction = true;

  final result = await askarSessionStart(handle, profile, asTransaction);

  printResult('SessionStart', result);

  expect(result.errorCode, equals(ErrorCode.success));
  expect(result.finished, equals(true));

  return result;
}

AskarResult<int> keyGenerateTest(KeyAlgorithm algorithm, KeyBackend keyBackend) {
  bool ephemeral = false;

  final result = askarKeyGenerate(algorithm, keyBackend, ephemeral);

  printAskarResult('KeyGenerate', result);

  expect(result.errorCode, equals(ErrorCode.success));
  expect(result.value, greaterThan(0));

  return result;
}

AskarResult<String> keyGetAlgorithmTest(int localKeyHandle,
    {required String expectedValue}) {
  final result = askarKeyGetAlgorithm(localKeyHandle);

  printAskarResult('KeyGetAlgorithm', result);
  expect(result.errorCode, ErrorCode.success);
  expect(result.value, expectedValue);

  return result;
}

AskarResult<String> keyEntryListGetNameTest(int keyEntryListHandle, int index,
    {required String expectedValue}) {
  final result = askarKeyEntryListGetName(keyEntryListHandle, index);

  printAskarResult('KeyEntryListGetName', result);
  expect(result.errorCode, ErrorCode.success);
  expect(result.value, expectedValue);

  return result;
}

AskarResult<Map> keyEntryListGetTagsTest(int keyEntryListHandle, int index,
    {required Map<dynamic, dynamic> expectedValue}) {
  final result = askarKeyEntryListGetTags(keyEntryListHandle, index);

  printAskarResult('KeyEntryListGetTags', result);
  expect(result.errorCode, ErrorCode.success);
  expect(result.value, expectedValue);

  return result;
}

AskarResult<int> entryListCountTest(int entryListHandle, {required int expectedValue}) {
  final result = askarEntryListCount(entryListHandle);

  printAskarResult('EntryListCount', result);

  expect(result.errorCode, equals(ErrorCode.success));
  expect(result.value, equals(expectedValue));

  return result;
}

AskarResult<int> keyEntryListCountTest(int keyEntryListHandle,
    {required int expectedValue}) {
  final result = askarKeyEntryListCount(keyEntryListHandle);

  printAskarResult('KeyEntryListCount', result);

  expect(result.errorCode, equals(ErrorCode.success));
  expect(result.value, equals(expectedValue));

  return result;
}

Future<CallbackResult> sessionInsertKeyTest(int sessionHandle, int localKeyHandle,
    String name, String metadata, Map<String, String> tags) async {
  int expiryMs = 2000;

  final result = await askarSessionInsertKey(
      sessionHandle, localKeyHandle, name, metadata, tags, expiryMs);

  printResult('SessionInsertKey', result);

  expect(result.errorCode, equals(ErrorCode.success));
  expect(result.finished, equals(true));

  return result;
}

Future<CallbackResult> sessionRemoveKeyTest(int sessionHandle, String name) async {
  final result = await askarSessionRemoveKey(sessionHandle, name);

  printResult('SessionRemoveKey', result);

  expect(result.errorCode, equals(ErrorCode.success));
  expect(result.finished, equals(true));

  return result;
}

Future<CallbackResult> sessionCountTest(
    int sessionHandle, String category, Map<String, String> tagFilter) async {
  final result = await askarSessionCount(sessionHandle, category, tagFilter);

  printResult('SessionCount', result);

  expect(result.errorCode, equals(ErrorCode.success));
  expect(result.finished, equals(true));
  expect(result.handle, greaterThan(0));

  return result;
}

Future<CallbackResult> sessionFetchKeyTest(int sessionHandle, String name,
    {bool expectSuccess = true}) async {
  bool forUpdate = false;

  final result = await askarSessionFetchKey(sessionHandle, name, forUpdate);

  printResult('SessionFetchKey', result);

  expect(result.errorCode, equals(ErrorCode.success));
  expect(result.finished, equals(true));

  if (expectSuccess) {
    expect(result.handle, greaterThan(0));
  } else {
    expect(result.handle, equals(0));
  }

  return result;
}

AskarResult<String> keyEntryListGetMetadataTest(
    int keyEntryListHandle, int index, String expectedMetadata) {
  final result = askarKeyEntryListGetMetadata(keyEntryListHandle, index);

  printAskarResult('KeyEntryListGetMetadata', result);

  expect(result.errorCode, equals(ErrorCode.success));
  expect(result.value, equals(expectedMetadata));

  return result;
}

Future<CallbackResult> sessionUpdateTest(int handle, EntryOperation operation,
    String value, Map<String, String> tags, String name, String category) async {
  int expiryMs = 2000;

  final result =
      await askarSessionUpdate(handle, operation, category, name, value, tags, expiryMs);

  printResult('SessionUpdate', result);

  expect(result.errorCode, equals(ErrorCode.success));
  expect(result.finished, equals(true));

  return result;
}

Future<CallbackResult> sessionFetchTest(int handle, {bool expectSuccess = true}) async {
  String category = 'category-one';
  String name = 'testEntry';
  bool forUpdate = false;

  CallbackResult result = CallbackResult(ErrorCode.custom, -1, false);

  if (expectSuccess) {
    result = await askarSessionFetch(handle, category, name, forUpdate);
    expect(result.errorCode, equals(ErrorCode.success));
    expect(result.finished, equals(true));
    expect(result.handle, isNot(0));
  } else {
    await expectLater(
      () async => {result = await askarSessionFetch(handle, category, name, forUpdate)},
      throwsA(isA<Exception>()),
    );
  }

  printResult('SessionFetch', result);

  return result;
}

AskarResult<String> entryListGetValueTest(int entryListHandle, int index,
    {required String expectedValue}) {
  final result = askarEntryListGetValue(entryListHandle, index);

  printAskarResult('EntryListGetValue', result);

  expect(result.errorCode, equals(ErrorCode.success));
  expect(result.value, equals(expectedValue));

  return result;
}

AskarResult<Map> entryListGetTagsTest(int entryListHandle, int index,
    {required Map expectedTags}) {
  final result = askarEntryListGetTags(entryListHandle, index);

  printAskarResult('EntryListGetTags', result);

  expect(result.errorCode, equals(ErrorCode.success));
  expect(result.value, equals(expectedTags));

  return result;
}

AskarResult<String> entryListGetNameTest(int entryListHandle, int index,
    {required String expectedName}) {
  final result = askarEntryListGetName(entryListHandle, index);

  printAskarResult('EntryListGetName', result);

  expect(result.errorCode, equals(ErrorCode.success));
  expect(result.value, equals(expectedName));

  return result;
}

AskarResult<String> entryListGetCategoryTest(int entryListHandle, int index,
    {required String expectedCategory}) {
  final result = askarEntryListGetCategory(entryListHandle, index);

  printAskarResult('EntryListGetCategory', result);

  expect(result.errorCode, equals(ErrorCode.success));
  expect(result.value, equals(expectedCategory));

  return result;
}

AskarResult<Uint8List> keySignMessageTest(
    int localKeyHandle, Uint8List message, SignatureAlgorithm sigType) {
  final result = askarKeySignMessage(localKeyHandle, message, sigType);

  printAskarResult('KeySignMessage', result);

  expect(result.errorCode, equals(ErrorCode.success));
  expect(result.value, isNot(message));

  return result;
}

AskarResult<bool> keyVerifySignatureTest(int localKeyHandle, Uint8List message,
    Uint8List signature, SignatureAlgorithm sigType,
    {bool expectSuccess = true}) {
  final result = askarKeyVerifySignature(localKeyHandle, message, signature, sigType);

  printAskarResult('KeyVerifySignature', result);

  expect(result.errorCode, equals(ErrorCode.success));
  expect(result.value, equals(expectSuccess));

  return result;
}

Future<CallbackResult> sessionCloseTest(int handle) async {
  final result = await askarSessionClose(handle, true);

  printResult('SessionClose', result);

  expect(result.errorCode, equals(ErrorCode.success));
  expect(result.finished, equals(true));

  return result;
}

Future<CallbackResult> storeCloseTest(int handle) async {
  final result = await askarStoreClose(handle);

  printResult('StoreClose', result);

  expect(result.errorCode, equals(ErrorCode.success));
  expect(result.finished, equals(true));

  return result;
}

void printResult(String test, CallbackResult result) {
  if (result.handle == -1) {
    print('$test Result: (${result.errorCode}, Finished: ${result.finished})\n');
  } else {
    print(
        '$test Result: (${result.errorCode}, Handle: ${result.handle}, Finished: ${result.finished})\n');
  }
}

void printAskarResult(String test, AskarResult result) {
  print('$test Result: (${result.errorCode}, Value: ${result.value})\n');
}
