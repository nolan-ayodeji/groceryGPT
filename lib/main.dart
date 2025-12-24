// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import 'loginpage.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

String theRoom = '200';
String globcat = "Other";
bool notInRoom = true;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [
    SystemUiOverlay.top,
    SystemUiOverlay.bottom,
  ]);
  await Firebase.initializeApp();
  runApp(
    ChangeNotifierProvider(
      create: (context) => GroceryProvider(roomId: '200'),
      child: const MyApp(),
    ),
  );
}

class Grocery {
  String name;
  bool needed;
  int quantity;
  String type;

  Grocery({
    required this.name,
    required this.type,
    this.needed = true,
    this.quantity = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'needed': needed,
      'quantity': quantity,
      'name_lower': name.trim().toLowerCase(),
      'type': type,
    };
  }

  static Grocery fromMap(Map<String, dynamic> map) {
    return Grocery(
      name: map['name'],
      needed: map['needed'],
      quantity: map['quantity'],
      type: map['type'],
    );
  }
}

class GroceryProvider with ChangeNotifier {
  final List<Grocery> _groceries = [];
  final String roomId;
  // Change this to switch rooms

  List<Grocery> get groceries => _groceries;

  GroceryProvider({required this.roomId}) {
    fetchGroceries();
  }

  Future<void> fetchGroceries() async {
    print('GROCERIES ARE BEING FETCHED HERE ARE THE LISTS');
    print(_groceries.map((g) => g.name).toList());
    print(_groceries.map((g) => g.needed).toList());
    final CollectionReference collection = FirebaseFirestore.instance
        .collection('groceryRooms')
        .doc(roomId)
        .collection('groceries');

    final snapshot =
        await collection.orderBy('createdAt', descending: false).get();
    _groceries.clear();

    for (var doc in snapshot.docs) {
      Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
      print("firebase: " + data.toString());
      _groceries.add(Grocery.fromMap(doc.data() as Map<String, dynamic>));
    }

    notifyListeners();
  }

  Stream<List<Grocery>> get groceriesStream {
    final CollectionReference collection = FirebaseFirestore.instance
        .collection('groceryRooms')
        .doc(roomId)
        .collection('groceries');

    return collection
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Grocery.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  void addGrocery(String name) async {
    final newGrocery = Grocery(name: name, type: globcat);
    _groceries.insert(0, newGrocery);
    print('the room');
    print(roomId);

    final CollectionReference collection = FirebaseFirestore.instance
        .collection('groceryRooms')
        .doc(roomId)
        .collection('groceries');

    final groceryData = newGrocery.toMap();

    // Add the server timestamp to the map before writing to Firestore
    groceryData['createdAt'] = FieldValue.serverTimestamp();

    // Add the document to Firestore with the timestamp
    await collection.add(groceryData);
    fetchGroceries();

    notifyListeners();
  }

  void removeGrocery(int index) async {
    final grocery = _groceries[index];

    final CollectionReference collection = FirebaseFirestore.instance
        .collection('groceryRooms')
        .doc(roomId)
        .collection('groceries');

    final QuerySnapshot snapshot = await collection
        .where('name', isEqualTo: grocery.name)
        .where('quantity', isEqualTo: grocery.quantity)
        .where('needed', isEqualTo: grocery.needed)
        .get();

    if (snapshot.docs.isNotEmpty) {
      await collection.doc(snapshot.docs[0].id).delete();
    }

    _groceries.removeAt(index);
    fetchGroceries();
    notifyListeners();
  }

  void increaseQuantity(int index) async {
    print(_groceries.map((g) => g.name).toList());
    print(_groceries.map((g) => g.needed).toList());
    final grocery = _groceries[index];
    grocery.quantity++;

    final CollectionReference collection = FirebaseFirestore.instance
        .collection('groceryRooms')
        .doc(roomId)
        .collection('groceries');

    final QuerySnapshot snapshot = await collection
        .where('name', isEqualTo: grocery.name)
        .where('quantity', isEqualTo: grocery.quantity - 1)
        .where('needed', isEqualTo: grocery.needed)
        .get();

    if (snapshot.docs.isNotEmpty) {
      await collection
          .doc(snapshot.docs[0].id)
          .update({'quantity': grocery.quantity});
    }

    notifyListeners();
  }

  void decreaseQuantity(int index) async {
    print('decreasequnaitty');
    final grocery = _groceries[index];
    if (grocery.quantity > 0) {
      grocery.quantity--;

      final CollectionReference collection = FirebaseFirestore.instance
          .collection('groceryRooms')
          .doc(roomId)
          .collection('groceries');

      final QuerySnapshot snapshot = await collection
          .where('name', isEqualTo: grocery.name)
          .where('quantity', isEqualTo: grocery.quantity + 1)
          .where('needed', isEqualTo: grocery.needed)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await collection
            .doc(snapshot.docs[0].id)
            .update({'quantity': grocery.quantity});
      }
      notifyListeners();
    }
  }

