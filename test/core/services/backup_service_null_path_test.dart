import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:file_picker/file_picker.dart';
import 'package:imyra_app/core/services/backup_service.dart';
import 'package:imyra_app/core/database/app_database.dart';
import 'package:drift/native.dart';

base class MockPlatformFile extends PlatformFile {
  @override
  final String name;
  @override
  final String? path;

  MockPlatformFile({
    required this.name,
    this.path,
  });

  @override
  Future<int> length() async => 0;

  @override
  Stream<Uint8List> readAsByteStream() => throw UnimplementedError();

  @override
  Future<Uint8List> readAsBytes() async => Uint8List(0);

  @override
  Uri get uri => Uri.parse(path ?? '');

  @override
  get xFile => throw UnimplementedError();
}

void main() {
  group('BackupService Null Path Guard Tests', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('restoreEncryptedBackup throws FormatException when file name is invalid', () async {
      final file = MockPlatformFile(
        name: 'test_backup.txt', // not ending in .imyrabackup
        path: '/tmp/test_backup.txt',
      );

      expect(
        () => BackupService.restoreEncryptedBackup(db, file, 'passphrase123'),
        throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('Invalid file type'))),
      );
    });

    test('restoreEncryptedBackup throws FormatException when file.path is null', () async {
      final file = MockPlatformFile(
        name: 'my_backup.imyrabackup',
        path: null, // picked from Google Drive / Cloud storage directly
      );

      expect(
        () => BackupService.restoreEncryptedBackup(db, file, 'passphrase123'),
        throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('Could not read the selected file'))),
      );
    });
  });
}
