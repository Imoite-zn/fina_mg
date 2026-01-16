// Stub File class for web platform compatibility
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
