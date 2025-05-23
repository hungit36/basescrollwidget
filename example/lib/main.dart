import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:async';
import 'package:basescrollview/basescrollview.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _getData();
  }

  bool _isLoading = true;
  bool _isLoadMore = false;

  Timer? _timer;

  final int _maxRow = 50;
  int _index = 1;

  List<String> _items = [];

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        _isLoading = false;
        LoadingStatusStream.instance.update(false);
      });
    });
  }

  void _getData({bool isReload = true}) {
    if (_items.length == _maxRow && !isReload) return;
    LoadingStatusStream.instance.update(true);
    _isLoading = isReload;
    if (isReload) {
      _index = 1;
    }
    if (_index == 1) {
      _items = List<String>.generate(10, (index) => index.toString());
    } else {
      int i = 0;
      while(i < 10) {
        _items.add(_items.length.toString());
        i += 1;
      }
    }
    _isLoadMore = _items.length < _maxRow;
    if (_isLoadMore) {
      _index += 1;
    }
    setState(() {});
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('BaseScrollView'),
        ),
        body: BaseScrollView(
          isEnableRefreshIndicator: false,
          indicatorColor: Colors.black87,
          indicatorActiveColor: Colors.blue,
          imageLoading: 'assets/images/loading.svg',
          loadingString:'Loading...',
          angle: pi/2,
          style: LoadingStyle.rotateAndopacity,
          onRefresh: _onScrollToTop,
          onLoadMore: _onScrollToBottom,
          onScrollUpdate: _onScrollUpdate,
          child: LayoutBuilder(
            builder: (context, constraints) => ListView.builder(
              padding: const EdgeInsets.all(16.0),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _items.length + (_items.isNotEmpty ? 1 : 0),
              itemBuilder: (context, index) => index < _items.length ? Container(
                      height: constraints.maxHeight / 10 - 10,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(child: Text('Item ${_items[index]}')),
                      ),
                      ) : _items.length > 9 ? Container(
                        padding: const EdgeInsets.all(10),
                        child: Center(
                          child: _isLoadMore
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.blue.shade100,
                                    backgroundColor: Colors.blue.shade600,
                                  ),
                                )
                              : const Text("That's all!"),
                        ),
                      ) : const SizedBox(),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onScrollToTop() async {
    print('_onScrollToTop');
    _getData();
  }

  Future<void> _onScrollUpdate(ScrollDirection scrollDirection, double position) async {
    print('_onUpdateScroll direction $scrollDirection at $position');
  }

  Future<void> _onScrollToBottom() async {
    print(_onScrollToBottom);
    _getData(isReload: false);
  }
}
