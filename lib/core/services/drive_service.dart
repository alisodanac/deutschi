import 'dart:convert';
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Service responsible for Google Drive authentication and file operations.
class DriveService {
  static const _backupFolderName = 'deutschi_backups';
  static const _backupFileName = 'deutschi_backup.json';

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: [drive.DriveApi.driveFileScope]);

  GoogleSignInAccount? _currentUser;
  drive.DriveApi? _driveApi;

  /// Returns true if user is currently signed in.
  bool get isSignedIn => _currentUser != null && _driveApi != null;

  /// Signs in the user with Google.
  Future<bool> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      if (_currentUser == null) {
        debugPrint('Google Sign-In canceled by user or failed');
        return false;
      }

      debugPrint('Google Sign-In successful: ${_currentUser!.email}');

      // On iOS, scopes are granted at sign-in time, so canAccessScopes
      // may return false inappropriately. We try to initialize the API
      // directly and treat that as the definitive test.
      if (!Platform.isIOS) {
        bool hasScopes = await _googleSignIn.canAccessScopes([drive.DriveApi.driveFileScope]);
        if (!hasScopes) {
          debugPrint('Required scopes not granted, requesting...');
          final granted = await _googleSignIn.requestScopes([drive.DriveApi.driveFileScope]);
          if (!granted) {
            debugPrint('Scopes not granted by user');
            return false;
          }
        }
      }

      await _initDriveApi();

      // Verify the connection actually works by making a small API call
      final verified = await _verifyConnection();
      if (!verified) {
        debugPrint('Drive API verification failed');
        _driveApi = null;
        return false;
      }

      debugPrint('Google Drive connected successfully');
      return true;
    } catch (e, stack) {
      debugPrint('Google Sign-In error: $e');
      debugPrint('Stack trace: $stack');
      _currentUser = null;
      _driveApi = null;
      return false;
    }
  }

  /// Signs in silently (for background tasks or app startup).
  Future<bool> signInSilently() async {
    try {
      _currentUser = await _googleSignIn.signInSilently();
      if (_currentUser == null) {
        return false;
      }

      await _initDriveApi();
      return _driveApi != null;
    } catch (e) {
      debugPrint('Silent sign-in error: $e');
      _currentUser = null;
      _driveApi = null;
      return false;
    }
  }

  /// Signs out the user.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
    _currentUser = null;
    _driveApi = null;
  }

  /// Initializes the Drive API with authenticated client.
  Future<void> _initDriveApi() async {
    if (_currentUser == null) return;

    try {
      final authHeaders = await _currentUser!.authHeaders;
      if (authHeaders.isEmpty) {
        debugPrint('Error: authHeaders is empty');
        _driveApi = null;
        return;
      }
      final authenticatedClient = _GoogleAuthClient(authHeaders);
      _driveApi = drive.DriveApi(authenticatedClient);
    } catch (e) {
      debugPrint('Error initializing Drive API: $e');
      _driveApi = null;
    }
  }

  /// Verifies the Drive API connection works by listing files.
  Future<bool> _verifyConnection() async {
    if (_driveApi == null) return false;
    try {
      // A simple call to verify connectivity - list 1 file
      await _driveApi!.files.list(pageSize: 1, spaces: 'drive');
      return true;
    } catch (e) {
      debugPrint('Drive API verification error: $e');
      return false;
    }
  }

  /// Uploads backup JSON string to Google Drive.
  Future<bool> uploadBackup(String jsonContent) async {
    if (_driveApi == null) {
      final signedIn = await signInSilently();
      if (!signedIn) return false;
    }

    try {
      // Create or get the backup folder
      final folderId = await _getOrCreateFolder();
      if (folderId == null) return false;

      // Check if backup file already exists
      final existingFileId = await _getExistingBackupFileId(folderId);

      final bytes = utf8.encode(jsonContent);
      final mediaContent = drive.Media(Stream.value(bytes), bytes.length);

      if (existingFileId != null) {
        // Update existing file (don't set parents on update)
        final fileMetadata = drive.File()..name = _backupFileName;
        await _driveApi!.files.update(fileMetadata, existingFileId, uploadMedia: mediaContent);
      } else {
        // Create new file
        final fileMetadata = drive.File()
          ..name = _backupFileName
          ..parents = [folderId];
        await _driveApi!.files.create(fileMetadata, uploadMedia: mediaContent);
      }

      debugPrint('Backup uploaded successfully');
      return true;
    } catch (e) {
      debugPrint('Upload error: $e');
      // If auth error, try to re-authenticate and retry once
      if (e.toString().contains('401') || e.toString().contains('403')) {
        debugPrint('Auth error detected, trying to re-authenticate...');
        _driveApi = null;
        final signedIn = await signInSilently();
        if (signedIn) {
          return _retryUpload(jsonContent);
        }
      }
      return false;
    }
  }

  /// Retry upload after re-authentication.
  Future<bool> _retryUpload(String jsonContent) async {
    try {
      final folderId = await _getOrCreateFolder();
      if (folderId == null) return false;

      final existingFileId = await _getExistingBackupFileId(folderId);
      final bytes = utf8.encode(jsonContent);
      final mediaContent = drive.Media(Stream.value(bytes), bytes.length);

      if (existingFileId != null) {
        final fileMetadata = drive.File()..name = _backupFileName;
        await _driveApi!.files.update(fileMetadata, existingFileId, uploadMedia: mediaContent);
      } else {
        final fileMetadata = drive.File()
          ..name = _backupFileName
          ..parents = [folderId];
        await _driveApi!.files.create(fileMetadata, uploadMedia: mediaContent);
      }
      return true;
    } catch (e) {
      debugPrint('Retry upload error: $e');
      return false;
    }
  }

  /// Downloads the latest backup from Google Drive.
  Future<String?> downloadBackup() async {
    if (_driveApi == null) {
      final signedIn = await signInSilently();
      if (!signedIn) return null;
    }

    try {
      final folderId = await _getOrCreateFolder();
      if (folderId == null) return null;

      final existingFileId = await _getExistingBackupFileId(folderId);
      if (existingFileId == null) return null;

      final response =
          await _driveApi!.files.get(existingFileId, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;

      final List<int> bytes = [];
      await for (var chunk in response.stream) {
        bytes.addAll(chunk);
      }

      return utf8.decode(bytes);
    } catch (e) {
      debugPrint('Download error: $e');
      return null;
    }
  }

  /// Gets or creates the backup folder in Drive.
  Future<String?> _getOrCreateFolder() async {
    try {
      // Search for existing folder
      final response = await _driveApi!.files.list(
        q: "name='$_backupFolderName' and mimeType='application/vnd.google-apps.folder' and trashed=false",
        spaces: 'drive',
      );

      if (response.files != null && response.files!.isNotEmpty) {
        return response.files!.first.id;
      }

      // Create new folder
      final folderMetadata = drive.File()
        ..name = _backupFolderName
        ..mimeType = 'application/vnd.google-apps.folder';

      final folder = await _driveApi!.files.create(folderMetadata);
      return folder.id;
    } catch (e) {
      debugPrint('Folder error: $e');
      return null;
    }
  }

  /// Gets the ID of the existing backup file in the folder.
  Future<String?> _getExistingBackupFileId(String folderId) async {
    try {
      final response = await _driveApi!.files.list(
        q: "name='$_backupFileName' and '$folderId' in parents and trashed=false",
        spaces: 'drive',
      );

      if (response.files != null && response.files!.isNotEmpty) {
        return response.files!.first.id;
      }
      return null;
    } catch (e) {
      debugPrint('File search error: $e');
      return null;
    }
  }
}

/// HTTP client wrapper that adds authorization headers.
class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}
