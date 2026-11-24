import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

String newId() => DateTime.now().microsecondsSinceEpoch.toString();

/// Photos are stored in the app's Documents folder by file name, because the
/// absolute container path on iOS changes between installs and updates.
class PhotoStore {
  PhotoStore._(this._dir);
  final Directory _dir;
  static late PhotoStore instance;

  static Future<void> init() async {
    instance = PhotoStore._(await getApplicationDocumentsDirectory());
  }

  File file(String name) => File('${_dir.path}/$name');

  /// Opens the camera or the photo library and keeps a copy of the picture.
  Future<String?> pick(ImageSource source) async {
    final XFile? picked = await ImagePicker().pickImage(source: source, maxWidth: 1600, imageQuality: 85);
    if (picked == null) return null;
    final String name = 'photo_${newId()}.jpg';
    await File(picked.path).copy(file(name).path);
    return name;
  }

  Future<void> delete(String? name) async {
    if (name == null) return;
    final File f = file(name);
    if (await f.exists()) await f.delete();
  }
}

class GearItem {
  GearItem({required this.id, required this.name, this.description = '', required this.sport, this.photo});
  final String id;
  String name;
  String description;
  String sport;
  String? photo;

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'id': id, 'name': name, 'description': description, 'sport': sport, 'photo': photo};
  factory GearItem.fromJson(Map<String, dynamic> j) => GearItem(
      id: j['id'] as String,
      name: j['name'] as String,
      description: (j['description'] ?? '') as String,
      sport: j['sport'] as String,
      photo: j['photo'] as String?);
}

class Person {
  Person({required this.id, required this.name, required this.sport, this.invited = false});
  final String id;
  String name;
  String sport;
  bool invited;

  Map<String, dynamic> toJson() => <String, dynamic>{'id': id, 'name': name, 'sport': sport, 'invited': invited};
  factory Person.fromJson(Map<String, dynamic> j) => Person(
      id: j['id'] as String, name: j['name'] as String, sport: j['sport'] as String, invited: j['invited'] == true);
}

class Game {
  Game({
    required this.id,
    required this.name,
    required this.idea,
    required this.rules,
    required this.players,
    required this.sport,
    required this.date,
    this.photo,
    this.signups = 0,
    this.success,
    this.rating,
    this.sample = false,
  });
  final String id;
  String name;
  String idea;
  List<String> rules;
  int players;
  String sport;
  DateTime date;
  String? photo;
  int signups;
  bool? success; // null until the result is recorded
  double? rating;
  bool sample; // created by "Add sample games" on the Analytics screen

  bool get finished => success != null;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id, 'name': name, 'idea': idea, 'rules': rules, 'players': players, 'sport': sport,
        'date': date.toIso8601String(), 'photo': photo, 'signups': signups, 'success': success,
        'rating': rating, 'sample': sample,
      };
  factory Game.fromJson(Map<String, dynamic> j) => Game(
        id: j['id'] as String,
        name: j['name'] as String,
        idea: (j['idea'] ?? '') as String,
        rules: List<String>.from((j['rules'] ?? <dynamic>[]) as List<dynamic>),
        players: (j['players'] ?? 2) as int,
        sport: j['sport'] as String,
        date: DateTime.parse(j['date'] as String),
        photo: j['photo'] as String?,
        signups: (j['signups'] ?? 0) as int,
        success: j['success'] as bool?,
        rating: (j['rating'] as num?)?.toDouble(),
        sample: j['sample'] == true,
      );
}

class Profile {
  Profile({this.name = '', this.birthDate, this.about = '', this.photo, DateTime? joined})
      : joined = joined ?? DateTime.now();
  String name;
  DateTime? birthDate;
  String about;
  String? photo;
  DateTime joined;

  String get initials {
    final List<String> parts = name.trim().split(RegExp(r'\s+')).where((String s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return 'L';
    return parts.take(2).map((String s) => s[0].toUpperCase()).join();
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name, 'birthDate': birthDate?.toIso8601String(), 'about': about, 'photo': photo,
        'joined': joined.toIso8601String(),
      };
  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        name: (j['name'] ?? '') as String,
        birthDate: j['birthDate'] == null ? null : DateTime.parse(j['birthDate'] as String),
        about: (j['about'] ?? '') as String,
        photo: j['photo'] as String?,
        joined: j['joined'] == null ? null : DateTime.parse(j['joined'] as String),
      );
}

/// Everything the user creates, saved on the device with shared_preferences.
class AppState extends ChangeNotifier {
  static const String _key = 'lmyexitems.state.v2';

  List<GearItem> items = <GearItem>[];
  List<Person> people = <Person>[];
  List<Game> games = <Game>[];
  Profile profile = Profile();

