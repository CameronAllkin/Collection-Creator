import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'collections.dart';
import 'settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initHive();

  runApp(ChangeNotifierProvider(
    create: (_) => Settingsprovider(),
    child: const MainApp()
  ));
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}


const double _padding = 20;
const double _margin = 5;
const double _spacing = 10;
const Duration _snackbarDuration = Duration(seconds: 2);


class _MainAppState extends State<MainApp> {
  @override
  Widget build(BuildContext context) {
    return Consumer<Settingsprovider>(
      builder: (context, settings, _) {
        if(!settings.loaded){
          return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
        }
        return MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: settings.seedColourC,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: settings.seedColourC,
            brightness: Brightness.dark,
          ),
          themeMode: settings.themeMode,
          home: Builder(builder: (context) => HomePage()),
          debugShowCheckedModeBanner: false,
        );
      }
    );
  }
}





class HomePage extends StatefulWidget{
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>{
  int _selectedIndex = 0;
  late List<Widget> _pages;
  late List<String>? _boxes;
  bool _loading = true;

  Future<void> _getBoxes() async {
    setState(() {
      _loading = true;
      _boxes = [];
    });

    final res = await getBoxeNames();
    if(!mounted) return;

    setState(() {
      _boxes = res;
      _pages[0] = CollectionsPage(key: ValueKey(_boxes!.hashCode), boxes: _boxes!);
      _loading = false;
    });
  }

  @override
  void initState(){
    super.initState();
    _pages = [
      CollectionsPage(boxes: []),
      Settings()
    ];
    _getBoxes();
  }

  final List<List<dynamic>> _items = [
    [Icon(Icons.collections_bookmark_rounded), "Collections"],
    [Icon(Icons.settings_rounded), "Settings"],
  ];

  @override
  Widget build(BuildContext context){
    return _loading ? const Scaffold(body: Center(child: CircularProgressIndicator())) :
    Scaffold(
      body: SafeArea(
        child: _pages[_selectedIndex]
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.shifting,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: _items.map((x){
          return BottomNavigationBarItem(
            icon: x[0],
            label: x[1],
            backgroundColor: Theme.of(context).colorScheme.primary
          );
        }).toList()
      ),
      floatingActionButton: _selectedIndex == 0 ? FloatingActionButton(
        child: const Icon(Icons.add_rounded),
        onPressed: () async {
          final res = await Navigator.push(context, MaterialPageRoute(builder: (context) => CollectionSchemaPage(boxNames: _boxes ?? [])));
          await _getBoxes();
        }
      ) : null,
    );
  }
}









class CollectionsPage extends StatefulWidget{
  final List<String> boxes;
  const CollectionsPage({
    super.key,
    required this.boxes
  });

  @override
  State<CollectionsPage> createState() => _CollectionsPageState();
}

class _CollectionsPageState extends State<CollectionsPage>{
  late final List<String> _boxes;
  late List<String> _displayBoxes;
  TextEditingController _search = TextEditingController();
  bool _sortAsc = true;

  @override
  void initState(){
    super.initState();
    _boxes = widget.boxes;
    _displayBoxes = _boxes;
  }

