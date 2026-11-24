import 'package:material_ui/material_ui.dart';

import 'state.dart';

/// A sport the app can suggest.
class Sport {
  const Sport(this.name, {this.image, required this.icon, required this.keywords, required this.tags, required this.needs});
  final String name;
  final String? image; // bundled artwork, if any
  final IconData icon;
  final List<String> keywords; // words found in item names/descriptions
  final Set<String> tags;
  final String needs; // what to get if the user has nothing for it yet
}

const List<String> kTags = <String>['Outdoors', 'Indoors', 'Team', 'One-on-one', 'Chill', 'Competitive'];

const List<Sport> kSports = <Sport>[
  Sport('5-a-side soccer',
      image: 'assets/images/soccer.png',
      icon: Icons.directions_run,
      keywords: <String>['soccer', 'football', 'cleat', 'boot', 'shin', 'goal', 'ball'],
      tags: <String>{'Outdoors', 'Team', 'Competitive'},
      needs: 'a size 5 ball and 9 more players'),
  Sport('Volleyball',
      image: 'assets/images/volley.png',
      icon: Icons.grid_on,
      keywords: <String>['volley', 'net', 'knee pad', 'ball'],
      tags: <String>{'Team', 'Outdoors', 'Indoors'},
      needs: 'a volleyball and a net'),
  Sport('Beach tennis',
      image: 'assets/images/tennis.png',
      icon: Icons.sports_tennis,
      keywords: <String>['tennis', 'racket', 'racquet', 'paddle'],
      tags: <String>{'Outdoors', 'One-on-one', 'Chill'},
      needs: 'two rackets (rentable) and a few balls'),
  Sport('Streetball',
      image: 'assets/images/basket.png',
      icon: Icons.sports_score,
      keywords: <String>['basketball', 'basket', 'hoop', 'streetball'],
      tags: <String>{'Outdoors', 'Team', 'Competitive'},
      needs: 'a basketball and a public court'),
  Sport('Running club',
      icon: Icons.directions_run,
      keywords: <String>['sneaker', 'shoe', 'trainer', 'watch', 'running', 'shorts'],
      tags: <String>{'Outdoors', 'Chill', 'One-on-one'},
      needs: 'a pair of running shoes'),
  Sport('Badminton',
      icon: Icons.sports_tennis,
      keywords: <String>['badminton', 'shuttle', 'shuttlecock', 'birdie', 'racket'],
      tags: <String>{'Indoors', 'One-on-one', 'Chill'},
      needs: 'two rackets and a shuttlecock'),
  Sport('Ultimate frisbee',
      icon: Icons.album_outlined,
      keywords: <String>['frisbee', 'disc', 'flying disc'],
      tags: <String>{'Outdoors', 'Team', 'Chill'},
      needs: 'a 175 g flying disc'),
  Sport('Cycling ride',
      icon: Icons.directions_bike,
      keywords: <String>['bike', 'bicycle', 'helmet', 'cycling'],
      tags: <String>{'Outdoors', 'Chill'},
      needs: 'a bike and a helmet'),
];

Sport sportByName(String name) =>
    kSports.firstWhere((Sport s) => s.name == name, orElse: () => kSports.first);

class MatchResult {
  const MatchResult(this.sport, this.percent, this.why);
  final Sport sport;
  final int percent;
  final String why;
}

/// Scores every sport against the selected gear, the free-text wish and the tags.
List<MatchResult> matchSports({required List<GearItem> gear, required String wish, required Set<String> tags}) {
  final String wishText = wish.toLowerCase();
  final List<MatchResult> out = <MatchResult>[];
  for (final Sport s in kSports) {
    final List<String> owned = <String>[];
    for (final GearItem g in gear) {
      final String text = '${g.name} ${g.description}'.toLowerCase();
      if (g.sport == s.name || s.keywords.any(text.contains)) owned.add(g.name);
    }
    final List<String> tagHits = s.tags.where(tags.contains).toList();
    final int wishHits =
        s.keywords.where(wishText.contains).length + (wishText.contains(s.name.toLowerCase()) ? 2 : 0);

    int score = 12 + (owned.length * 32).clamp(0, 64) + tagHits.length * 9 + (wishHits * 8).clamp(0, 16);
    score = score.clamp(5, 98);

    final StringBuffer why = StringBuffer();
    if (owned.isNotEmpty) {
      why.write('You already have: ${owned.take(2).join(', ')}${owned.length > 2 ? '…' : ''}.');
    } else {
      why.write('You would need ${s.needs}.');
    }
    if (tagHits.isNotEmpty) why.write(' Fits: ${tagHits.join(', ').toLowerCase()}.');
    out.add(MatchResult(s, score, why.toString()));
  }
  out.sort((MatchResult a, MatchResult b) => b.percent.compareTo(a.percent));
  return out.take(3).toList();
}
