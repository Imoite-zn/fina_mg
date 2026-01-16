// Stub implementations for web platform
// These are never actually called on web, but needed for compilation

class Permission {
  static Permission get storage => Permission();

  Future<PermissionStatus> get status async => PermissionStatus();
  Future<PermissionStatus> request() async => PermissionStatus();
}

class PermissionStatus {
  bool get isGranted => false;
}

Future<Directory> getApplicationDocumentsDirectory() async {
  throw UnsupportedError('Not supported on web');
}

// File and Directory stubs
class File {
  File(String path);

  String readAsStringSync() {
    throw UnsupportedError('File operations not supported on web');
  }

  Future<void> writeAsString(String contents) async {
    throw UnsupportedError('File operations not supported on web');
  }

  String get path => '';
}

class Directory {
  Directory(String path);

  String get path => '';

  Future<Directory> create({bool recursive = false}) async {
    return this;
  }
}

class Platform {
  static bool get isAndroid => false;
  static bool get isWindows => false;
}