  void _queryBoxes(){
    final search = _search.text;
    List<String> filtered = List.from(_boxes);

    if(search != ""){
      List<String> searchList = search.toLowerCase().split(" ");
      filtered = [];
      for(dynamic d in _boxes){
        String values = d.toLowerCase();
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
    filtered.sort((a, b){
      return _sortAsc ? a.compareTo(b) : b.compareTo(a);
    });
    setState(() => _displayBoxes = filtered);
  }

  Future<void> _removeBox(String name) async{
    setState(() => _boxes!.remove(name));
    _queryBoxes();
    await removeBox(name);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(_padding),
      child: Column(
        spacing: _margin,
        children: [
          Row(spacing: _spacing, children: [
            Expanded(child: TextField(
              controller: _search,
              onChanged: (v) => _queryBoxes(),
              decoration: InputDecoration(
                labelText: "Search",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(_spacing)),
              ),
            )),
            IconButton(
              icon: Icon(_sortAsc ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded),
              onPressed: (){
                setState(() => _sortAsc = !_sortAsc);
                _queryBoxes();
              }
            )
          ]), 
          _displayBoxes.isEmpty ? Expanded(child: Center(child: Text("No Collections"))):
          Expanded(child: ListView.builder(
            itemCount: _displayBoxes.length,
            shrinkWrap: true,
            itemBuilder: (context, index){
              return Card(child: Row(children: [
                Expanded(child: Padding(padding: EdgeInsets.all(_spacing), child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.all(_padding),
                    textStyle: Theme.of(context).textTheme.titleMedium,
                  ),
                  onPressed: () async {
                    final r = await Navigator.push(context, MaterialPageRoute(builder: (context) => CollectionPage(boxName: _displayBoxes[index])));
                    await Future.delayed(const Duration(milliseconds: 100));
                    if(r == true){
                      final name = _displayBoxes[index];
                      await _removeBox(name);
                    }
                  },
                  child: Text(_displayBoxes[index]),
                ))),
                Padding(padding: EdgeInsets.all(_spacing), child: PopupMenuButton<String>(
                  itemBuilder: (context){
                    return [
                      // PopupMenuItem<String>(
                      //   onTap: () async {
                      //     final res = await Navigator.push(context, MaterialPageRoute(builder: (context) => CollectionSchemaPage(boxNames: _boxes)));
                          
                      //   },
                      //   child: Text("Edit")
                      // ),
                      PopupMenuItem<String>(
                        onTap: () async {
                          final name = _displayBoxes[index];
                          await _removeBox(name);
                        },
                        child: Text("Delete")
                      )
                    ];
                  }
                ))
              ]));
            }
          ))
        ]
      )
    );
  }
}












class CollectionSchemaPage extends StatefulWidget{
  final List<String> boxNames;
  final String? boxName;
  final List<dynamic>? initSchema;
  const CollectionSchemaPage({
    super.key,
    required this.boxNames,
    this.boxName,
    this.initSchema
  });

  @override
  State<CollectionSchemaPage> createState() => _CollectionSchemaPageState();
}

class _CollectionSchemaPageState extends State<CollectionSchemaPage>{
  final _formKey = GlobalKey<FormState>();
  late final bool _hasSchema;

  late final _schemaName = TextEditingController();
  late List<String> _initFields;
  late List<SchemaField> _fields = [];

  @override
  void initState(){
    super.initState();
    _hasSchema = widget.boxName != null && widget.initSchema != null;
    print(_hasSchema);
    if(_hasSchema){
      _schemaName.text = widget.boxName!;
      _initFields = widget.initSchema!.map((x) => x["name"].toString()).toList();
      _fields = List<SchemaField>.from(widget.initSchema!.map((x) => SchemaField(name: x["name"], type: x["type"], options: x["options"])));
    }
  }

  void _addField(){
    setState(() => _fields.add(SchemaField()));
  }

  void _removeField(int index){
    setState(() => _fields.removeAt(index));
  }

