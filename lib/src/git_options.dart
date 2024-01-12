class GitOptions {
  final String? gitPath;
  final String? gitRef;
  GitOptions({this.gitPath, this.gitRef});
  String get asFragment {
    if (gitPath == null && gitRef == null) return '';
    return '#${[
      if (gitPath != null) 'path:$gitPath',
      if (gitRef != null) 'ref:$gitRef',
    ].join(',')}';
  }
}