  void toggleNeeded(int index) async {
    print('toggleneeded');
    final grocery = _groceries[index];
    grocery.needed = !grocery.needed;

    final CollectionReference collection = FirebaseFirestore.instance
        .collection('groceryRooms')
        .doc(roomId)
        .collection('groceries');

    final QuerySnapshot snapshot = await collection
        .where('name', isEqualTo: grocery.name)
        .where('quantity', isEqualTo: grocery.quantity)
        .where('needed', isEqualTo: !grocery.needed)
        .get();

    if (snapshot.docs.isNotEmpty) {
      await collection
          .doc(snapshot.docs[0].id)
          .update({'needed': grocery.needed});
    }

    notifyListeners();
  }

  void setNeededNot(int index) async {
    print('setneededNot');
    final grocery = _groceries[index];

    // Map the _groceries list to a list of names and print it
    print(_groceries.map((g) => g.name).toList());
    print(_groceries.map((g) => g.needed).toList());

    grocery.needed = !grocery.needed;
    print(grocery.name);
    print('IS BEING PRESSED');

    final CollectionReference collection = FirebaseFirestore.instance
        .collection('groceryRooms')
        .doc(roomId)
        .collection('groceries');

    final QuerySnapshot snapshot = await collection
        .where('name', isEqualTo: grocery.name)
        .where('quantity', isEqualTo: grocery.quantity)
        .where('needed', isEqualTo: !grocery.needed)
        .get();

    if (snapshot.docs.isNotEmpty) {
      await collection
          .doc(snapshot.docs[0].id)
          .update({'needed': grocery.needed});
    }

    //_groceries.removeAt(index);
    //if (grocery.needed) {
    //_groceries.insert(0, grocery);
    //} else {
    //_groceries.add(grocery);
    //}

    fetchGroceries();
    notifyListeners();
  }

