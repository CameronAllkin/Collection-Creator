import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settingsprovider extends ChangeNotifier{
  ThemeMode _themeMode = ThemeMode.system;
  String _seedColour = "Purple";
  static Map<String, Color> colours = {
    "Red": Colors.red,
    "Green": Colors.green,
    "Blue": Colors.blue,
    "Yellow": Colors.yellow,
    "Orange": Colors.orange,
    "Cyan": Colors.cyan,
    "Purple": Colors.purple,
    "Pink": Colors.pink,
    "Brown": Colors.brown,
    "Indigo": Colors.indigo,
    "Teal": Colors.teal,
    "Lime": Colors.lime,
    "Amber": Colors.amber,
    "Grey": Colors.grey,
    "Black": Colors.black,
    "White": Colors.white
  };

  ThemeMode get themeMode => _themeMode;
  String get seedColour => _seedColour;
  Color get seedColourC => colours[_seedColour]!;

  bool _loaded = false;
  bool get loaded => _loaded;

  Settingsprovider(){
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = ThemeMode.values[prefs.getInt("themeMode") ?? 0];
    _seedColour = prefs.getString("seedColour") ?? "Purple";
    _loaded = true;
    notifyListeners();
  }

  Future<void> setTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("themeMode", mode.index);
    _themeMode = mode;
    notifyListeners();
  }

  Future<void> setColour(String colour) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("seedColour", colour);
    _seedColour = colour;
    notifyListeners();
  }

  Future<void> clearGames() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList("games", []);
  }
}