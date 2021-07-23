import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //自己建立Stream的話可以透過controller來製作
  //監控用戶按下數字鍵的Stream事件

  // 建立一個廣播型的StreamController for 小鍵盤
  // 小鍵盤在按下3的時候就會產生一個3的數據流
  final _inputController = StreamController.broadcast();
  final _scoreController = StreamController.broadcast();

  // int score = 0;

  // @override
  // void initState() {
  //   //開始監聽 _scoreController.stream
  //   // _scoreController.stream.listen((event) {
  //   //   setState(() {
  //   //     score +=event;
  //   //   });
  //   //
  //   //
  //   // });
  //   super.initState();
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: Text("Score: $score"),
        title: StreamBuilder(
            //利用StreamBuilder來監聽這個數據流裡的數據
            //分數控制器給我們的數據流被轉換了一下, 轉換出來之後就得到了新的數據流
            //StreamBuilder 在這邊監聽的是轉換後的Stream
            stream: _scoreController.stream.transform(TallyTransformer()),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Text("Score: ${snapshot.data}");
                // return Text("Score: ${snapshot.data}");
              }
              return Text("Score: 0");
            }),
      ),
      body: Stack(
        children: [
          //利用List.generate生成了5個Puzzle, 同時把_controller.stream也交給了Puzzle
          //Puzzle就能夠知道用戶按下了多少
          //...用於拆分list
          ...List.generate(
              15, (index) => Puzzle(_inputController.stream, _scoreController)),
          Align(
            alignment: Alignment.bottomCenter,
            child: KeyPad(_inputController, _scoreController),
          ),
        ],
      ),
    );
  }
}

class TallyTransformer implements StreamTransformer {
  int sum = 0;

  //需要讓別人來聽我們另一個stream
  StreamController _controller = StreamController();

  @override
  //bind 是數據流剛開始接入的時候
  Stream bind(Stream stream) {
    stream.listen((event) {
      sum += event;
      _controller.add(sum);
    });
    return _controller.stream;//回傳我們的controller的stream
  }

  @override
  StreamTransformer<RS, RT> cast<RS, RT>() => StreamTransformer.castFrom(this);
}

class Puzzle extends StatefulWidget {
  // const Puzzle({Key key}) : super(key: key);
  final inputStream;
  final scoreStream;

  Puzzle(this.inputStream, this.scoreStream);

  @override
  _PuzzleState createState() => _PuzzleState();
}

class _PuzzleState extends State<Puzzle> with SingleTickerProviderStateMixin {
  int a, b;
  Color color;
  double x;

  //AnimationController 不能在這邊初始化,
  // 因為會用到(vsync: this), 但因為this只能在initState或是function裡面存在.
  AnimationController _controller;

  reset([from = 0.0]) {
    a = Random().nextInt(5) + 1;
    b = Random().nextInt(5);
    x = Random().nextDouble() * 300;
    color = Colors.primaries[Random().nextInt(Colors.primaries.length)][200];
    _controller.duration =
        Duration(milliseconds: Random().nextInt(5000) + 5000);
    _controller.forward(from: from);
  }

  @override
  void initState() {
    //Optional 可選參數, [from = 0.0]沒設定的話就從0.0開始

    //_controller 運行起來之後, 其數值在0~1之間
    _controller = AnimationController(
      vsync: this,
    );

    reset(Random().nextDouble());
    // _controller.forward(from: 100);
    // _controller.forward(from: Random().nextDouble());

    //下落到最底下的時候就重新產生
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        reset();
        //事實上這裡不是真的加減分數, 而是添加事件, 添加一個-3的事件
        widget.scoreStream.add(-3);
      }
    });

    //如果用戶輸入正確的話, 也重新產生新的
    widget.inputStream.listen((input) {
      if (input == a + b) {
        reset();
        widget.scoreStream.add(5);
      }
    });

    super.initState();
  }

  //透過這個AnimatedBuilder讓物件有下落的效果
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      //為了要監聽_controller, 所以要用到AnimatedBuilder
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: x,
          // top: MediaQuery.of(context).size.height,
          top: 700 * _controller.value - 100,

          child: Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.5),
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(24),
            ),
            padding: EdgeInsets.all(8.0),
            child: Text(
              "$a + $b",
              style: TextStyle(fontSize: 24),
            ),
          ),
        );
      },
    );
  }
}

class KeyPad extends StatelessWidget {
  final _inputController;
  final _scoreController;

  KeyPad(this._inputController, this._scoreController);

  // const KeyPad({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      //如果不想要讓Container佔滿整個螢幕, 會壓縮成組件的大小
      padding: EdgeInsets.all(0.0),
      physics: NeverScrollableScrollPhysics(),
      //讓控件完全不能滾動
      childAspectRatio: 2 / 1,
      //改變GridView尺寸
      children: List.generate(9, (index) {
        return TextButton(
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(), //取消按鍵的圓角邊
            backgroundColor: Colors.primaries[index][200],
            primary: Colors.black,
          ),
          child: Text("${index + 1}", style: TextStyle(fontSize: 24)),
          onPressed: () {
            _inputController.add(index + 1);
            _scoreController.add(-2);
          },
        );
      }),
    );
  }
}