  void set(int index) async {
    final grocery = _groceries[index];
    grocery.needed = false;

    final CollectionReference collection = FirebaseFirestore.instance
        .collection('groceryRooms')
        .doc(roomId)
        .collection('groceries');

    final QuerySnapshot snapshot = await collection
        .where('name', isEqualTo: grocery.name)
        .where('quantity', isEqualTo: grocery.quantity)
        .where('needed', isEqualTo: !grocery.needed)
        .get();

    if (snapshot.docs.isNotEmpty) {
      await collection
          .doc(snapshot.docs[0].id)
          .update({'needed': grocery.needed});
    }

    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: MyHomePage(title: 'Flutter Demo Homee Page', roomId: '200'),
      initialRoute: notInRoom ? '/login' : '/home',
      routes: {
        loginPage.route: (context) => loginPage(),
        '/home': (context) =>
            const MyHomePage(title: 'Flutter Demo Home Page', roomId: '200'),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String roomId; // Add this line
  const MyHomePage(
      {super.key,
      required this.title,
      required this.roomId}); // Modify this line

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();
  final CollectionReference collection =
      FirebaseFirestore.instance.collection('testCollection');

  int _counter = 0;

  final List<String> _cats = [
    "Produce",
    "Dairy",
    "Meat & Seafood",
    "Pantry",
    "Frozen",
    "Beverages",
    "Household",
    "Snacks/Sweets",
    "Other"
  ];
  final List<bool> _catsbool = [
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    true,
  ];

  final List<bool> _catsbool2 = [true];

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void setCat(int ind) {
    for (int i = 0; i <= 8; i++) {
      if (i == ind) {
        setState(() {
          _catsbool[i] = true;
        });
      } else
        setState(() {
          _catsbool[i] = false;
        });
    }
  }

  void exitRoom() {
    Navigator.pushNamed(context, '/login');
  }

  void testing() {
    print("tester");
  }

  Future<String> fetchPassword() async {
    String result;
    try {
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('groceryRooms')
          .doc('200')
          .get();
      if (documentSnapshot.exists) {
        result = documentSnapshot
            .get('password')
            .toString(); // Ensure the field name is correct
      } else {
        result = 'Document does not exist';
      }
    } catch (e) {
      result = 'Error fetching password: $e';
    }

    //print(result);  // Print "hi" every time before repeating the function

    return result;
  }

  bool vis = false;

  final ScrollController _scrollController = ScrollController();

  void setvis() {
    if (vis == true) {
      setState(() {
        vis = false;
        print('setting visibility to false');
      });
    } else {
      setState(() {
        vis = true;
        print('setting visibility to true');
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      // Subtract a small amount to avoid the bounce
      final maxScroll = _scrollController.position.maxScrollExtent;
      _scrollController.animateTo(
        maxScroll - 100, // Subtract 10 pixels to avoid bounce
        duration: Duration(milliseconds: 30),
        curve: Curves.easeOut,
      );
    }
  }

  void _addGrocery() {
    print("adding grocery");
    FocusScope.of(context).unfocus();

    final provider = Provider.of<GroceryProvider>(context, listen: false);
    if (_controller.text.isNotEmpty) {
      provider.addGrocery(_controller.text);
      _controller.clear();
    }

    //_scrollToBottom();
  }

  void _removeGrocery(int Index) {
    final provider = Provider.of<GroceryProvider>(context, listen: false);
    provider.removeGrocery(Index);
    print("removing grocery");
  }

  void _move(int Index) {
    final provider = Provider.of<GroceryProvider>(context, listen: false);
    provider.setNeededNot(Index);
  }

  void _add(int Index) {
    final provider = Provider.of<GroceryProvider>(context, listen: false);
    provider.increaseQuantity(Index);
  }

  void _remove(int Index) {
    final provider = Provider.of<GroceryProvider>(context, listen: false);
    provider.decreaseQuantity(Index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          hilly(),
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black12,
          ),
          ShaderMask(
            shaderCallback: (Rect rect) {
              return LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: const [
                  Colors.purple,
                  Colors.transparent,
                  Colors.transparent,
                  Colors.purple
                ],
                stops: [
                  0.03,
                  0.11,
                  WidgetsBinding.instance.window.viewInsets.bottom > 300.0
                      ? 0.30
                      : 0.61,
                  WidgetsBinding.instance.window.viewInsets.bottom > 300.0
                      ? 0.50
                      : 0.83,
                ], // 10% purple, 80% transparent, 10% purple
              ).createShader(rect);
            },
            blendMode: BlendMode.dstOut,
            child: Align(
              child: StreamBuilder<List<Grocery>>(
                stream: Provider.of<GroceryProvider>(context, listen: false)
                    .groceriesStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final groceries = snapshot.data!;

                  return groceries.isEmpty
                      ? Visibility(
                          visible:
                              WidgetsBinding.instance.window.viewInsets.bottom >
                                      100.0
                                  ? false
                                  : true,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'No Groceries Added',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    shadows: <Shadow>[
                                      Shadow(
                                        offset: Offset(0.0, 1.5),
                                        blurRadius: 8.0,
                                        color: Colors.black38,
                                      ),
                                    ],
                                    fontSize: 35,
                                    fontFamily: 'Schyler',
                                  ),
                                ),
                                SizedBox(
                                  height: 4,
                                ),
                                Text(
                                  'Type then Press the + button below to add a grocery.',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white70,
                                    shadows: <Shadow>[
                                      Shadow(
                                        offset: Offset(0.0, 1.5),
                                        blurRadius: 8.0,
                                        color: Colors.black38,
                                      ),
                                    ],
                                    fontSize: 13,
                                    fontFamily: 'Schyler',
                                  ),
                                ),
                                SizedBox(
                                  height: 4,
                                ),
                                StreamBuilder<DocumentSnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('groceryRooms')
                                      .doc(Provider.of<GroceryProvider>(context)
                                          .roomId)
                                      .snapshots(),
                                  builder: (BuildContext context,
                                      AsyncSnapshot<DocumentSnapshot>
                                          snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Text('Loading password...');
                                    } else if (snapshot.hasError) {
                                      return Text('Error: ${snapshot.error}');
                                    } else if (!snapshot.hasData ||
                                        !snapshot.data!.exists) {
                                      return Text('Document does not exist');
                                    } else {
                                      String password = snapshot.data!
                                          .get('password')
                                          .toString();
                                      String roomCode = snapshot.data!.id;
                                      return Text(
                                        'Room Code: $roomCode | Room Password: $password',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: Colors.lightGreenAccent,
                                          shadows: <Shadow>[
                                            Shadow(
                                              offset: Offset(0.0, 1.5),
                                              blurRadius: 8.0,
                                              color: Colors.black38,
                                            ),
                                          ],
                                          fontSize: 16,
                                          fontFamily: 'Schyler',
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.only(top: 65.0, bottom: 220.0),
                          itemCount: groceries.length,
                          itemBuilder: (BuildContext context, int index) {
                            return widgetone(
                              text1: groceries[index].name.toString(),
                              text2: groceries[index].quantity.toString(),
                              text3: groceries[index].type.toString(),
                              onTap: () => _removeGrocery(index),
                              onTap2: () {
                                _move(index);
                              },
                              onTap3: () {
                                _add(index);
                              },
                              onTap4: () {
                                _remove(index);
                              },
                              key: ValueKey(index),
                              need: groceries[index].needed,
                              textColor: groceries[index].needed == true
                                  ? Colors.white
                                  : Colors.black38,
                              optacity:
                                  groceries[index].needed == true ? 1.0 : 0.7,
                            );
                          },
                        );
                },
              ),
            ),
          ),
          Column(
            children: [
              Spacer(),
              // StreamBuilder<List<Grocery>>(
              //   stream: Provider.of<GroceryProvider>(context, listen: false)
              //       .groceriesStream,
              //   builder: (context, snapshot) {
              //     if (!snapshot.hasData) {
              //       return Center(
              //         child: CircularProgressIndicator(),
              //       );
              //     }
              //
              //     final groceries = snapshot.data!;
              //
              //     return Visibility(
              //       visible: groceries.isEmpty
              //           ? false : true,
              //
              //       child: StreamBuilder<DocumentSnapshot>(
              //         stream: FirebaseFirestore.instance
              //             .collection('groceryRooms')
              //             .doc(Provider.of<GroceryProvider>(context).roomId)
              //             .snapshots(),
              //         builder: (BuildContext context,
              //             AsyncSnapshot<DocumentSnapshot> snapshot) {
              //           if (snapshot.connectionState == ConnectionState.waiting) {
              //             return Text('Loading password...');
              //           } else if (snapshot.hasError) {
              //             return Text('Error: ${snapshot.error}');
              //           } else if (!snapshot.hasData || !snapshot.data!.exists) {
              //             return Text('Document does not exist');
              //           } else {
              //             String password = snapshot.data!.get('password').toString();
              //             String roomCode = snapshot.data!.id;
              //             return Text(
              //               'Room Code: $roomCode | Room Password: $password',
              //               style: TextStyle(
              //                 fontWeight: FontWeight.w900,
              //                 color: Colors.white70,
              //                 shadows: <Shadow>[
              //                   Shadow(
              //                     offset: Offset(0.0, 1.5),
              //                     blurRadius: 8.0,
              //                     color: Colors.black38,
              //                   ),
              //                 ],
              //                 fontSize: 13,
              //                 fontFamily: 'Schyler',
              //               ),
              //             );
              //           }
              //         },
              //       ),
              //     );
              //   },
              // ),
              Container(
                child: WidgetsBinding.instance.window.viewInsets.bottom > 100.0
                    ? Container(
                        width: MediaQuery.of(context).size.width / 1.2,
                        height: 180,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                for (int i = 0; i < 3; i++)
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: InkWell(
                                        child: catItem(
                                          txt: _cats[i],
                                          toshow: _catsbool[i],
                                          callbck: () {
                                            setState(() {
                                              globcat = _cats[i];
                                              setCat(i);
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            Row(
                              children: [
                                for (int i = 3; i < 6; i++)
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: InkWell(
                                        child: catItem(
                                          txt: _cats[i],
                                          toshow: _catsbool[i],
                                          callbck: () {
                                            setState(() {
                                              globcat = _cats[i];
                                              setCat(i);
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            Row(
                              children: [
                                for (int i = 6; i < 9; i++)
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: InkWell(
                                        child: catItem(
                                          txt: _cats[i],
                                          toshow: _catsbool[i],
                                          callbck: () {
                                            setState(() {
                                              globcat = _cats[i];
                                              setCat(i);
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      )
                    : Visibility(
                        visible: false,
                        child: widgetbutton4(
                            text: "Tap to SmartShop",
                            onTap1: () {},
                            onTap2: () {})),
              ),
//widgetbutton4(text: "Shopping Mode", onTap1: (){}, onTap2:  (){}),
              SizedBox(
                height: 2,
              ),
              Transform.scale(
                scale: 0.9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(38),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(
                      sigmaX: 3.0,
                      sigmaY: 3.0,
                    ),
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: 80,
                      decoration: BoxDecoration(
                        //colors
                        color: Color(0xda191919),
                        borderRadius: BorderRadius.circular(38),
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            Color(0xBE626162),
                            Color(0x991E1E1E),
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          Visibility(
                            visible: WidgetsBinding
                                        .instance.window.viewInsets.bottom >
                                    100.0
                                ? false
                                : true,
                            child: InkWell(
                              onTap: setvis,
                              child: ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(38),
                                    bottomLeft: Radius.circular(38),
                                    topRight: Radius.circular(0),
                                    bottomRight: Radius.circular(0),
                                  ),
                                  child: Container(
                                    width: 70,
                                    height: 80,
                                    decoration: const BoxDecoration(
                                      //colors
                                      color: Colors.black26,
                                    ),
                                    child: Icon(Icons.settings,
                                        color: Colors.white60),
                                  )),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Transform.translate(
                                offset: Offset(0, 2),
                                child: Container(
                                  child: TextFormField(
                                    controller: _controller,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 20,
                                      fontFamily: 'Schyler',
                                      color: Colors.white,
                                    ),
                                    onFieldSubmitted: (value) {
                                      setState(() {
                                        print("yo");
                                        _addGrocery();
                                      });
                                    },
                                    cursorColor: Colors.black,
                                    decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        hintText: 'Type Grocery Here',
                                        hintStyle: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 20,
                                          color: Colors.white70,
                                          fontFamily: 'Schyler',
                                        )),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: _addGrocery,
                            child: ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(0),
                                  bottomLeft: Radius.circular(0),
                                  topRight: Radius.circular(38),
                                  bottomRight: Radius.circular(38),
                                ),
                                child: Container(
                                  width: 70,
                                  height: 80,
                                  decoration: const BoxDecoration(
                                    //colors
                                    color: Colors.black26,
                                  ),
                                  child: Icon(Icons.add, color: Colors.white60),
                                )),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
            ],
          ),
          Visibility(
            visible: vis,
            child: Stack(
              children: [
                BackdropFilter(
                  filter: ui.ImageFilter.blur(
                    sigmaX: 7.0,
                    sigmaY: 7.0,
                  ),
                  child: Container(
                    color: Colors.black12,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                  ),
                ),
                Center(
                  //settings
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(43),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(
                        sigmaX: 7.0,
                        sigmaY: 732.0,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Container(
                          decoration: BoxDecoration(
                            //colors
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(43),
                            border: Border.all(
                              color: Colors.white70,
                              width: 2,
                            ),

                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                spreadRadius: 1,
                                blurRadius: 6,
                                offset: Offset(
                                    0, 2), // changes position of shadow
                              ),
                            ],
                          ),
                          height: MediaQuery.of(context).size.height / 1.1,
                          child: Column(
                            children: [
                              SizedBox(
                                height: 50,
                              ),
                              StreamBuilder<DocumentSnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('groceryRooms')
                                    .doc(Provider.of<GroceryProvider>(
                                            context)
                                        .roomId)
                                    .snapshots(),
                                builder: (BuildContext context,
                                    AsyncSnapshot<DocumentSnapshot>
                                        snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Text('Loading password...');
                                  } else if (snapshot.hasError) {
                                    return Text('Error: ${snapshot.error}');
                                  } else if (!snapshot.hasData ||
                                      !snapshot.data!.exists) {
                                    return Text('Document does not exist');
                                  } else {
                                    String password = snapshot.data!
                                        .get('password')
                                        .toString();
                                    String roomCode = snapshot.data!.id;
                                    return Text(
                                      'Room Code: $roomCode ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        shadows: <Shadow>[
                                          Shadow(
                                            offset: Offset(0.0, 1.5),
                                            blurRadius: 8.0,
                                            color: Colors.black38,
                                          ),
                                        ],
                                        fontSize: 33,
                                        fontFamily: 'Schyler',
                                      ),
                                    );
                                  }
                                },
                              ),
                              StreamBuilder<DocumentSnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('groceryRooms')
                                    .doc(Provider.of<GroceryProvider>(
                                            context)
                                        .roomId)
                                    .snapshots(),
                                builder: (BuildContext context,
                                    AsyncSnapshot<DocumentSnapshot>
                                        snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Text('Loading password...');
                                  } else if (snapshot.hasError) {
                                    return Text('Error: ${snapshot.error}');
                                  } else if (!snapshot.hasData ||
                                      !snapshot.data!.exists) {
                                    return Text('Document does not exist');
                                  } else {
                                    String password = snapshot.data!
                                        .get('password')
                                        .toString();
                                    String roomCode = snapshot.data!.id;
                                    return Text(
                                      'Room Password: $password ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white70,
                                        shadows: <Shadow>[
                                          Shadow(
                                            offset: Offset(0.0, 1.5),
                                            blurRadius: 8.0,
                                            color: Colors.black38,
                                          ),
                                        ],
                                        fontSize: 18,
                                        fontFamily: 'Schyler',
                                      ),
                                    );
                                  }
                                },
                              ),
                              Expanded(
                                child: Container(
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      SizedBox(
                                        height: 20,
                                      ),
                                      Center(
                                        child: InkWell(
                                          onTap: setvis,
                                          child: AnimatedContainer(
                                            duration:
                                                Duration(milliseconds: 40),
                                            width: 330,
                                            height: 70,
                                            decoration: BoxDecoration(
                                              //colors
                                              color: Colors.white60,
                                              borderRadius:
                                                  BorderRadius.circular(45),
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 2,
                                              ),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Color(0x2C000000),
                                                  spreadRadius: 1,
                                                  blurRadius: 6,
                                                  offset: Offset(0,
                                                      2), // changes position of shadow
                                                ),
                                              ],
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: <Color>[
                                                  Color(0xBE626162),
                                                  Color(0xda191919),
                                                ],
                                              ),
                                            ),
                                            child: Center(
                                                child: Text(
                                              """
Return To Grocery Page""",
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontFamily: 'Schyler',
                                                  fontSize: 25),
                                            )),
                                          ),
                                        ),
                                      ),
                                      Center(
                                        child: InkWell(
                                          onTap: exitRoom,
                                          child: AnimatedContainer(
                                            duration:
                                                Duration(milliseconds: 40),
                                            width: 200,
                                            height: 70,
                                            decoration: BoxDecoration(
                                              //colors
                                              color: Colors.white60,
                                              borderRadius:
                                                  BorderRadius.circular(45),
                                              border: Border.all(
                                                color: Colors.red,
                                                width: 2,
                                              ),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Color(0x2C000000),
                                                  spreadRadius: 1,
                                                  blurRadius: 6,
                                                  offset: Offset(0,
                                                      2), // changes position of shadow
                                                ),
                                              ],
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: <Color>[
                                                  Color(0xBE626162),
                                                  Color(0xda191919),
                                                ],
                                              ),
                                            ),
                                            child: Center(
                                                child: Text(
                                              "Exit Room",
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontFamily: 'Schyler',
                                                  fontSize: 25),
                                            )),
                                          ),
                                        ),
                                      ),
                                      Center(
                                        child: InkWell(
                                          onTap: setvis,
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: AnimatedContainer(
                                              duration:
                                                  Duration(milliseconds: 40),

                                              height: 280,
                                              decoration: BoxDecoration(
                                                //colors
                                                color: Colors.white60,
                                                borderRadius:
                                                    BorderRadius.circular(35),
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 2,
                                                ),
                                                boxShadow: const [
                                                  BoxShadow(
                                                    color: Color(0x2C000000),
                                                    spreadRadius: 1,
                                                    blurRadius: 6,
                                                    offset: Offset(0,
                                                        2), // changes position of shadow
                                                  ),
                                                ],
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: <Color>[
                                                    Color(0xBE626162),
                                                    Color(0xda191919),
                                                  ],
                                                ),
                                              ),
                                              child: Center(
                                                  child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                children: [
                                                  Text(
                                                    """
Sort Groceries""",
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontFamily: 'Schyler',
                                                        fontSize: 25),
                                                  ),
                                                  sortButton(
                                                    txt: "Alphabetically",
                                                  ),
                                                  sortButton(
                                                    txt: "By Category",
                                                  ),
                                                  sortButton(
                                                    txt: "By Time Added",
                                                  )
                                                ],
                                              )),
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        height: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

class hilly extends StatefulWidget {
  @override
  _hillyState createState() => _hillyState();
}

class _hillyState extends State<hilly> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: OverflowBox(
        child: Image(image: AssetImage('assets/hbflowof-min.png')),
        maxWidth: double.infinity,
        maxHeight: double.infinity,
      ),
    );
  }
}

class widgetone extends StatefulWidget {
  final text1;
  final VoidCallback onTap;
  final VoidCallback onTap2;
  final VoidCallback onTap3;
  final VoidCallback onTap4;
  final need;
  final textColor;
  final optacity;
  final String text2;
  final String text3;
  const widgetone(
      {super.key,
      this.text1,
      required this.onTap,
      required this.onTap2,
      this.need = true,
      this.textColor,
      this.optacity,
      this.text2 = "0",
      this.text3 = "0",
      required this.onTap3,
      required this.onTap4});

  @override
  State<widgetone> createState() => _widgetoneState();
}

class _widgetoneState extends State<widgetone> {
  bool animate = true;
  bool newanimate = true;
  Future<void> wanim() async {
    await Future.delayed(const Duration(milliseconds: 400), () {
      setState(() {
        animate = false;
      });
      setState(() {});
    });
    await Future.delayed(const Duration(milliseconds: 200), () {
      setState(() {
        newanimate = false;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    wanim();
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.optacity,
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 350),
          curve: Curves.easeInOutCirc,
          width: 50,
          height: 130,
          decoration: BoxDecoration(
            //colors
            color: Color(0xda191919),
            borderRadius: BorderRadius.circular(43),
            border: Border.all(
              color: widget.textColor,
              width: 2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2C000000),
                spreadRadius: 1,
                blurRadius: 6,
                offset: Offset(0, 2), // changes position of shadow
              ),
            ],
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color(0xBE626162),
                Color(0xBE626162),
              ],
            ),
          ),
          child: Column(
            children: [
              const SizedBox(
                height: 5,
              ),
              Transform.scale(
                scale: 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      width: 200,
                      height: 55,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Center(
                          child: AutoSizeText(
                            widget.text1.toString(),
                            maxLines: 2,
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: widget.textColor,
                                fontSize: 100,
                                fontFamily: 'Schyler'),
                          ),
                        ),
                      ),
                    ),
                    widgetbutton(onTap: widget.onTap),
                    widgetButton2(
                        onTap: widget.onTap2,
                        icon: widget.need == false
                            ? Icons.add_shopping_cart
                            : Icons.remove_shopping_cart,
                        text: widget.need == true
                            ? "Mark as Bought"
                            : "Mark as Needed"),
                  ],
                ),
              ),
              const SizedBox(
                height: 2,
              ),
              Row(
                children: [
                  Expanded(child: Container()),
                  AutoSizeText(
                    widget.text3.toString(),
                    maxLines: 2,
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.black45,
                        fontSize: 20,
                        fontFamily: 'Schyler'),
                  ),
                  Expanded(child: Container()),
                  Expanded(
                      flex: 3,
                      child: widgetbutton3(
                        onTap2: widget.onTap3,
                        text: widget.text2,
                        onTap1: widget.onTap4,
                      )),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class widgetbutton extends StatefulWidget {
  final VoidCallback onTap;

  const widgetbutton({super.key, required this.onTap});

  @override
  State<widgetbutton> createState() => _widgetbuttonState();
}

class _widgetbuttonState extends State<widgetbutton> {
  bool hovered = false;

  void setHover(TapDownDetails details) {
    setState(() {
      hovered = true;
      print('no');
    });
  }

  void unsetHover() {
    setState(() {
      hovered = false;
      print('no');
    });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: widget.onTap,
        child: Column(
          children: [
            AnimatedContainer(
              duration: Duration(milliseconds: 40),
              width: 80,
              height: 50,
              decoration: BoxDecoration(
                //colors
                color: Colors.white60,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: Color(0xFFFF6969),
                  width: 2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x2C000000),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: Offset(0, 2), // changes position of shadow
                  ),
                ],
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Color(0xBE626162),
                    hovered == false ? Color(0xda191919) : Colors.black26,
                  ],
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.delete_forever, color: Colors.white60),
                  const Text(
                    'Delete Item',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      color: Colors.white,
                      fontFamily: 'Schyler',
                    ),
                  )
                ],
              ),
            ),
          ],
        ));
  }
}

class widgetButton2 extends StatefulWidget {
  final VoidCallback onTap;
  final text;
  final icon;
  const widgetButton2(
      {super.key, required this.onTap, required this.text, this.icon});

