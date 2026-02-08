import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

/// Service responsible for Google Drive authentication and file operations.
class DriveService {
  static const _backupFolderName = 'deutschi_backups';
  static const _backupFileName = 'deutschi_backup.json';

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: [drive.DriveApi.driveFileScope]);

  GoogleSignInAccount? _currentUser;
  drive.DriveApi? _driveApi;

  /// Returns true if user is currently signed in.
  bool get isSignedIn => _currentUser != null;

  /// Signs in the user with Google.
  Future<bool> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      if (_currentUser != null) {
        await _initDriveApi();
        return true;
      }
      return false;
    } catch (e) {
      print('Google Sign-In error: $e');
      return false;
    }
  }

  /// Signs in silently (for background tasks).
  Future<bool> signInSilently() async {
    try {
      _currentUser = await _googleSignIn.signInSilently();
      if (_currentUser != null) {
        await _initDriveApi();
        return true;
      }
      return false;
    } catch (e) {
      print('Silent sign-in error: $e');
      return false;
    }
  }

  /// Signs out the user.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    _driveApi = null;
  }

  /// Initializes the Drive API with authenticated client.
  Future<void> _initDriveApi() async {
    if (_currentUser == null) return;

    final authHeaders = await _currentUser!.authHeaders;
    final authenticatedClient = _GoogleAuthClient(authHeaders);
    _driveApi = drive.DriveApi(authenticatedClient);
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

      final fileMetadata = drive.File()
        ..name = _backupFileName
        ..parents = [folderId];

      final mediaContent = drive.Media(Stream.value(utf8.encode(jsonContent)), utf8.encode(jsonContent).length);

      if (existingFileId != null) {
        // Update existing file
        await _driveApi!.files.update(fileMetadata, existingFileId, uploadMedia: mediaContent);
      } else {
        // Create new file
        await _driveApi!.files.create(fileMetadata, uploadMedia: mediaContent);
      }

      return true;
    } catch (e) {
      print('Upload error: $e');
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
      print('Download error: $e');
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
      print('Folder error: $e');
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
      print('File search error: $e');
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