  void _submit(){
    if(!_formKey.currentState!.validate()) return;
    if(_fields.isEmpty) return;

    final schemaName = _schemaName.text;
    for(final field in _fields){if(field.name.isEmpty || field.type.isEmpty) return;}
    
    _hasSchema ? updateCollectionSchema(schemaName, _fields) : createCollection(schemaName, _fields);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: _hasSchema ? Text("Edit Collection Schema") : Text("Collection Schema")),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add_rounded),
        onPressed: _addField
      ),
      body: SafeArea(child: Form(key: _formKey, child: SingleChildScrollView(child: Padding(padding: EdgeInsets.all(_padding), child: Center(child: Column(spacing: _spacing, children: [
        TextFormField(
          controller: _schemaName,
          enabled: !_hasSchema,
          readOnly: _hasSchema,
          decoration: InputDecoration(
            labelText: "Schema Name",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(_spacing))
          ),
          validator: (v){
            return _schemaName.text.isEmpty ? "Fill In" :
            widget.boxNames.contains(v) ? "Already Exists" : null;
          }
        ),
        Padding(padding: EdgeInsets.symmetric(vertical: _spacing), child:
        _fields.isEmpty ? Text("Add Fields"): 
        ListView.builder(
          itemCount: _fields.length,
          shrinkWrap: true,
          itemBuilder: (context, index){
            final _field = _fields[index];
            return Padding(padding: EdgeInsets.symmetric(vertical: _spacing), child: Column(children: [Row(
              spacing: _spacing,
              children: [
                Expanded(flex: 2, child: TextFormField(
                  initialValue: _field.name,
                  enabled: !_initFields.contains(_field.name),
                  decoration: InputDecoration(
                    labelText: "Field Name",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(_spacing))
                  ),
                  onChanged: (v) => _field.name = v,
                  validator: (v) => v!.isEmpty ? "Fill In" : null,
                )),
                Expanded(flex: 1, child: DropdownButtonFormField<String>(
                  initialValue: _field.type,
                  items: SchemaFieldTypes.types.map((x){
                    return DropdownMenuItem(
                      value: x,
                      child: Text(x)
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _field.type = v!),
                  decoration: InputDecoration(
                    labelText: "Field Type",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(_spacing))
                  )
                )),
                IconButton(
                  icon: const Icon(Icons.remove_rounded),
                  onPressed: () => _removeField(index), 
                )
              ],
            ),
            if(_field.type == "Dropdown")
            ...[
              SizedBox(height: _spacing),
              TextFormField(
                initialValue: _field.options,
                maxLines: null,
                decoration: InputDecoration(
                  labelText: "Dropdown Options",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(_spacing)),
                ),
                onChanged: (v) => _field.options = v,
                validator: (v) => v!.isEmpty ? "Fill In" : null,
              )]
            ]));
          }
        )),
        Row(children: [Expanded(child: ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(padding: EdgeInsets.all(_padding)),
          child: const Text("Save Collection Schema"),
        ))])
      ]))))))
    );
  }
}







class CollectionRenameReorderPage extends StatefulWidget{
  final String boxName;
  final List<dynamic> schema;

  const CollectionRenameReorderPage({
    super.key,
    required this.boxName,
    required this.schema
  });

  @override
  State<CollectionRenameReorderPage> createState() => _CollectionRenameReorderPageState();
}

class _CollectionRenameReorderPageState extends State<CollectionRenameReorderPage>{
  final _formKey = GlobalKey<FormState>();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Collection Schema")),
      body: SafeArea(child: Form(key: _formKey, child: SingleChildScrollView(child: Padding(padding: EdgeInsets.all(_padding), child: Center(child: Column(spacing: _spacing, children: [
        Text("Test")
      ]))))))
    );
  }
}