  @override
  State<widgetButton2> createState() => _widgetButton2State();
}

class _widgetButton2State extends State<widgetButton2> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: widget.onTap,
        child: Column(
          children: [
            AnimatedContainer(
              duration: Duration(milliseconds: 40),
              width: 80,
              height: 50,
              decoration: BoxDecoration(
                //colors
                color: Colors.white60,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x2C000000),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: Offset(0, 2), // changes position of shadow
                  ),
                ],
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Color(0xBE626162),
                    Color(0xda191919),
                  ],
                ),
              ),
              child: Column(
                children: [
                  Icon(widget.icon, color: Colors.white60),
                  Text(
                    widget.text.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 8,
                      color: Colors.white,
                      fontFamily: 'Schyler',
                    ),
                  )
                ],
              ),
            ),
          ],
        ));
  }
}

class widgetbutton3 extends StatefulWidget {
  final VoidCallback onTap1;
  final VoidCallback onTap2;
  final String text;

  const widgetbutton3(
      {super.key,
      required this.text,
      required this.onTap1,
      required this.onTap2});

  @override
  State<widgetbutton3> createState() => _widgetbutton3State();
}

class _widgetbutton3State extends State<widgetbutton3> {
  bool hovered = false;

  void setHover(TapDownDetails details) {
    setState(() {
      hovered = true;
      print('no');
    });
  }

