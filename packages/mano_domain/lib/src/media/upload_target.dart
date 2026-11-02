const _mib = 1024 * 1024;

/// What an upload is for; it decides the kind, the access rules and the cap.
sealed class UploadTarget {
  const UploadTarget();

  /// The largest file the media service keeps for this target.
  int get maxBytes;
}

/// A photo attached to a chat message.
final class ChatUpload extends UploadTarget {
  const ChatUpload(this.conversationId);

  final String conversationId;

  @override
  int get maxBytes => 100 * _mib;

  @override
  bool operator ==(Object other) =>
      other is ChatUpload && other.conversationId == conversationId;

  @override
  int get hashCode => Object.hash(ChatUpload, conversationId);
}

/// The signed-in user's own profile photo.
final class AvatarUpload extends UploadTarget {
  const AvatarUpload();

  @override
  int get maxBytes => 2 * _mib;

  @override
  bool operator ==(Object other) => other is AvatarUpload;

  @override
  int get hashCode => (AvatarUpload).hashCode;
}

/// A photo of the problem on a project being published.
final class ProjectPhotoUpload extends UploadTarget {
  const ProjectPhotoUpload();

  @override
  int get maxBytes => 10 * _mib;

  @override
  bool operator ==(Object other) => other is ProjectPhotoUpload;

  @override
  int get hashCode => (ProjectPhotoUpload).hashCode;
}

/// A photo of past work on a provider's profile.
final class PortfolioUpload extends UploadTarget {
  const PortfolioUpload();

  @override
  int get maxBytes => 10 * _mib;

  @override
  bool operator ==(Object other) => other is PortfolioUpload;

  @override
  int get hashCode => (PortfolioUpload).hashCode;
}
