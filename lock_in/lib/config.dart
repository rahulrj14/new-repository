/// Test tools (fake lock/unlock, time warp). Compiled in only when built with
/// `--dart-define=LOCKIN_DEBUG_TOOLS=true`; otherwise this constant is false
/// and the debug UI is tree-shaken out of the build entirely.
const kDebugTools = bool.fromEnvironment('LOCKIN_DEBUG_TOOLS');

/// Play Store page. Used for the "get the app" QR in the squad lobby.
/// Opening it only hands the link to the phone's browser / Play Store app;
/// Lock In itself still has no internet access.
const kPlayUrl =
    'https://play.google.com/store/apps/details?id=app.lockin.android';

/// Optional feedback form (e.g. a Google Form). Empty = the link is hidden.
const kFeedbackUrl = '';

/// Public privacy policy page. Empty = the link is hidden.
const kPrivacyUrl = '';