class CollectionPage extends StatefulWidget{
  final String boxName;
  const CollectionPage({
    super.key,
    required this.boxName
  });

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage>{
  late final String _name;
  late List<dynamic> _schema;
  late List<dynamic> _data;

  TextEditingController _search = TextEditingController();
  late Map<String, bool> _columns = {};
  List<String> get _columnsA => _columns.keys.where((v) => _columns[v] == true).toList();
  String? _sortColumn;
  bool _sortAsc = true;

  late List<dynamic> _displayData;
  bool _loading = true;

  Future<void> _getBoxData() async {
    if(!mounted) return;
    setState(() {
      _loading = true;
      _schema = [];
      _data = [];
      _displayData = [];
    });

    final box = await getBox(_name);
    if(!mounted) return;

    setState(() {
      _schema = box.get("fields");
      _data = box.get("data");
      _columns = {};
      for(String k in _schema.map((x) => x["name"])){
        _columns[k] = true;
      }
      _displayData = _data;
      _applyQuery();
      _loading = false;
    });
  }

  @override
  void initState(){
    super.initState();
    _name = widget.boxName;
    _getBoxData();
  }

  @override
  void dispose(){
    _search.dispose();
    super.dispose();
  }


  void _applyQuery(){
    final search = _search.text;

    setState((){
      _displayData = queryData(_data, _schema, search, _sortColumn ?? "", _sortAsc);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _loading ? Center(child: CircularProgressIndicator()) :
    Scaffold(
      appBar: AppBar(
        title: Text(_name),
        actions: [
          PopupMenuButton(
            itemBuilder: (context){
              return [
                PopupMenuItem(
                  onTap: () async {
                    final res = await Navigator.push(context, MaterialPageRoute(builder: (context) => CollectionRenameReorderPage(boxName: _name, schema: _schema)));
                    await _getBoxData();
                  },
                  child: Text("Rename / Reorder")
                ),
                PopupMenuItem(
                  onTap: () async {
                    final res = await Navigator.push(context, MaterialPageRoute(builder: (context) => CollectionSchemaPage(boxNames: [], boxName: _name, initSchema: _schema)));
                    await _getBoxData();
                  },
                  child: Text("Edit Schema")
                ),
                PopupMenuItem(
                  onTap: () async {
                    removeBox(_name);
                    Navigator.pop(context, true);
                  },
                  child: Text("Delete")
                )
              ];
            }
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add_rounded),
        onPressed: () async {
          final r = await Navigator.push(context, MaterialPageRoute(builder: (context) => CollectionItemPage(name: _name, schema: _schema)));
          r == true ? await _getBoxData() : null;
        }
      ),
      body: SafeArea(child: Padding(padding: EdgeInsets.all(_padding), child: Column(spacing: _spacing, children: [
        Row(children: [
          Expanded(child: TextField(
            controller: _search,
            onChanged: (v){
              _applyQuery();
            },
            decoration: InputDecoration(
              labelText: "Search",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(_spacing)),
            ),
          )),
          PopupMenuButton<String>(
            itemBuilder: (context) => _columns.keys.map((key){
              return PopupMenuItem<String>(
                enabled: true,
                child: StatefulBuilder(builder: (context, setMenuState){
                  return CheckboxListTile(
                    title: Text(key),
                    value: _columns[key],
                    onChanged: (v){
                      setMenuState(() => _columns[key] = v!);
                      setState((){});
                    }
                  );
                })
              );
            }).toList(),
            icon: Icon(Icons.filter_list_rounded)
        )
        ]),
        Text("Displaying ${_displayData.length}/${_data.length} Items"),
        Card(child: Padding(padding: EdgeInsets.all(_spacing), child: Row(
          spacing: _margin,
          children: [
            ..._columnsA.map<Widget>((k){
              final td = _schema.firstWhere((x) => x["name"] == k)["type"];
              return Expanded(
                flex: td == SchemaFieldTypes.textArea ? 3 : 
                      [SchemaFieldTypes.integer, SchemaFieldTypes.double].contains(td) ? 1 : 2,
                child: GestureDetector(
                  onTap: (){
                    setState((){
                      if(_sortColumn == k){_sortAsc = !_sortAsc;}
                      else{
                        _sortColumn = k;
                        _sortAsc = true;
                      }
                    });
                    _applyQuery();
                  },
                  child: Text(k.toString(), textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium)
                )
              );
            }),
            SizedBox(width: 40)
          ]
        ))),
        Expanded(child:
          ListView.builder(
            itemCount: _displayData.length+1,
            shrinkWrap: true,
            itemBuilder: (context, index){
              return index == _displayData.length ? SizedBox(height: _padding*3) :
              Card(child: Padding(padding: EdgeInsets.all(_spacing), child: Row(spacing: _margin, children: [
                ..._columnsA.map((k){
                  final td = _schema.firstWhere((x) => x["name"] == k)["type"];
                  return Expanded(
                    flex: td == SchemaFieldTypes.textArea ? 3 : 
                          [SchemaFieldTypes.integer, SchemaFieldTypes.double].contains(td) ? 1 : 2,
                    child: td == SchemaFieldTypes.image ? 
                      ClipRRect(borderRadius: BorderRadius.circular(_spacing), child: Image.network(
                        _displayData[index][k].toString(), 
                        loadingBuilder: (context, child, loadingProgress){
                          if(loadingProgress == null) return child;
                          return Center(child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, StackTrace){
                          return Center(child: Icon(Icons.broken_image_rounded));
                        },
                        fit: BoxFit.cover
                      )):
                      Text(_displayData[index][k].toString(), textAlign: TextAlign.center)
                  );
                }),
                PopupMenuButton(
                  itemBuilder: (context){
                    return [
                      PopupMenuItem(
                        onTap: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (context) => CollectionItemPage(name: _name, schema: _schema, data: Map<String, dynamic>.from(_displayData[index]), dataIndex: _data.indexOf(_displayData[index]))));
                          await _getBoxData();
                        },
                        child: Text("Edit")
                      ),
                      PopupMenuItem(
                        onTap: (){
                          AddDataToCollection(_name, Map<String, dynamic>.from(_displayData[index]));
                          _getBoxData();
                        },
                        child: Text("Duplicate")
                      ),
                      PopupMenuItem(
                        onTap: (){
                          final item = _displayData[index];
                          _data.remove(item);
                          SetDataForCollection(_name, List<Map<String, dynamic>>.from(_data.map((x) => Map<String, dynamic>.from(x))));
                          _getBoxData();
                        },
                        child: Text("Delete")
                      )
                    ];
                  }
                )
              ])));
            }
          ))
      ])))
    );
  }
}





/*

- Collection Page
  - show collection items
    - selected columns
    - remove button
  - search
  - filter (checkbox for which columns to show?)

*/


class CollectionItemPage extends StatefulWidget{
  final String name;
  final List<dynamic> schema;
  final Map<String, dynamic>? data;
  final int? dataIndex;
  CollectionItemPage({
    super.key,
    required this.name,
    required this.schema,
    this.data,
    this.dataIndex
  });

