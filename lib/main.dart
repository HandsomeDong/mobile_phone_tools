import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:simple_permissions/simple_permissions.dart';
import 'package:file_utils/file_utils.dart';
import 'dart:math';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';



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

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
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
                downloadFile();
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
          child: const Text('解析并下载'),
        ),
        RaisedButton(
          onPressed: () async {
            try {
              String res = await (const MethodChannel("parseShareLink")).invokeMethod(_controller.text);
              String msg = res;
              if (res.startsWith("http")) {
                Clipboard.setData(ClipboardData(text: res));
                msg = '七里翔提醒您，下载链接已复制到粘贴板，请到浏览器下载视频哦~';
              }
              showDefaultToast(msg);
            } catch (e) {
              showDefaultToast(e.message);
            }
          },
          color: Colors.green,
          textColor: Colors.white,
          splashColor: Colors.blue,
          child: const Text('解析并获取下载链接'),
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
        // Directory directory = Directory((await getApplicationDocumentsDirectory()).path);
        //
        // Directory directoryRes;
        // //2、创建文件夹
        // if (!(await directory.exists())) {
        //   directoryRes = await directory.create(recursive: true);
        // }
        //
        // String filePath = directory.path + "/" + (DateTime.now().millisecondsSinceEpoch).toString() + random.nextInt(100).toString() + ".mp4";
        //
        // //3、使用 dio 下载文件
        // await dio.download(fileURL, filePath,
        //     onReceiveProgress: (receivedBytes, totalBytes) {
        //       if (receivedBytes/totalBytes == 1) {
        //         print(receivedBytes.toString() + "/" + totalBytes.toString());
        //         Fluttertoast.showToast(
        //           msg: "视频下载完毕~存储在：" + filePath,
        //           toastLength: Toast.LENGTH_SHORT,
        //           gravity: ToastGravity.BOTTOM,
        //           timeInSecForIos: 8,
        //           backgroundColor: Colors.grey[600], // 灰色背景
        //           fontSize: 20.0,
        //         );
        //       }
        //     });

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

class VideoPlayerApp extends StatelessWidget {
  const VideoPlayerApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Video Player Demo',
      home: VideoPlayerScreen(),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({Key key}) : super(key: key);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
   VideoPlayerController _controller;
   Future<void> _initializeVideoPlayerFuture;
   String videoUrl;

  @override
  void initState() {
    // Create and store the VideoPlayerController. The VideoPlayerController
    // offers several different constructors to play videos from assets, files,
    // or the internet.
    _controller = VideoPlayerController.network(
      videoUrl,
    );

    // Initialize the controller and store the Future for later use.
    _initializeVideoPlayerFuture = _controller.initialize();

    // Use the controller to loop the video.
    _controller.setLooping(true);

    super.initState();
  }

  @override
  void dispose() {
    // Ensure disposing of the VideoPlayerController to free up resources.
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Butterfly Video'),
      ),
      // Use a FutureBuilder to display a loading spinner while waiting for the
      // VideoPlayerController to finish initializing.
      body: FutureBuilder(
        future: _initializeVideoPlayerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the VideoPlayerController has finished initialization, use
            // the data it provides to limit the aspect ratio of the video.
            return AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              // Use the VideoPlayer widget to display the video.
              child: VideoPlayer(_controller),
            );
          } else {
            // If the VideoPlayerController is still initializing, show a
            // loading spinner.
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Wrap the play or pause in a call to `setState`. This ensures the
          // correct icon is shown.
          setState(() {
            // If the video is playing, pause it.
            if (_controller.value.isPlaying) {
              _controller.pause();
            } else {
              // If the video is paused, play it.
              _controller.play();
            }
          });
        },
        // Display the correct icon depending on the state of the player.
        child: Icon(
          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }
}