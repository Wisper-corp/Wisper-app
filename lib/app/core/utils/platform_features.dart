import 'dart:io' show Platform;

/// Whether the wallet is offered on this build.
///
/// Hidden on iOS while the app goes through App Store review, and left alone
/// everywhere else — Android is unchanged.
///
/// Kept here rather than inline so the rule cannot drift: every screen that
/// shows or hides the wallet asks the same question.
///
/// A platform check rather than a remote switch, on purpose. A feature shipped
/// hidden and then turned on from a server after approval is what App Store
/// guideline 2.3.1 forbids; a path the binary never takes on iOS is not that.
bool get walletEnabled => !Platform.isIOS;