  @override
  State<CollectionItemPage> createState() => _CollectionItemPageState();
}

class _CollectionItemPageState extends State<CollectionItemPage>{
  final _formKey = GlobalKey<FormState>();
  late final List<dynamic> _schema;
  late List<dynamic> _formFields = [];

  @override
  void initState() {
    super.initState();
    _schema = widget.schema;
    for(final f in _schema){
      final initialData = widget.data?[f["name"]];
      final t = f["type"];
      if ([SchemaFieldTypes.text, SchemaFieldTypes.textArea, SchemaFieldTypes.integer, SchemaFieldTypes.double, SchemaFieldTypes.date, SchemaFieldTypes.image].contains(t)){
        _formFields.add(TextEditingController(
          text: initialData?.toString() ?? ""
        ));
      }
      else if(t == SchemaFieldTypes.boolean){
        _formFields.add(initialData == true ? "True" : "False");
      }
      else if(t == SchemaFieldTypes.dropdown){
        _formFields.add(initialData?.toString() ?? f["options"].split(",")[0]);
      }
    }
  }

  void _submit(){
    if(!_formKey.currentState!.validate()) return;

    Map<String, dynamic> data = {};
    for(int i=0; i < _schema.length; i++){
      final String _fieldName = _schema[i]["name"];
      final String _fieldType = _schema[i]["type"];
      final dynamic _value = _formFields[i];
      switch(_fieldType){
        case SchemaFieldTypes.text:
          data[_fieldName] = _value.text;
        case SchemaFieldTypes.textArea:
          data[_fieldName] = _value.text;
        case SchemaFieldTypes.integer:
          data[_fieldName] = int.parse(_value.text);
        case SchemaFieldTypes.double:
          data[_fieldName] = double.parse(_value.text);
        case SchemaFieldTypes.boolean:
          data[_fieldName] = _value == "True";
        case SchemaFieldTypes.dropdown:
          data[_fieldName] = _value;
        case SchemaFieldTypes.date:
          data[_fieldName] = _value.text;
        case SchemaFieldTypes.image:
          data[_fieldName] = _value.text;
      }
    }
    widget.data == null ? AddDataToCollection(widget.name, data) : SetDataForCollectionItem(widget.name, data, widget.dataIndex!);
    Navigator.pop(context, true);
  }

