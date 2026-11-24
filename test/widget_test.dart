import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lmyexitems/src/matching.dart';
import 'package:lmyexitems/src/state.dart';
import 'package:lmyexitems/src/screens/analytics_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a soccer ball and "outdoors, team" rank 5-a-side soccer first', () {
    final List<MatchResult> r = matchSports(
      gear: <GearItem>[GearItem(id: '1', name: 'Soccer ball', sport: '5-a-side soccer')],
      wish: 'play with friends on weekends',
      tags: <String>{'Outdoors', 'Team'},
    );
    expect(r, hasLength(3));
    expect(r.first.sport.name, '5-a-side soccer');
    expect(r.first.percent, greaterThan(r.last.percent));
  });

  test('sports without matching gear say what is needed', () {
    final List<MatchResult> r = matchSports(gear: <GearItem>[], wish: '', tags: <String>{'Indoors'});
    expect(r.every((MatchResult m) => m.why.startsWith('You would need')), isTrue);
  });

  test('game data round-trips through JSON', () {
    final Game g = Game(
      id: 'g', name: 'Golden Bounce', idea: 'x', rules: <String>['a'], players: 6, sport: 'Streetball',
      date: DateTime(2026, 11, 28), success: true, rating: 4.5, signups: 6,
    );
    final Game back = Game.fromJson(g.toJson());
    expect(back.name, g.name);
    expect(back.finished, isTrue);
    expect(back.rating, 4.5);
  });

  test('the analytics page is bundled locally', () async {
    final String html = await rootBundle.loadString(AnalyticsScreen.page);
    expect(html, contains('window.LApp'));
    expect(html, isNot(contains('http://')));
  });
}
