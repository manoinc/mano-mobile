/// The store's install referrer (Play's `referrer=`), or null where there is none.
abstract interface class InstallReferrerSource {
  Future<String?> referrer();
}