  void unsetHover() {
    setState(() {
      hovered = false;
      print('no');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
            duration: Duration(milliseconds: 40),
            width: 150,
            height: 40,
            decoration: BoxDecoration(
              //colors
              color: Colors.white60,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.lightBlue,
                width: 2,
              ),

              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0xBE626162),
                  hovered == false ? Color(0xda191919) : Colors.black26,
                ],
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: widget.onTap1,
                      child: Container(
                        decoration: BoxDecoration(
                          //colors
                          color: Colors.black26,
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: <Color>[
                              Color(0xBE626162),
                              Colors.black,
                            ],
                          ),
                        ),
                        child: Center(
                            child: Icon(
                          Icons.remove,
                          color: Colors.white60,
                        )),
                      ),
                    ),
                  ),
                  Container(
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                    ),
                    child: Center(
                        child: Text(
                      widget.text.toString(),
                      style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Schyler',
                          fontSize: 25),
                    )),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: widget.onTap2,
                      child: Container(
                        decoration: BoxDecoration(
                          //colors
                          color: Colors.black26,

                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: <Color>[
                              Color(0xBE626162),
                              Colors.black,
                            ],
                          ),
                        ),
                        child: Center(
                            child: Icon(Icons.add, color: Colors.white60)),
                      ),
                    ),
                  )
                ],
              ),
            )),
        SizedBox(
          height: 2,
        ),
        const Text(
          'Quantity',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 10,
            color: Colors.white,
            fontFamily: 'Schyler',
          ),
        )
      ],
    );
  }
}

