import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

Future<void> initHive() async {
  final dir = await getApplicationDocumentsDirectory();
  final hiveDir = Directory("${dir.path}/Collection_Creator_Data");
  if(!await hiveDir.exists()) await hiveDir.create(recursive: true);
  await Hive.initFlutter(hiveDir.path);
}

Future<List<String>> getBoxeNames() async {
  final prefs = await SharedPreferences.getInstance();
  List<String> _boxes = prefs.getStringList("collections") ?? [];
  return _boxes;
}

Future<void> openBox(String name) async {
  if(Hive.isBoxOpen(name)) return;
  await Hive.openBox(name);
}

Future<Box> getBox(String name) async {
  await openBox(name);
  final b = Hive.box(name);
  // for(final k in b.keys){print("${k}: ${b.get(k)}");}
  return b;
}

Future<void> removeBox(String name) async {
  final prefs = await SharedPreferences.getInstance();
  final b = prefs.getStringList("collections") ?? [];
  b.remove(name);
  await prefs.setStringList("collections", b);
  await Hive.close();
  await Hive.deleteBoxFromDisk(name);
}







Future<void> createCollection(String name, List<SchemaField> fields) async {
  final prefs = await SharedPreferences.getInstance();
  final boxes = prefs.getStringList("collections") ?? [];
  boxes.contains(name) ? null : boxes.add(name);
  await prefs.setStringList("collections", boxes);
  final b = await getBox(name);
  b.put("boxName", name);
  b.put("fields", fields.map((x) => {"name": x.name, "type": x.type, "options": x.options}).toList());
  b.put("data", []);
}

Future<void> updateCollectionSchema(String name, List<SchemaField> fields) async {
  final b = await getBox(name);
  b.put("fields", fields.map((x) => {"name": x.name, "type": x.type, "options": x.options}).toList());
}

Future<void> renameReorderCollectionSchema(String name, List<String> newNames, List<int> newIndexes) async {
  final b = await getBox(name);
  final fields = b.get("fields");
  final data = b.get("data");

  final newFields = List.generate(newIndexes.length, (index){
    final newField = fields[newIndexes[index]];
    newField["name"] = newNames[newIndexes[index]];
    return newField;
  });
  print(newFields.toString());
  b.put("fields", newFields);

  final newData = List.generate(data.length, (index){
    Map<String, dynamic> item = Map<String, dynamic>.from(data[index]);
    Map<String, dynamic> newItem = {};
    for(int i=0; i < newNames.length; i++){
      String cKey = item.keys.toList()[newIndexes[i]];
      String nKey = newNames[newIndexes[i]];
      newItem[nKey] = item[cKey];
    }
    return newItem;
  });
  b.put("data", newData);
}


class SchemaField{
  String name;
  String type;
  String options;
  SchemaField({this.name = '', this.type = 'String', this.options = ''});
}

class SchemaFieldTypes{
  static const String text = "String";
  static const String textArea = "TextArea";
  static const String integer = "Integer";
  static const String double = "Double";
  static const String boolean = "Boolean";
  static const String dropdown = "Dropdown";
  static const String date = "Date";
  static const String image = "Image";
  static const List<String> types = [text, textArea, integer, double, boolean, dropdown, date, image];
}



Future<void> AddDataToCollection(String name, Map<String, dynamic> data) async {
  final b = await getBox(name);
  final currentData = b.get("data");
  currentData.add(data);
  b.put("data", currentData);
}

Future<void> SetDataForCollection(String name, List<Map<String, dynamic>> data) async {
  final b = await getBox(name);
  b.put("data", data);
}

Future<void> SetDataForCollectionItem(String name, Map<String, dynamic> data, int index) async {
  final b = await getBox(name);
  final currentData = b.get("data");
  currentData[index] = data;
  b.put("data", currentData);
}







List<dynamic> queryData(List<dynamic> data, List<dynamic> schema, String search, String sortColumn, bool sortAsc){
  List<dynamic> usableSchema = schema.where((x) => x["type"] != SchemaFieldTypes.image).map((x) => x["name"]).toList();
  List<dynamic> filtered = List.from(data);
  if(search != ""){
    filtered = [];
    List<String> searchList = search.toLowerCase().split(" ");
    for(dynamic d in data){
      List<dynamic> usableData = d.keys.where((x) => usableSchema.contains(x)).toList();
      String values = usableData.map((x) => d[x].toString().toLowerCase()).join(" ");
      bool match = true;
      for(String s in searchList){
        if(!values.contains(s)){
          match = false;
          break;
        }
      }
      if(match) filtered.add(d);
    }
  }
  if(sortColumn != ""){
    final type = schema.firstWhere((x) => x["name"] == sortColumn)["type"];
    filtered.sort((a, b){
      a = a[sortColumn];
      b = b[sortColumn];
      if(type == SchemaFieldTypes.integer){
        a = int.parse(a.toString());
        b = int.parse(b.toString());
      }
      else if(type == SchemaFieldTypes.double){
        a = double.parse(a.toString());
        b = double.parse(b.toString());
      }
      else if(type == SchemaFieldTypes.date){
        List<String> la = a.toString().split("/").reversed.toList();
        List<String> lb = b.toString().split("/").reversed.toList();
        for(var i = 0; i < 3; i++){
          if(la[i] == lb[i]) continue;
          return sortAsc ? la[i].compareTo(lb[i]) : lb[i].compareTo(la[i]);
        }
      }
      else{
        a = a.toString().toLowerCase();
        b = b.toString().toLowerCase();
      }
      return sortAsc ? a.compareTo(b) : b.compareTo(a);
    });
  }
  return filtered;
}