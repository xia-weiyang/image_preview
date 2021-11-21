import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_preview/image_preview.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _imageUrls = <String>[
    'https://xia-weiyang.github.io/image/2.jpg',
    'https://xia-weiyang.github.io/image/1_thumbnail.jpg',
    'https://xia-weiyang.github.io/image/3.jpg',
  ];

  final _imageOriginalUrls = <String>[
    '',
    'https://xia-weiyang.github.io/image/1.jpg',
    'https://xia-weiyang.github.io/image/3.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          // Column is also layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: _imageUrls.map<Widget>((url) {
            final i = _imageUrls.indexOf(url);
            return Hero(
              child: GestureDetector(
                child: CachedNetworkImage(
                  imageUrl: url,
                ),
                onTap: () {
                  openImagesPage(Navigator.of(context),
                      imgUrls: _imageUrls,
                      imgOriginalUrls: _imageOriginalUrls,
                      index: i,
                      heroTags: _imageUrls,
                      onLongPressHandler: (con, url) => debugPrint(url),
                      onPageChanged: (i, widget) async {
                        if (widget != null) return widget;
                        await Future.delayed(const Duration(seconds: 3));
                        return i > 1
                            ? null
                            : const Text(
                          '图片描述信息',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        );
                      });
                },
              ),
              tag: url,
            );
          }).toList(),
        ),
      ),
    );
  }
}
