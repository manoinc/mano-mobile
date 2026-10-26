import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

void main() {
  final at = DateTime.utc(2026, 10, 25, 15);

  test('a feed status carries only when the live link was issued', () {
    expect(CalendarFeedStatus(issuedAt: at), CalendarFeedStatus(issuedAt: at));
    expect(CalendarFeedStatus(issuedAt: at).issuedAt, at);
  });

  test('an issued feed reduces to its status, without the URL', () {
    final feed = CalendarFeed(url: 'https://gw/calendar/abc.ics', issuedAt: at);
    expect(feed.status, CalendarFeedStatus(issuedAt: at));
  });
}
