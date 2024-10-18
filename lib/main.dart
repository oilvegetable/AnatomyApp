import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anatomy App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  List<String> favoriteMethods = [];

  final List<String> _moduleNames = ['3D 解剖模块', '解剖方法列表', '收藏夹'];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context); // 关闭抽屉菜单
  }

  void _toggleFavorite(String method) {
    setState(() {
      if (favoriteMethods.contains(method)) {
        favoriteMethods.remove(method);
      } else {
        favoriteMethods.add(method);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _modules = [
      Anatomical3DModule(),
      AnatomicalMethodsList(
        favoriteMethods: favoriteMethods,
        onFavoriteToggle: _toggleFavorite,
      ),
      FavoritesPage(
        favoriteMethods: favoriteMethods,
        onFavoriteToggle: _toggleFavorite,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_moduleNames[_selectedIndex]),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                '解剖示教App',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.view_in_ar),
              title: Text('3D 解剖模块'),
              onTap: () => _onItemTapped(0),
            ),
            ListTile(
              leading: Icon(Icons.list),
              title: Text('解剖方法列表'),
              onTap: () => _onItemTapped(1),
            ),
            ListTile(
              leading: Icon(Icons.favorite),
              title: Text('收藏夹'),
              onTap: () => _onItemTapped(2),
            ),
          ],
        ),
      ),
      body: _modules[_selectedIndex],
    );
  }
}

class Anatomical3DModule extends StatefulWidget {
  @override
  _Anatomical3DModuleState createState() => _Anatomical3DModuleState();
}

class _Anatomical3DModuleState extends State<Anatomical3DModule> {
  late TransformationController _transformationController;
  TapDownDetails? _doubleTapDetails;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _showMethodDetailBottomSheet(BuildContext context, String methodName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 5 / 6,
          width: double.infinity,
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                methodName,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Expanded(
                child: Text(
                  '这是 $methodName 的详细介绍。',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onDoubleTapDown: (details) => _doubleTapDetails = details,
          onDoubleTap: () {
            if (_transformationController.value != Matrix4.identity()) {
              _transformationController.value = Matrix4.identity();
            } else if (_doubleTapDetails != null) {
              final position = _doubleTapDetails!.localPosition;
              _transformationController.value = Matrix4.identity()
                ..translate(-position.dx * 2, -position.dy * 2)
                ..scale(2.0);
            }
          },
          child: InteractiveViewer(
            transformationController: _transformationController,
            panEnabled: true,
            scaleEnabled: true,
            minScale: 1.0,
            maxScale: 4.0,
            child: Image.asset(
              'assets/images/head.jpg',
              width: double.maxFinite,
              height: double.maxFinite,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 100,
          left: 150,
          child: Column(
            children: [
              GestureDetector(
                onTap: () => _showMethodDetailBottomSheet(context, '部位 1'),
                child: Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 35,
                ),
              ),
              Text('部位 1', style: TextStyle(color: Colors.red, fontSize: 20)),
            ],
          ),
        ),
        Positioned(
          top: 200,
          right: 100,
          child: Column(
            children: [
              GestureDetector(
                onTap: () => _showMethodDetailBottomSheet(context, '部位 2'),
                child: Icon(
                  Icons.location_on,
                  color: Colors.blue,
                  size: 35,
                ),
              ),
              Text('部位 2', style: TextStyle(color: Colors.blue, fontSize: 20)),
            ],
          ),
        ),
        Positioned(
          top: 150,
          left: 50,
          child: Column(
            children: [
              GestureDetector(
                onTap: () => _showMethodDetailBottomSheet(context, '部位 3'),
                child: Icon(
                  Icons.location_on,
                  color: Colors.green,
                  size: 35,
                ),
              ),
              Text('部位 3', style: TextStyle(color: Colors.green, fontSize: 20)),
            ],
          ),
        ),
      ],
    );
  }
}

class AnatomicalMethodsList extends StatefulWidget {
  final List<String> favoriteMethods;
  final Function(String) onFavoriteToggle;

  AnatomicalMethodsList({
    required this.favoriteMethods,
    required this.onFavoriteToggle,
  });

  @override
  _AnatomicalMethodsListState createState() => _AnatomicalMethodsListState();
}

class _AnatomicalMethodsListState extends State<AnatomicalMethodsList> {
  List<String> allMethods = List.generate(10, (index) => '解剖方法 ${index + 1}');
  List<String> filteredMethods = [];

  @override
  void initState() {
    super.initState();
    filteredMethods = allMethods; // 初始状态下，显示全部方法
  }

  void _filterMethods(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredMethods = allMethods;
      } else {
        filteredMethods = allMethods
            .where((method) =>
                method.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            onChanged: (value) => _filterMethods(value),
            decoration: InputDecoration(
              labelText: '搜索解剖方法',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filteredMethods.length,
            itemBuilder: (context, index) {
              String method = filteredMethods[index];
              bool isFavorite = widget.favoriteMethods.contains(method);
              return ListTile(
                leading: Icon(Icons.book),
                title: Text(method),
                trailing: IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : null,
                  ),
                  onPressed: () => widget.onFavoriteToggle(method),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AnatomicalMethodDetailPage(
                        methodName: method,
                        methodDescription: '这是$method的详细介绍。',
                        isFavorite: isFavorite,
                        onFavoriteToggle: () => widget.onFavoriteToggle(method),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class FavoritesPage extends StatelessWidget {
  final List<String> favoriteMethods;
  final Function(String) onFavoriteToggle;

  FavoritesPage({
    required this.favoriteMethods,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: favoriteMethods.length,
      itemBuilder: (context, index) {
        String method = favoriteMethods[index];
        return ListTile(
          leading: Icon(Icons.book),
          title: Text(method),
          trailing: IconButton(
            icon: Icon(
              Icons.favorite,
              color: Colors.red,
            ),
            onPressed: () => onFavoriteToggle(method),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AnatomicalMethodDetailPage(
                  methodName: method,
                  methodDescription: '这是$method的详细介绍。',
                  isFavorite: true,
                  onFavoriteToggle: () => onFavoriteToggle(method),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class AnatomicalMethodDetailPage extends StatelessWidget {
  final String methodName;
  final String methodDescription;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  AnatomicalMethodDetailPage({
    required this.methodName,
    required this.methodDescription,
    required this.isFavorite,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(methodName),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : null,
            ),
            onPressed: onFavoriteToggle,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            height: 200,
            child: Center(child: Placeholder())
          ),
          SizedBox(height: 16),
          Text("这里是${methodName}的详细介绍。"),
        ],
      ),
    );
  }
}
  