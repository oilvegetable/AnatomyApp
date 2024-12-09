import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'global.dart';

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
    Navigator.pop(context); // 关闭抽弧菜单
  }

  void _toggleFavorite(String methodId) {
    setState(() {
      if (favoriteMethods.contains(methodId)) {
        favoriteMethods.remove(methodId);
      } else {
        favoriteMethods.add(methodId);
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
  _Anatomical3DModule createState() => _Anatomical3DModule();
}

class _Anatomical3DModule extends State<Anatomical3DModule> {
  late WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    // 初始化 WebViewController
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)  // 允许 JavaScript
      ..loadRequest(Uri.parse(unity_url));  // 加载 URL
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _webViewController);
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
  late Future<Map<String, List<Map<String, dynamic>>>> _methodsByLocation;

  @override
  void initState() {
    super.initState();
    _methodsByLocation = fetchMethodsByLocation();
  }

  Future<Map<String, List<Map<String, dynamic>>>> fetchMethodsByLocation() async {
    final response = await http.get(Uri.parse(server_url + '/api/files/all'));

    if (response.statusCode == 200) {
      List<dynamic> methods = json.decode(response.body);
      Map<String, List<Map<String, dynamic>>> categorizedMethods = {};

      for (var method in methods) {
        String location = method['location'];
        categorizedMethods.putIfAbsent(location, () => []);
        categorizedMethods[location]!.add(method);
      }

      for (var methodList in categorizedMethods.values) {
        methodList.sort((a, b) => a['priority'].compareTo(b['priority']));
      }

      return categorizedMethods;
    } else {
      throw Exception('Failed to load methods');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
      future: _methodsByLocation,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Failed to load methods'));
        } else {
          Map<String, List<Map<String, dynamic>>> methodsByLocation = snapshot.data!;
          return ListView(
            children: methodsByLocation.entries.map((entry) {
              String location = entry.key;
              List<Map<String, dynamic>> methods = entry.value;

              return ExpansionTile(
                title: Text(location),
                children: methods.map((method) {
                  bool isFavorite = widget.favoriteMethods.contains(method['file_id']);
                  return ListTile(
                    title: Text(method['filename']),
                    trailing: IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : null,
                      ),
                      onPressed: () => widget.onFavoriteToggle(method['file_id']),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AnatomicalMethodDetailPage(
                            methodDetail: method,
                            isFavorite: isFavorite,
                            onFavoriteToggle: () => widget.onFavoriteToggle(method['file_id']),
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              );
            }).toList(),
          );
        }
      },
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

  Future<List<Map<String, dynamic>>> fetchFavoriteMethods(List<String> favoriteMethods) async {
    final response = await http.get(Uri.parse(server_url + '/api/files/all'));

    if (response.statusCode == 200) {
      List<dynamic> methods = json.decode(response.body);
      List<Map<String, dynamic>> favoriteMethodsList = methods
          .where((method) => favoriteMethods.contains(method['file_id']))
          .map((method) => method as Map<String, dynamic>)
          .toList();
      return favoriteMethodsList;
    } else {
      throw Exception('Failed to load favorite methods');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchFavoriteMethods(favoriteMethods),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Failed to load favorite methods'));
        } else {
          List<Map<String, dynamic>> favorites = snapshot.data!;
          return ListView.builder(
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              var method = favorites[index];
              return ListTile(
                title: Text(method['filename']),
                trailing: IconButton(
                  icon: Icon(
                    Icons.favorite,
                    color: Colors.red,
                  ),
                  onPressed: () => onFavoriteToggle(method['file_id']),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AnatomicalMethodDetailPage(
                        methodDetail: method,
                        isFavorite: true,
                        onFavoriteToggle: () => onFavoriteToggle(method['file_id']),
                      ),
                    ),
                  );
                },
              );
            },
          );
        }
      },
    );
  }
}

class AnatomicalMethodDetailPage extends StatelessWidget {
  final Map<String, dynamic> methodDetail;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  AnatomicalMethodDetailPage({
    required this.methodDetail,
    required this.isFavorite,
    required this.onFavoriteToggle,
  });

