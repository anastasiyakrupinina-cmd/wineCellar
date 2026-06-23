import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wine_cellar/core/database/database_service.dart';
import 'package:injectable/injectable.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;

enum SyncOutcome { synced, conflict }

@lazySingleton
class UCloudSyncService {
  static const String _usernameKey = 'ucloud_username';
  static const String _passwordKey = 'ucloud_password';
  static const String _hasUnsyncedChangesKey = 'has_unsynced_changes';
  static const String _localLastWriteTimeKey = 'local_last_write_time';

  static const String _webDavHost =
      'https://ucloud.univie.ac.at/remote.php/dav/files/';
  static const String _remoteDir = 'winecellar';
  static const String _remoteFile = 'winecellar/winecellar.db';

  static String _buildWebDavBase(String username) =>
      '$_webDavHost${Uri.encodeComponent(username)}/';

  static const int _connectTimeoutMs = 30000; // 30 s
  static const int _receiveTimeoutMs = 30000; // 30 s

  
  static bool get _useSecureStorage => !Platform.isMacOS;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final DatabaseService _databaseService;

  bool _isUploading = false;

  UCloudSyncService(this._databaseService);

  Future<void> markDirty() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasUnsyncedChangesKey, true);
    await prefs.setInt(_localLastWriteTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _clearDirty() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasUnsyncedChangesKey, false);
  }

  Future<void> clearDirty() => _clearDirty();

  Future<bool> _hasUnsyncedChanges() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasUnsyncedChangesKey) ?? false;
  }

  Future<bool> hasCredentials() async {
    if (_useSecureStorage) {
      final username = await _secureStorage.read(key: _usernameKey);
      final password = await _secureStorage.read(key: _passwordKey);
      return username != null && password != null && username.isNotEmpty && password.isNotEmpty;
    } else {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString(_usernameKey);
      final password = prefs.getString(_passwordKey);
      return username != null && password != null && username.isNotEmpty && password.isNotEmpty;
    }
  }

  Future<void> saveCredentials(String username, String password) async {
    if (_useSecureStorage) {
      await _secureStorage.write(key: _usernameKey, value: username);
      await _secureStorage.write(key: _passwordKey, value: password);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_usernameKey, username);
      await prefs.setString(_passwordKey, password);
    }
  }

  
  Future<String?> getCurrentUsername() async {
    if (_useSecureStorage) {
      return _secureStorage.read(key: _usernameKey);
    } else {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_usernameKey);
    }
  }

  Future<void> signOut() async {
    if (_useSecureStorage) {
      await _secureStorage.delete(key: _usernameKey);
      await _secureStorage.delete(key: _passwordKey);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_usernameKey);
      await prefs.remove(_passwordKey);
    }
  }

 
  Future<bool> validateCredentials(String username, String password) async {
    final testClient = webdav.newClient(
      _buildWebDavBase(username),
      user: username,
      password: password,
      debug: false,
    );
    testClient.setConnectTimeout(_connectTimeoutMs);
    testClient.setReceiveTimeout(_receiveTimeoutMs);
    try {
      await testClient.readDir('/');
      return true;
    } on DioException catch (e) {
      // 401/403 = wrong credentials; anything else = network/SSL problem rethrow
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        return false;
      }
      rethrow;
    }
  }

  Future<webdav.Client?> _getClient() async {
    String? username;
    String? password;
    if (_useSecureStorage) {
      username = await _secureStorage.read(key: _usernameKey);
      password = await _secureStorage.read(key: _passwordKey);
    } else {
      final prefs = await SharedPreferences.getInstance();
      username = prefs.getString(_usernameKey);
      password = prefs.getString(_passwordKey);
    }
    if (username == null || password == null || username.isEmpty || password.isEmpty) {
      return null;
    }
    final client = webdav.newClient(
      _buildWebDavBase(username),
      user: username,
      password: password,
      debug: false,
    );
    client.setConnectTimeout(_connectTimeoutMs);
    client.setReceiveTimeout(_receiveTimeoutMs);
    return client;
  }

  /// Downloads the remote .db file and overwrites the local one, skips if the remote file does not exist yet.
  Future<void> downloadDb() async {
    try {
      final client = await _getClient();
      if (client == null) return;

      final bytes = await client.read(_remoteFile);
      final file = File(_databaseService.dbPath);
      await file.writeAsBytes(Uint8List.fromList(bytes));
    } on DioException catch (e) {
      // 404 = file not yet uploaded
      if (e.response?.statusCode == 404) return;
      // Any other network error: skip
    } catch (_) {
      // Timeout, IO error, etc. — skip
    }
  }

  /// Uploads the local .db file to u:cloud.
  /// Safe to call while the DB is open — uses WAL checkpoint instead of
  /// closing the connection, so no other operation is blocked.
  /// Concurrent calls are collapsed: if an upload is already running the new
  /// request is silently dropped (the in-flight upload already has the latest data).
  Future<void> uploadDb() async {
    if (_isUploading) return;
    if (!_databaseService.isInitialized) return;
    _isUploading = true;
    try {
      await _databaseService.db.rawQuery('PRAGMA wal_checkpoint(TRUNCATE)');

      final localFile = File(_databaseService.dbPath);
      final client = await _getClient();
      if (client == null) return;

      try {
        await client.mkdir(_remoteDir);
      } catch (_) {
        // Directory may already exist — ignore
      }

      if (!localFile.existsSync()) return;

      final bytes = await localFile.readAsBytes();
      await client.write(_remoteFile, bytes);
      await _clearDirty();
    } catch (_) {
      // Upload failure is silent — will retry on next sync
    } finally {
      _isUploading = false;
    }
  }

  /// Called on app start (both first login and returning user).
  /// Returns [SyncOutcome.conflict] when local unsynced changes are older than
  /// the remote file, ask the user which version to keep.
  Future<SyncOutcome> syncOnStart() async {
    await _databaseService.init();

    if (await _hasUnsyncedChanges()) {
      final remoteModified = await _getRemoteLastModified();
      final prefs = await SharedPreferences.getInstance();
      final localMs = prefs.getInt(_localLastWriteTimeKey);
      final localModified = localMs != null
          ? DateTime.fromMillisecondsSinceEpoch(localMs)
          : null;

      if (remoteModified != null &&
          localModified != null &&
          remoteModified.isAfter(localModified)) {
        return SyncOutcome.conflict;
      }

      await uploadDb();
      return SyncOutcome.synced;
    }

    await _databaseService.close();
    try {
      final client = await _getClient();
      if (client != null) {
        try {
          await client.mkdir(_remoteDir);
        } catch (_) {}
      }
    } catch (_) {}
    await downloadDb();
    await _databaseService.init();
    return SyncOutcome.synced;
  }

  /// Downloads the remote file and reopens the DB, discarding any local unsynced changes.
  Future<void> resolveWithRemote() async {
    await _clearDirty();
    await _databaseService.close();
    await downloadDb();
    await _databaseService.init();
  }

  Future<DateTime?> _getRemoteLastModified() async {
    try {
      final client = await _getClient();
      if (client == null) return null;
      final files = await client.readDir(_remoteDir);
      for (final f in files) {
        if (f.name == 'winecellar.db') return f.mTime;
      }
    } catch (_) {}
    return null;
  }

  
  Future<void> syncAfterWrite() async {
    await markDirty();
    await uploadDb();
  }

}
