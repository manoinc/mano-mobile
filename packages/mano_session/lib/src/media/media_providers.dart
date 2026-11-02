import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

import '../offline_marketplace_provider.dart';
import '../session_providers.dart';

/// Offline store shared by the mock uploader and the mock chat.
final mockMediaLibraryProvider = Provider((ref) => MockMediaLibrary());

final mediaPickerProvider = Provider<MediaPicker>(
  (ref) => ImagePickerMediaPicker(),
);

// Live for chat and avatar; project and portfolio photos stay mocked until the gateway has kinds.
final mediaUploaderProvider = Provider<MediaUploader>((ref) {
  final mock = MockMediaUploader(library: ref.watch(mockMediaLibraryProvider));
  if (ref.watch(offlineMarketplaceProvider)) return mock;
  return GatewayMediaUploader(
    ref.watch(gatewayTransportProvider),
    unsupported: mock,
  );
});
