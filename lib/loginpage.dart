import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'dart:async';
import 'main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';


class loginPage extends StatefulWidget {
  static const String route = '/login';

  @override
  State<loginPage> createState() => _loginPageState();
}

class _loginPageState extends State<loginPage> {

  final TextEditingController _controller = TextEditingController();
  final TextEditingController _controller2 = TextEditingController();

  @override
  void initState() {
    super.initState();


  }


  Future<void> saveDataInRoom(String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('inRoom', true);
      await prefs.setString('roomCode', code); // use the code parameter
      print('Data saved successfully!');
    } catch (e) {
      print('Error saving data in room: $e');
      // Optionally, you can rethrow or handle the error differently
      // throw Exception('Failed to save room data');
    }
  }

  Future<void> checkIfInRoom() async {
    final prefs = await SharedPreferences.getInstance();

    String? code = prefs.getString('roomCode');
    if (code == "0" || code == null){
      return;
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChangeNotifierProvider(
            create: (context) => GroceryProvider(roomId: code.toString()), // Pass the roomCode to the provider
            child: MyHomePage(title: 'Flutter Demo Home Page', roomId: code.toString()),
          ),
        ),
      );

    }
  }



  Future<void> fetchDocumentNames() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('groceryRooms').get();
      print("Total documents fetched: ${querySnapshot.docs.length}");
      for (var doc in querySnapshot.docs) {
        print(doc.id); // Print each document ID (name)
      }
    } catch (e) {
      print('Error fetching document names: $e');
    }
  }



  Future<void> createNewRoom() async {
    try {
      // Generate random numbers for room code and password
      int roomCode;
      int password = 1000 + Random().nextInt(8001); // Generates a number between 1000 and 9000

      // Check if the generated room code already exists
      bool roomExists = true;
      do {
        roomCode = 1000 + Random().nextInt(8001); // Generates a number between 1000 and 9000
        DocumentSnapshot docSnapshot = await FirebaseFirestore.instance.collection('groceryRooms').doc(roomCode.toString()).get();
        if (!docSnapshot.exists) {
          roomExists = false;
        }
      } while (roomExists);

      // Create a new document with the unique room code as the document ID
      await FirebaseFirestore.instance.collection('groceryRooms').doc(roomCode.toString()).set({
        'password': password.toString(),
      });

      print('New room created with code: $roomCode and password: $password');

      String roomString = roomCode.toString();
      saveDataInRoom(roomString);

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              ChangeNotifierProvider(
                create: (context) => GroceryProvider(roomId: roomCode.toString()),
                child: MyHomePage(title: 'Flutter Demo Home Page', roomId: roomCode.toString()),
              ),
          transitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );

    } catch (e) {
      print('Error creating new room: $e');
    }




  }



  Future<void> findRoomAndPrintPassword() async {
    String roomCode = _controller.text; // Get the room code from the first TextFormField

    try {
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance.collection('groceryRooms').doc(roomCode).get();

      if (docSnapshot.exists) {
        var password = docSnapshot.get('password').toString();
        print('Password for room $roomCode: $password');
        // Optionally, you can set this password to the second TextFormField

        if (_controller2.text == password) {
          print('Password for room $roomCode matches: $password');
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  ChangeNotifierProvider(
                    create: (context) => GroceryProvider(roomId: roomCode),
                    child: MyHomePage(title: 'Flutter Demo Home Page', roomId: roomCode),
                  ),

              // Define the transition duration
              transitionDuration: const Duration(milliseconds: 250), // Adjust for speed

              // The transition effect function
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                // Use a FadeTransition for a smooth dissolve effect
                return FadeTransition(
                  opacity: animation, // Use the primary animation controller
                  child: child,
                );
              },
            ),
          );


        } else {
          print('Entered password does not match for room $roomCode');
        }
      } else {
        print('Room code $roomCode not found');
      }
    } catch (e) {
      print('Error finding room and printing password: $e');
    }
  }

  bool istapped = false;
  bool istapped2 = false;


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
            color: Colors.black12,  // This darkens the background
          ),
          Column(

            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              SizedBox(
                height: 30,
              ),

              Container(
                width: MediaQuery.of(context).size.width /1.04,
                height: 100,
                // Define the max height

                child: Image.asset(
                  'assets/gpt_wide.png', // Replace with your actual path
                  fit: BoxFit.fitWidth, // <--- Key Property
                ),
              ),
              SizedBox(
                height: 30,
              ),




              InkWell(
                onTapDown: (details){
                  setState(() {
                    istapped = true;
                  });
                },
                onTapUp: (details){
                  setState(() {
                    istapped = false;
                  });
                },
                child: Center(
                  child: Container(


                    width: MediaQuery.of(context).size.width /1.04,
                    decoration: BoxDecoration(
                      //colors

                      borderRadius: BorderRadius.circular(50),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x2C000000),
                          spreadRadius: 2,
                          blurRadius: 3,
                          offset: Offset(0, 2), // changes position of shadow
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white,
                        width: istapped ? 2: 2,
                      ),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          Color(0x867E7E7E),
                          Color(0x864D4D4D),
                        ],
                      ),
                    ),

                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,


                      children: [

                        const Center(child:  Text(
                          'Join Room',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 30,
                            color: Colors.white,
                            fontFamily: 'Schyler',
                            shadows: <Shadow>[
                              Shadow(
                                offset: Offset(0.0, 3.0),
                                blurRadius: 5.0,
                                color: Colors.black12,
                              ),
                            ],
                          ),
                        )),
                        const SizedBox(
                          height: 7,
                        ),


                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              height: 70,


                              decoration: BoxDecoration(
                                //colors
                                color: Color(0xda191919),
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x2C000000),
                                    spreadRadius: 2,
                                    blurRadius: 3,
                                    offset: Offset(0, 2), // changes position of shadow
                                  ),
                                ],
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: <Color>[
                                    Color(0x88A9A9A9),
                                    Color(0xBE626162),

                                  ],
                                ),
                              ),
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Container(

                                    child: TextFormField(
                                      controller: _controller,
                                      keyboardType: TextInputType.number,
                                      // onChanged: (value) {
                                      //   findRoomAndPrintPassword();
                                      //
                                      // },
                                      maxLength: 5,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 20,
                                        fontFamily: 'Schyler',
                                      ),
                                      cursorColor: Colors.black,
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        counterText: '',
                                        focusedBorder: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        hintText: 'Type Room Code Here',
                                        hintStyle: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 20,
                                          fontFamily: 'Schyler',
                                          color: Colors.white38,
                                        ),

                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              height: 70,


                              decoration: BoxDecoration(
                                //colors
                                color: Color(0xda191919),
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x2C000000),
                                    spreadRadius: 2,
                                    blurRadius: 3,
                                    offset: Offset(0, 2), // changes position of shadow
                                  ),
                                ],
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: <Color>[
                                    Color(0x88A9A9A9),
                                    Color(0xBE626162),

                                  ],
                                ),
                              ),
                              child: Center(
                                child: TextFormField(
                                  controller: _controller2,
                                  keyboardType: TextInputType.number,
                                  // onChanged: (value) {
                                  //   findRoomAndPrintPassword();
                                  // },

                                  maxLength: 5,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                    fontFamily: 'Schyler',
                                  ),
                                  cursorColor: Colors.black,

                                  decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      counterText: '',


                                      focusedBorder: InputBorder.none,
                                      enabledBorder: InputBorder.none,

                                      hintText: 'Type Room Password Here',
                                      hintStyle: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 20,
                                        fontFamily: 'Schyler',
                                        color: Colors.white38,
                                      )),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        InkWell(
                          onTap: (){
              findRoomAndPrintPassword();
              },
                          child: Container(
                            width: 180,
                            height: 40,


                            decoration: BoxDecoration(
                              //colors
                              color: Color(0xda6d8169),
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x2C000000),
                                  spreadRadius: 2,
                                  blurRadius: 3,
                                  offset: Offset(0, 2), // changes position of shadow
                                ),
                              ],
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: <Color>[
                                  Color(0x88A9A9A9),
                                  Color(0xBE626162),

                                ],
                              ),
                            ),
                            child: Center(child: Text('Join', style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                              color: Colors.white,
                              fontFamily: 'Schyler',
                              shadows: <Shadow>[
                                Shadow(
                                  offset: Offset(0.0, 3.0),
                                  blurRadius: 5.0,
                                  color: Colors.black12,
                                ),
                              ],
                            ),)),
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),

                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 15,
              ),
              Visibility(
                visible: MediaQuery.of(context).viewInsets.bottom == 0.0,
                child: Text(
                  'Or',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 30,
                    color: Colors.white,
                    fontFamily: 'Schyler',
                    shadows: <Shadow>[
                      Shadow(
                        offset: Offset(0.0, 3.0),
                        blurRadius: 5.0,
                        color: Colors.black12,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 15,
              ),
              Visibility(
                visible: MediaQuery.of(context).viewInsets.bottom == 0.0,
                child: Center(
                  child: Container(

                    height: 180,
                    width: MediaQuery.of(context).size.width /1.09,
                    decoration: BoxDecoration(
                      //colors

                      borderRadius: BorderRadius.circular(70),
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x2C000000),
                          spreadRadius: 2,
                          blurRadius: 3,
                          offset: Offset(0, 2), // changes position of shadow
                        ),
                      ],
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[

                          Color(0x864D4D4D),
                          Color(0x867E7E7E),
                        ],
                      ),
                    ),

                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,


                      children: [




                        Center(
                          child: InkWell(


                            onTap: createNewRoom,


                            child: Container(
                              width: 330,
                              height: 90,


                              decoration: BoxDecoration(
                                //colors
                                color: Color(0xda191919),
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x2C000000),
                                    spreadRadius: 2,
                                    blurRadius: 3,
                                    offset: Offset(0, 2), // changes position of shadow
                                  ),
                                ],
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: <Color>[
                                    Color(0x88A9A9A9),
                                    Color(0xBE626162),

                                  ],
                                ),
                              ),
                              child: Visibility(
                                visible: MediaQuery.of(context).viewInsets.bottom == 0.0,
                                child: Center(child: Text('Generate Room', style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 30,
                                  color: Colors.white,
                                  fontFamily: 'Schyler',
                                  shadows: <Shadow>[
                                    Shadow(
                                      offset: Offset(0.0, 3.0),
                                      blurRadius: 5.0,
                                      color: Colors.black12,
                                    ),
                                  ],
                                ),)),
                              ),
                            ),
                          ),
                        ),


                      ],
                    ),
                  ),
                ),
              ),

            ],
          )
        ],
      ),
    );
  }
}