  String? dateValidator(String? value) {
    if (value == null || value.isEmpty) 'Please enter a date';
    
    final regex = RegExp(r'^\d{2}/\d{2}/\d{4}$');
    if (!regex.hasMatch(value!)) 'Enter date in dd/MM/yyyy format';

    try {
      final parts = value.split('/');
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      final date = DateTime(year, month, day);
      if (date.day != day || date.month != month || date.year != year) return 'Invalid date';
    } catch (e) {return 'Invalid date';}

    return null;
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: Text("Add Item")),
      body: SafeArea(child: Form(key: _formKey, child: SingleChildScrollView(child: Padding(padding: EdgeInsets.all(_padding), child: Center(child: Column(spacing: _spacing, children: [
        ListView.builder(
          itemCount: _schema.length,
          shrinkWrap: true,
          itemBuilder: (context, index){
            final String _fieldName = _schema[index]["name"];
            final String _fieldType = _schema[index]["type"];
            final List<String> _fieldOptions = _fieldType == SchemaFieldTypes.dropdown ? _schema[index]["options"].split(",") : [];
            Widget _widget = Text("");
            switch(_fieldType){
              case SchemaFieldTypes.text:
                _widget = TextFormField(
                  controller: _formFields[index],
                  decoration: InputDecoration(
                    labelText: _fieldName,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(_spacing)),
                  ),
                  validator: (v) => _formFields[index].text.isEmpty ? "Fill In" : null,
                );
              case SchemaFieldTypes.textArea:
                _widget = TextFormField(
                  controller: _formFields[index],
                  maxLines: null,
                  decoration: InputDecoration(
                    labelText: _fieldName,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(_spacing)),
                  ),
                  validator: (v) => _formFields[index].text.isEmpty ? "Fill In" : null,
                );
              case SchemaFieldTypes.integer:
                _widget = TextFormField(
                  controller: _formFields[index],
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: _fieldName,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(_spacing)),
                  ),
                  validator: (v) => _formFields[index].text.isEmpty || int.tryParse(_formFields[index].text) == null ? "Fill In" : null,
                );
              case SchemaFieldTypes.double:
                _widget = TextFormField(
                  controller: _formFields[index],
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: _fieldName,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(_spacing)),
                  ),
                  validator: (v) => _formFields[index].text.isEmpty || double.tryParse(_formFields[index].text) == null ? "Fill In" : null,
                );
              case SchemaFieldTypes.boolean:
                _widget = DropdownButtonFormField<String>(
                  initialValue: ["False", "True"].contains(_formFields[index]) ? _formFields[index] : _fieldOptions[0],
                  items: ["False", "True"].map((x){
                    return DropdownMenuItem(
                      value: x,
                      child: Text(x)
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _formFields[index] = v!),
                  decoration: InputDecoration(
                    labelText: _fieldName,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(_spacing))
                  )
                );
              case SchemaFieldTypes.dropdown:
                _widget = DropdownButtonFormField<String>(
                  initialValue: _fieldOptions.contains(_formFields[index]) ? _formFields[index] : _fieldOptions[0],
                  items: _fieldOptions.map((x){
                    return DropdownMenuItem(
                      value: x,
                      child: Text(x)
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _formFields[index] = v!),
                  decoration: InputDecoration(
                    labelText: _fieldName,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(_spacing))
                  )
                );
              case SchemaFieldTypes.date:
                _widget = TextFormField(
                  controller: _formFields[index],
                  keyboardType: TextInputType.datetime,
                  decoration: InputDecoration(
                    labelText: _fieldName,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(_spacing)),
                  ),
                  validator: (v) => dateValidator(v),
                );
              case SchemaFieldTypes.image:
                _widget = TextFormField(
                  controller: _formFields[index],
                  decoration: InputDecoration(
                    labelText: _fieldName,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(_spacing)),
                  ),
                  validator: (v) => _formFields[index].text.isEmpty ? "Fill In" : null,
                );
            }
            return Padding(padding: EdgeInsets.symmetric(vertical: _spacing), child: Column(children: [Row(
              spacing: _spacing,
              children: [
                Expanded(child: _widget)
              ]
            )]));
          }
        ),
        Row(children: [Expanded(child: ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(padding: EdgeInsets.all(_padding)),
          child: const Text("Save Item"),
        ))])
      ]))))))
    );
  }
}


