class widgetbutton4 extends StatefulWidget {
  final VoidCallback onTap1;
  final VoidCallback onTap2;
  final String text;

  const widgetbutton4(
      {super.key,
      required this.text,
      required this.onTap1,
      required this.onTap2});

  @override
  State<widgetbutton4> createState() => _widgetbutton4State();
}

class _widgetbutton4State extends State<widgetbutton4> {
  bool hovered = false;

  void setHover(TapDownDetails details) {
    setState(() {
      hovered = true;
      print('no');
    });
  }

  void unsetHover() {
    setState(() {
      hovered = false;
      print('no');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: AnimatedContainer(
          duration: Duration(milliseconds: 40),
          width: 270,
          height: 50,
          decoration: BoxDecoration(
            //colors
            color: Colors.white60,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.lightGreen,
              width: 2,
            ),

            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color(0xBE749A74),
                hovered == false ? Color(0xda191919) : Colors.black26,
              ],
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(3.0),
                child: Text(
                  widget.text.toString(),
                  style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Schyler',
                      fontWeight: FontWeight.w900,
                      fontSize: 20),
                ),
              ),
            ),
          )),
    );
  }
}

class catItem extends StatefulWidget {
  final txt;
  final toshow;
  final callbck;
  const catItem({super.key, this.txt, this.toshow, this.callbck});

