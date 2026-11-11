/// Test tools (fake lock/unlock, time warp). Compiled in only when built with
/// `--dart-define=LOCKIN_DEBUG_TOOLS=true`; otherwise this constant is false
/// and the debug UI is tree-shaken out of the build entirely.
const kDebugTools = bool.fromEnvironment('LOCKIN_DEBUG_TOOLS');
