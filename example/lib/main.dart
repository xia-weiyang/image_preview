import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_preview/preview.dart';
import 'package:image_preview/preview_data.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<PreviewData> dataList = [];

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      String path = '';
      if (!kIsWeb) {
        if (Platform.isAndroid) {
          path = ((await getExternalCacheDirectories())![0]).path;
        } else {
          path = (await getTemporaryDirectory()).path;
        }
      }
      final temp = [
        PreviewData(
          type: Type.image,
          heroTag: 'b53764c82a1940',
          image: ImageData(
            url: 'https://xia-weiyang.github.io/image/1.jpg',
            path: '$path/image/1.jpg',
            thumbnailUrl: 'https://xia-weiyang.github.io/image/1_thumbnail.jpg',
            thumbnailPath: '$path/image/1_thumbnail.jpg',
          ),
        ),
        PreviewData(
          type: Type.video,
          heroTag: 'c53764c82a1940',
          video: VideoData(
              coverUrl: 'https://xia-weiyang.github.io/image/2.jpg',
              coverPath: '$path/image/2.jpg',
              url: 'https://file.jiushig.com/content/mood/9715/video/d6d15c02d44e4eed8190456f66255a5a.mov'),
        ),
        PreviewData(
          type: Type.image,
          heroTag: '112cc8a34e13',
          image: ImageData(
            url: 'https://xia-weiyang.github.io/image/3.jpg',
            path: '$path/image/3.jpg',
            thumbnailUrl: 'https://xia-weiyang.github.io/image/3.jpg',
            thumbnailPath: '$path/image/3.jpg',
          ),
        ),
      ];
      setState(() {
        dataList.addAll(temp);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: dataList.map<Widget>((preview) {
            final i = dataList.indexOf(preview);
            return SizedBox(
              width: double.infinity,
              height: 240,
              child: PreviewThumbnail(
                data: dataList[i],
                onTap: () {
                  openPreviewPages(
                    Navigator.of(context),
                    data: dataList,
                    index: i,
                    indicator: kIsWeb ||
                        Platform.isMacOS ||
                        Platform.isWindows ||
                        Platform.isLinux,
                    tipWidget: (currentIndex) {
                      return Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: EdgeInsets.only(
                              top: MediaQuery.of(context).padding.top + 16,
                              right: 32),
                          child: InkWell(
                            onTap: () {
                              debugPrint('tap tip $currentIndex');
                            },
                            child: Text(
                              '${currentIndex + 1}/${dataList.length}',
                              style:
                                  TextStyle(color: Colors.white.withAlpha(180)),
                            ),
                          ),
                        ),
                      );
                    },
                    onLongPressHandler: (con, url) =>
                        debugPrint(preview.image?.url),
                    onPageChanged: (i) async {
                      debugPrint('onPageChanged $i');
                    },
                  );
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