  @override
  State<catItem> createState() => _catItemState();
}

class _catItemState extends State<catItem> {
  bool istapped = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTapDown: (details) {
        setState(() {
          istapped = true;
          widget.callbck();
        });
      },
      onTapUp: (details) {
        setState(() {
          istapped = false;
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 40),
        width: 70,
        height: 50,
        decoration: BoxDecoration(
          //colors
          color: Colors.white60,
          borderRadius: BorderRadius.circular(istapped ? 40 : 20),
          border: Border.all(
            color: widget.toshow == true ? Colors.white : Colors.white38,
            width: widget.toshow == true ? 3 : 2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2C000000),
              spreadRadius: 1,
              blurRadius: 6,
              offset: Offset(0, 2), // changes position of shadow
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xBE626162),
              Color(0xda191919),
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: FittedBox(
              child: Text(widget.txt,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: Colors.white,
                    fontFamily: 'Schyler',
                  )),
            ),
          ),
        ),
      ),
    );
  }
}

class sortButton extends StatefulWidget {
  final txt;
  final toshow;
  final callbck;
  const sortButton({super.key, this.txt, this.toshow, this.callbck});

  @override
  State<sortButton> createState() => _sortButtonState();
}

class _sortButtonState extends State<sortButton> {
  bool istapped = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTapDown: (details) {
        setState(() {
          istapped = true;
          widget.callbck();
        });
      },
      onTapUp: (details) {
        setState(() {
          istapped = false;
        });
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 40),
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            //colors
            color: Colors.white60,
            borderRadius: BorderRadius.circular(istapped ? 40 : 40),
            border: Border.all(
              color: widget.toshow == true ? Colors.white : Colors.white38,
              width: widget.toshow == true ? 3 : 2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2C000000),
                spreadRadius: 1,
                blurRadius: 6,
                offset: Offset(0, 2), // changes position of shadow
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color(0xBE626162),
                Color(0xda191919),
              ],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: FittedBox(
                child: Text(widget.txt,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: Colors.white,
                      fontFamily: 'Schyler',
                    )),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
