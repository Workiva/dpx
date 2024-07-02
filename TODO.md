# TODO

## Unit Tests
- [x] Package Spec parsing. Should cover:
  - [x] `lib/src/package_spec_scanner.dart`
  - [x] `lib/src/package_spec.dart`
  - [x] `lib/src/pub_package_spec.dart`
  - [x] `lib/src/git_package_spec.dart`
- [ ] `lib/src/args.dart`
- [ ] `lib/src/ensure_process_exit.dart`
- [ ] `lib/src/find_active_global_package.dart`
- [ ] `lib/src/find_reusable_package.dart`
- [ ] `lib/src/get_system_cache_path.dart`
- [ ] `lib/src/global_activate_package.dart`
- [ ] `lib/src/list_active_global_packages.dart`
- [ ] `lib/src/resolve_latest_git_ref.dart`

## End-to-end Tests
Should run the `dpx` executable to cover these use cases:

- [ ] Installing from:
  - [ ] pub
  - [ ] pub with version constraint
  - [ ] custom pub (use the public pub, but explicitly specify the URL)
  - [ ] github repo (https)
  - [ ] github repo (ssh)
  - [ ] github repo at ref
  - [ ] github repo at subpath
  - [ ] github repo at ref and subpath
- [ ] Executing specific package executable with args
- [ ] Executing non-package executable with args
