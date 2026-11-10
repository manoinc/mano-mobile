/// Invite links the app was opened with: the launch link first, then any while running.
abstract interface class InviteLinkSource {
  Stream<Uri> get links;
}