  // "Find a game" draft, kept while switching tabs.
  Set<String> selectedItemIds = <String>{};
  Set<String> tags = <String>{'Outdoors', 'Team'};
  String wish = '';

  static Future<AppState> load() async {
    final AppState s = AppState();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_key);
    if (raw == null) return s;
    try {
      final Map<String, dynamic> j = jsonDecode(raw) as Map<String, dynamic>;
      s.items = (j['items'] as List<dynamic>).map((dynamic e) => GearItem.fromJson(e as Map<String, dynamic>)).toList();
      s.people = (j['people'] as List<dynamic>).map((dynamic e) => Person.fromJson(e as Map<String, dynamic>)).toList();
      s.games = (j['games'] as List<dynamic>).map((dynamic e) => Game.fromJson(e as Map<String, dynamic>)).toList();
      s.profile = Profile.fromJson(j['profile'] as Map<String, dynamic>);
      s.selectedItemIds = Set<String>.from((j['selected'] ?? <dynamic>[]) as List<dynamic>);
      s.tags = Set<String>.from((j['tags'] ?? <dynamic>['Outdoors', 'Team']) as List<dynamic>);
      s.wish = (j['wish'] ?? '') as String;
    } catch (e) {
      debugPrint('Could not read saved data: $e');
    }
    return s;
  }

  Future<void> _save() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key,
        jsonEncode(<String, dynamic>{
          'items': items.map((GearItem e) => e.toJson()).toList(),
          'people': people.map((Person e) => e.toJson()).toList(),
          'games': games.map((Game e) => e.toJson()).toList(),
          'profile': profile.toJson(),
          'selected': selectedItemIds.toList(),
          'tags': tags.toList(),
          'wish': wish,
        }));
  }

  /// Apply a change, repaint listeners and save.
  void update(VoidCallback change) {
    change();
    notifyListeners();
    _save();
  }

  int get invitedCount => people.where((Person p) => p.invited).length;
  int get gamesPlayed => games.where((Game g) => g.finished).length;
  int get gamesCreated => games.where((Game g) => !g.sample).length;
  bool get hasSampleGames => games.any((Game g) => g.sample);

  /// Clearly labelled demo games, only added when the user taps the button on Analytics.
  void addSampleGames() {
    final DateTime now = DateTime.now();
    final List<List<Object>> rows = <List<Object>>[
      // daysAgo, sport, signups, success, rating
      <Object>[1, '5-a-side soccer', 10, true, 4.8], <Object>[3, 'Streetball', 3, false, 2.5],
      <Object>[5, 'Beach tennis', 4, true, 4.4], <Object>[6, '5-a-side soccer', 9, true, 4.5],
      <Object>[8, 'Volleyball', 8, true, 4.1], <Object>[10, 'Streetball', 6, true, 3.9],
      <Object>[13, '5-a-side soccer', 12, true, 4.7], <Object>[15, 'Volleyball', 5, false, 3.0],
      <Object>[17, 'Beach tennis', 4, true, 4.2], <Object>[20, '5-a-side soccer', 11, true, 4.6],
      <Object>[22, 'Streetball', 6, true, 4.0], <Object>[27, 'Volleyball', 7, true, 4.3],
    ];
    update(() {
      for (final List<Object> r in rows) {
        games.add(Game(
          id: newId() + r[0].toString(),
          name: '${r[1]} (sample)',
          idea: '',
          rules: <String>[],
          players: r[2] as int,
          sport: r[1] as String,
          date: now.subtract(Duration(days: r[0] as int)),
          signups: r[2] as int,
          success: r[3] as bool,
          rating: r[4] as double,
          sample: true,
        ));
      }
    });
  }

  void removeSampleGames() => update(() => games.removeWhere((Game g) => g.sample));

  Future<void> resetAll() async {
    for (final GearItem i in items) {
      await PhotoStore.instance.delete(i.photo);
    }
    for (final Game g in games) {
      await PhotoStore.instance.delete(g.photo);
    }
    await PhotoStore.instance.delete(profile.photo);
    update(() {
      items = <GearItem>[];
      people = <Person>[];
      games = <Game>[];
      profile = Profile();
      selectedItemIds = <String>{};
      tags = <String>{'Outdoors', 'Team'};
      wish = '';
    });
  }

  /// JSON pushed into the analytics web page.
  String analyticsJson() => jsonEncode(<String, dynamic>{
        'games': games
            .map((Game g) => <String, dynamic>{
                  'name': g.name, 'sport': g.sport, 'date': g.date.toIso8601String(), 'signups': g.signups,
                  'success': g.success, 'rating': g.rating, 'sample': g.sample,
                })
            .toList(),
        'hasSample': hasSampleGames,
      });
}

/// Gives every screen access to [AppState] and rebuilds it on change.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
