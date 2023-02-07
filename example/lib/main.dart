import 'package:dio/dio.dart';
import 'package:dio_cookie_caching_handler/dio_cookie_caching_handler.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final Dio _dio;
  Map<String, dynamic> _fetchedData = {};

  @override
  void initState() {
    _initDio();
    super.initState();
  }

  void _initDio() {
    _dio = Dio();
    _dio.interceptors.add(cookieCachedHandler());
  }

  void _fetchSomeData() {
    _dio.get("https://reqres.in/api/users/2").then((value) {
      setState(() {
        _fetchedData = value.data;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              _fetchedData.entries.map((e) => "${e.key}:${e.value}").join("\n"),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchSomeData,
        tooltip: 'Fetch',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
