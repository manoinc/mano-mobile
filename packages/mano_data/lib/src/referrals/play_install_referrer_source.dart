import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mano_domain/mano_domain.dart';
import 'package:play_install_referrer/play_install_referrer.dart';

/// Play's install referrer on Android; null on iOS or without Play services.
final class PlayInstallReferrerSource implements InstallReferrerSource {
  PlayInstallReferrerSource({bool? isAndroid})
    : _isAndroid = isAndroid ?? defaultTargetPlatform == TargetPlatform.android;

  final bool _isAndroid;

  @override
  Future<String?> referrer() async {
    if (!_isAndroid) return null;
    try {
      return (await PlayInstallReferrer.installReferrer).installReferrer;
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
