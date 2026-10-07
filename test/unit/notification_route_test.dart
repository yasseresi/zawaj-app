import 'package:flutter_test/flutter_test.dart';
import 'package:zawaj_app/src/data/models/app_notification_model.dart';
import 'package:zawaj_app/src/ui/notifications/notification_route.dart';

AppNotification _n(String type, {String? wedding = 'w1'}) =>
    AppNotification(id: 'n1', type: type, title: 't', weddingId: wedding);

void main() {
  test('a join request opens the wedding share screen for review', () {
    expect(notificationRoute(_n('join_requested')), '/weddings/w1/share');
  });

  test('an approval opens the wedding', () {
    expect(notificationRoute(_n('join_approved')), '/weddings/w1');
  });

  test('a decline goes nowhere (the user is not a member)', () {
    expect(notificationRoute(_n('join_declined')), isNull);
  });

  test('other wedding notifications open the wedding; none without one', () {
    expect(notificationRoute(_n('guest_added')), '/weddings/w1');
    expect(notificationRoute(_n('guest_added', wedding: null)), isNull);
  });
}
