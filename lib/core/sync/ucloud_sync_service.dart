import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:home_wine/core/database/database_service.dart';
import 'package:injectable/injectable.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;

@lazySingleton
class UCloudSyncService {
  static const String _usernameKey = 'ucloud_username';
  static const String _passwordKey = 'ucloud_password';

  static const String _webDavBase =
      'https://ucloud.univie.ac.at/remote.php/dav/files/krupininaa00%40univie.ac.at/';
  static const String _remoteDir = 'winecellar';
  static const String _remoteFile = 'winecellar/winecellar.db';

  static const int _connectTimeoutMs = 10000; // 10 s
  static const int _receiveTimeoutMs = 30000; // 30 s

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final DatabaseService _databaseService;

  bool _isUploading = false;

  UCloudSyncService(this._databaseService);

  Future<bool> hasCredentials() async {
    final username = await _secureStorage.read(key: _usernameKey);
    final password = await _secureStorage.read(key: _passwordKey);
    return username != null && password != null && username.isNotEmpty && password.isNotEmpty;
  }

  Future<void> saveCredentials(String username, String password) async {
    await _secureStorage.write(key: _usernameKey, value: username);
    await _secureStorage.write(key: _passwordKey, value: password);
  }

  /// Returns the stored username (full university email), or null if not set.
  Future<String?> getCurrentUsername() async {
    return _secureStorage.read(key: _usernameKey);
  }

  /// Clears stored credentials — effectively signs the user out.
  Future<void> signOut() async {
    await _secureStorage.delete(key: _usernameKey);
    await _secureStorage.delete(key: _passwordKey);
  }

  /// Validates credentials by making a real WebDAV request.
  /// Returns true if the server accepts them, false on 401 or any error.
  Future<bool> validateCredentials(String username, String password) async {
    if (kIsWeb) return false;
    try {
      final testClient = webdav.newClient(
        _webDavBase,
        user: username,
        password: password,
        debug: false,
      );
      testClient.setConnectTimeout(_connectTimeoutMs);
      testClient.setReceiveTimeout(_receiveTimeoutMs);
      await testClient.readDir('/');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<webdav.Client?> _getClient() async {
    final username = await _secureStorage.read(key: _usernameKey);
    final password = await _secureStorage.read(key: _passwordKey);
    if (username == null || password == null || username.isEmpty || password.isEmpty) {
      return null;
    }
    final client = webdav.newClient(
      _webDavBase,
      user: username,
      password: password,
      debug: false,
    );
    client.setConnectTimeout(_connectTimeoutMs);
    client.setReceiveTimeout(_receiveTimeoutMs);
    return client;
  }

  /// Downloads the remote .db file and overwrites the local one.
  /// Silently skips if the remote file does not exist yet (404) or network fails.
  Future<void> downloadDb() async {
    if (kIsWeb) return;
    try {
      final client = await _getClient();
      if (client == null) return;

      final bytes = await client.read(_remoteFile);
      final file = File(_databaseService.dbPath);
      await file.writeAsBytes(Uint8List.fromList(bytes));
    } on DioException catch (e) {
      // 404 = file not yet uploaded — silently skip on first launch
      if (e.response?.statusCode == 404) return;
      // Any other network error: silently skip
    } catch (_) {
      // Timeout, IO error, etc. — silently skip
    }
  }

  /// Uploads the local .db file to u:cloud.
  /// Safe to call while the DB is open — uses WAL checkpoint instead of
  /// closing the connection, so no other operation is blocked.
  /// Concurrent calls are collapsed: if an upload is already running the new
  /// request is silently dropped (the in-flight upload already has the latest data).
  Future<void> uploadDb() async {
    if (kIsWeb) return;
    if (_isUploading) {
      print('[UCloud] uploadDb() skipped: already uploading');
      return;
    }
    if (!_databaseService.isInitialized) {
      print('[UCloud] uploadDb() skipped: DB not initialised');
      return;
    }
    _isUploading = true;
    print('[UCloud] uploadDb() called');
    try {
      // Flush any WAL frames into the main .db file so the file we read is
      // fully up-to-date without having to close the connection.
      await _databaseService.db.rawQuery('PRAGMA wal_checkpoint(TRUNCATE)');

      final localPath = _databaseService.dbPath;
      final localFile = File(localPath);
      print('[UCloud] local path: $localPath');
      print('[UCloud] file exists: ${localFile.existsSync()}');
      if (localFile.existsSync()) {
        print('[UCloud] file size: ${await localFile.length()} bytes');
      }

      final client = await _getClient();
      if (client == null) {
        print('[UCloud] upload FAILED: no credentials');
        return;
      }

      try {
        await client.mkdir(_remoteDir);
      } catch (_) {
        // Directory may already exist — ignore
      }

      if (!localFile.existsSync()) return;

      final bytes = await localFile.readAsBytes();
      await client.write(_remoteFile, bytes);
      print('[UCloud] upload SUCCESS');
    } catch (e, stack) {
      print('[UCloud] upload FAILED: $e');
      print(stack);
    } finally {
      _isUploading = false;
    }
  }

  /// Called on app start (both first login and returning user).
  /// Resolves the DB path, downloads the remote file if it exists, then opens the DB.
  Future<void> syncOnStart() async {
    if (kIsWeb) return;
    // init() resolves _dbPath (idempotent if already open).
    // Without this, downloadDb() throws StateError on first login after a
    // fresh install because _dbPath is null until init() runs at least once.
    await _databaseService.init();
    // close() flushes the DB and releases the file lock so downloadDb() can
    // safely overwrite it on disk.
    await _databaseService.close();
    try {
      final client = await _getClient();
      if (client != null) {
        try {
          await client.mkdir(_remoteDir);
        } catch (_) {
          // Directory may already exist — ignore
        }
      }
    } catch (_) {
      // Network unavailable — proceed to download attempt anyway
    }
    await downloadDb(); // 404 or network error → silent skip, local file untouched
    await _databaseService.init();
  }

  /// Called when the app goes to background or becomes inactive.
  Future<void> syncOnClose() async {
    if (kIsWeb) return;
    await uploadDb();
  }
}