class Settings extends StatelessWidget{
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<Settingsprovider>(context);
    return SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(_padding),
      child: Column(
        spacing: _spacing,
        children: [
          Text("Appearance", style: Theme.of(context).textTheme.titleLarge),
          Card(child: Padding(padding: EdgeInsets.all(_padding), child: Column(spacing: _padding, children: [
            DropdownButtonFormField(
              initialValue: settings.themeMode,
              decoration: InputDecoration(
                labelText: "Theme",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(_spacing),
                ),
                contentPadding: const EdgeInsets.all(_spacing),
              ),
              items: [
                DropdownMenuItem(value: ThemeMode.system, child: Text("System")),
                DropdownMenuItem(value: ThemeMode.light, child: Text("Light")),
                DropdownMenuItem(value: ThemeMode.dark, child: Text("Dark"))
              ], 
              onChanged: (mode) => settings.setTheme(mode!)
            ),
            DropdownButtonFormField(
              initialValue: settings.seedColour,
              decoration: InputDecoration(
                labelText: "Colour",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(_spacing),
                ),
                contentPadding: const EdgeInsets.all(_spacing),
              ),
              items: Settingsprovider.colours.keys.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), 
              onChanged: (colour) => settings.setColour(colour!)
            ),
          ]))),
          Divider(height: _padding),
          Text("Information", style: Theme.of(context).textTheme.titleLarge),
          Card(child: Padding(padding: EdgeInsets.all(_padding), child: Column(spacing: _padding, children: [ 
            Row(children: [Expanded(child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.all(_padding),
                textStyle: Theme.of(context).textTheme.titleMedium,
              ),
              onPressed: (){
                Navigator.push(context, MaterialPageRoute(builder: (context) => AboutPage()));
              }, 
              child: Text("About App", textAlign: TextAlign.center),
            ))]),
            Row(children: [Expanded(child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.all(_padding),
                textStyle: Theme.of(context).textTheme.titleMedium,
              ),
              onPressed: (){
                Navigator.push(context, MaterialPageRoute(builder: (context) => LegalPage()));
              }, 
              child: Text("Legal", textAlign: TextAlign.center),
            ))])
          ])))
        ]
      )
    ));
  }
}


class AboutPage extends StatelessWidget{
  const AboutPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("About")),
      body: SafeArea(child: SingleChildScrollView(child: Padding(padding: EdgeInsets.all(_padding), child: Center(child: Column(spacing: _spacing, children: [
        Text("Purpose", style: Theme.of(context).textTheme.titleMedium),
        Card(child: Padding(padding: EdgeInsets.all(_padding), child: Column(spacing: _padding, children: [
          Text("The purpose of this program is to have a way to create and store information about your collections, being able to specify exactly what information is captured and how.", textAlign: TextAlign.center),
          Text("Designed to be a quick and easy way of not only cataloging items but searching and filtering them.", textAlign: TextAlign.center),
        ]))),
        Divider(),
        Text("What Can You Do?", style: Theme.of(context).textTheme.titleMedium),
        Card(child: Padding(padding: EdgeInsets.all(_padding), child: Column(spacing: _padding, children: [
          Text("There are two main actions you can do; creating collections and creating items.", textAlign: TextAlign.center),
          Text("Creating collections allows you to design and specify a collection's schema, including what information is captured and what type of information that is. This creates a 'skeleton' for your collection that all items adhere to.", textAlign: TextAlign.center),
          Text("Creating items allows you to specify specific items within a collection following the collection's schema.", textAlign: TextAlign.center),
          Text("Within both, you can do various searching, sorting, and filtering to see exactly what you want.", textAlign: TextAlign.center),
        ]))),
        Divider(),
        Text("Requirements", style: Theme.of(context).textTheme.titleMedium),
        Card(child: Padding(padding: EdgeInsets.all(_padding), child: Column(spacing: _padding, children: [
          Text("There are no requirements for using this program.", textAlign: TextAlign.center),
          Text("An internet connection may be required if a URL image is chosen for an item/schema.", textAlign: TextAlign.center),
        ]))),
        Divider(),
        Text("Behind the Scenes", style: Theme.of(context).textTheme.titleMedium),
        Card(child: Padding(padding: EdgeInsets.all(_padding), child: Column(spacing: _padding, children: [
          Text("All information created within the program is stored locally to the device and is not shared/sharable to anywhere else.", textAlign: TextAlign.center),
        ])))
      ])))))
    );
  }
}


class LegalPage extends StatelessWidget{
  const LegalPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Legal")),
      body: SafeArea(child: SingleChildScrollView(child: Padding(padding: EdgeInsets.all(_padding), child: Center(child: Column(spacing: _spacing, children: [
        Text("Legal Stuffs", style: Theme.of(context).textTheme.titleMedium),
        Card(child: Padding(padding: EdgeInsets.all(_padding), child: Column(spacing: _padding, children: [
          Text("Don't really know what to put here...", textAlign: TextAlign.center),
          Text("No legal stuff I guess, just go get them games for cheap.", textAlign: TextAlign.center),
        ])))
      ])))))
    );
  }
}