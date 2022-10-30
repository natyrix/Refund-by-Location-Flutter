import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:refund_location_mob_app/utils.dart';
import 'package:refund_location_mob_app/pages/mappage.dart';

void main() async {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Location DApp',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(
          color: whiteColor,
          foregroundColor: blackColor,
          iconTheme: IconThemeData(color: blackColor),
        ),
      ),
      home: const MyHomePage(title: 'Home'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String address = "";

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
          actions: [
            TextButton(
                onPressed: () {
                  if (address.isNotEmpty) {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => MapPage(address)));
                  }
                },
                child: const Text("Next"))
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    TextField(
                      style: const TextStyle(color: blackColor),
                      onChanged: (val) {
                        address = val;
                      },
                      decoration: textFieldInputDecorator.copyWith(
                        labelText: "Address:",
                      ),
                    ),
                  ])),
        ) // This trailing comma makes auto-formatting nicer for build methods.
        );
  }
}