  Map _getTextStyleFromStyle(String styleName) {
    // 根据 Word 样式名返回不同的 TextStyle
    switch (styleName) {
      case 'Heading 1':
        return {
          'fontSize': 32.0,
          'fontWeight': FontWeight.bold,
          'color': const Color.fromARGB(255, 47, 156, 246),
        };
      case 'Heading 2':
        return {
          'fontSize': 28.0,
          'fontWeight': FontWeight.bold,
          'color': Colors.black,
        };
      case 'Heading 3':
        return {
          'fontSize': 24.0,
          'fontWeight': FontWeight.bold,
          'color': Colors.black,
        };
      case 'Normal':
        return {
          'fontSize': 14.0,
          'fontWeight': FontWeight.normal,
          'fontStyle': FontStyle.normal,
          'color': Colors.black,
        };
      case 'Subtitle':
        return {
          'fontSize': 18.0,
          'fontStyle': FontStyle.italic,
          'color': Colors.grey,
        };
      // 如果你有更多的自定义样式，可以继续添加
      default:
        return {
          'fontSize': 14.0,
          'fontWeight': FontWeight.normal,
          'fontStyle': FontStyle.normal,
          'color': _getColorFromRGBString([0,0,0]),
        };
    }
  }

  // 根据 alignment 字符串值返回对应的 Alignment
  Alignment _getAlignment(int? alignment) {
    switch (alignment) {
      case 1:
        return Alignment.center;
      case 2:
        return Alignment.centerRight;
      default:
        return Alignment.centerLeft;
    }
  }

    Color _getColorFromRGBString(List colorParts) {

    if (colorParts.length == 3) {
      // 将 RGB 转为十六进制并返回颜色值
      return Color.fromRGBO(colorParts[0], colorParts[1], colorParts[2], 1.0);
    } else {
      // 如果解析失败，返回默认颜色
      return Colors.black;
    }
  }

  List<Widget> buildParagraphs(List<dynamic> content) {
    List<Widget> widgets = [];

    for (var paragraph in content) {
      List<InlineSpan> textSpans = [];
      String text = paragraph['text'] ?? '';
      Map textStyle = _getTextStyleFromStyle(paragraph['style']) ;

      int start = 0;
      String textBefore;

      for (var image in paragraph['images']){
        var splitPoint = image['position_in_paragraph'];
        if (splitPoint > text.length) break;

        textBefore = text.substring(start, splitPoint);
        text = text.substring(splitPoint);
        start = splitPoint;

        textSpans.add(TextSpan(
          text: textBefore,
          style: TextStyle(
            fontWeight: paragraph['font']['bold'] == true ? FontWeight.bold : textStyle['fontWeight'],
            fontStyle: paragraph['font']['italic'] == true ? FontStyle.italic : textStyle['fontStyle'],
            decoration: paragraph['font']['underline'] == true ? TextDecoration.underline : TextDecoration.none,
            fontSize: paragraph['font']['size'] != null ? paragraph['font']['size'] : textStyle['fontSize'],
            color: paragraph['font']['color'] != null 
              ? _getColorFromRGBString(paragraph['font']['color']) // 使用转换方法
              : textStyle['fontColor'],
            fontFamily: paragraph['font']['name'],
          ),
          
        ));

        textSpans.add(WidgetSpan(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Image.network(
                server_url + image['image_link'],  // 这里是图片链接
                loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  } else {
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                            : null,
                      ),
                    );
                  }
                },
                errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                  return Icon(Icons.error, color: Colors.red);
                },
              ),
            ),
          ));
      }
      // 循环结束后补上最后一段文字
      textSpans.add(TextSpan(
        text: text,
        style: TextStyle(
            fontWeight: paragraph['font']['bold'] == true ? FontWeight.bold : textStyle['fontWeight'],
            fontStyle: paragraph['font']['italic'] == true ? FontStyle.italic : textStyle['fontStyle'],
            decoration: paragraph['font']['underline'] == true ? TextDecoration.underline : TextDecoration.none,
            fontSize: paragraph['font']['size'] != null ? paragraph['font']['size'] : textStyle['fontSize'],
            color: paragraph['font']['color'] != null 
              ? _getColorFromRGBString(paragraph['font']['color']) // 使用转换方法
              : textStyle['fontColor'],
            fontFamily: paragraph['font']['name'],
            letterSpacing: paragraph['font']['strikethrough'] == true ? 2.0 : 0.0, // Example for strikethrough effect
        ),
      ));

      // 用 Text.rich 显示文本和图片
      widgets.add(Align(
        alignment: _getAlignment(paragraph['alignment']),
        child: Text.rich(
          TextSpan(
            children: textSpans,
          ),
        ),
      ));
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('方法详情'),
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
      body: ListView(
        padding: EdgeInsets.all(16),
        children: buildParagraphs(methodDetail['content']), 
      ),
    );
  }
}
