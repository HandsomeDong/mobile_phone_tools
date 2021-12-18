import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:simple_permissions/simple_permissions.dart';
import 'dart:math';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:fijkplayer/fijkplayer.dart';


void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '七里翔的短视频下载工具',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('七里翔的短视频下载工具'),
        ),
        body: Center(
          child: ExampleWidget(),
        ),
      ),
    );
  }
}

/// Opens an [AlertDialog] showing what the user typed.
class ExampleWidget extends StatefulWidget {
  ExampleWidget({Key key}) : super(key: key);

  @override
  _ExampleWidgetState createState() => _ExampleWidgetState();
}

/// State for [ExampleWidget] widgets.
class _ExampleWidgetState extends State<ExampleWidget> {
  final TextEditingController _controller = TextEditingController();
  Permission permission1 = Permission.WriteExternalStorage;
  static final Random random = Random();
  String fileURL = "";
  final FijkPlayer player = FijkPlayer();

  @override
  void initState() {
    super.initState();
    player.setDataSource("");
  }


  @override
  void dispose() {
    super.dispose();
    player.release();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 300,
          height: 300,
          child: FijkView(
            player: player,
          ),
        ),
        TextField(
          controller: _controller,
          decoration: const InputDecoration(
            hintText: '粘贴分享链接',
          ),
        ),
        RaisedButton(
          onPressed: () async {
            var text = await Clipboard.getData(Clipboard.kTextPlain);
            _controller.text = text.text;
          },
          color: Colors.white,
          textColor: Colors.black,
          splashColor: Colors.blue,
          child: const Text('粘贴'),
        ),
        RaisedButton(
          onPressed: () async {
            _controller.text = "";
          },
          color: Colors.white,
          textColor: Colors.black,
          splashColor: Colors.blue,
          child: const Text('清空输入框'),
        ),
        RaisedButton(
          onPressed: () async {
            try {
              String res =  await (const MethodChannel("parseShareLink")).invokeMethod(_controller.text);
              String msg = res;
              if (res.startsWith("http")) {
                fileURL = res;
                showDefaultToast("解析成功！");
                setState(() {
                  player.reset();
                  player.setDataSource(fileURL, autoPlay: false, showCover: true);
                });
              } else {
                showDefaultToast(msg);
              }
            } catch (e) {
              showDefaultToast(e.message);
            }
          },
          color: Colors.green,
          textColor: Colors.white,
          splashColor: Colors.blue,
          child: const Text('解析'),
        ),
        RaisedButton(
          onPressed: () async {
            try {
              if (fileURL.startsWith("http")) {
                downloadFile();
              } else {
                showDefaultToast("解析失败！请重新解析！");
              }
            } catch (e) {
              showDefaultToast(e.message);
            }
          },
          color: Colors.green,
          textColor: Colors.white,
          splashColor: Colors.blue,
          child: const Text('下载视频'),
        ),
        RaisedButton(
          onPressed: () async {
            try {
              if (fileURL.startsWith("http")) {
                Clipboard.setData(ClipboardData(text: fileURL));
                showDefaultToast('七里翔提醒您，下载链接已复制到粘贴板，请到浏览器下载视频哦~');
              } else {
                showDefaultToast("解析失败！请重新解析！");
              }
            } catch (e) {
              showDefaultToast(e.message);
            }
          },
          color: Colors.green,
          textColor: Colors.white,
          splashColor: Colors.blue,
          child: const Text('复制下载链接'),
        ),
      ],
    );
  }

  Future<void> downloadFile() async {
    bool checkPermission1 =
    //1、权限检查
    await SimplePermissions.checkPermission(permission1);
    if (checkPermission1 == false) {
      await SimplePermissions.requestPermission(permission1);
      checkPermission1 = await SimplePermissions.checkPermission(permission1);
    }

    if (checkPermission1 == true) {
      try {
        var appDocDir = await getTemporaryDirectory();
        String savePath = appDocDir.path + "/" + (DateTime.now().millisecondsSinceEpoch).toString() + random.nextInt(100).toString() + ".mp4";
        await Dio().download(fileURL, savePath);
        final result = await ImageGallerySaver.saveFile(savePath);
        String msg;
        if (result['isSuccess']) {
          msg = "视频下载成功！快到相册里找找吧~";
        } else {
          msg = "视频下载失败！" + result['errorMessage'].toString();
        }
        showDefaultToast(msg);
      } catch (e) {
        showDefaultToast("下载失败！" + e.toString());
      }

    } else {
      showDefaultToast("下载失败！没有权限读写手机内存！");
    }
  }

  void showDefaultToast(String msg) {
    Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIos: 8,
      backgroundColor: Colors.grey[600], // 灰色背景
      fontSize: 20.0,
    );
  }
}

class VideoScreen extends StatefulWidget {
  String url;

  VideoScreen({Key key, this.url}) : super(key: key);

  @override
  _VideoScreenState createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  final FijkPlayer player = FijkPlayer();

  _VideoScreenState();

  @override
  void initState() {
    super.initState();
    player.setDataSource(widget.url, autoPlay: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
          alignment: Alignment.center,
          child: FijkView(
            player: player,
          ),
        ));
  }

  @override
  void dispose() {
    super.dispose();
    player.release();
  }
}