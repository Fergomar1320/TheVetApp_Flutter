import 'dart:html';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase/firebase.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vet_app/read%20data/get_pet_name.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

// install firebase-cli curl -sL https://firebase.tools | bash (https://firebase.google.com/docs/cli)
// firebase login
// dart pub global activate flutterfire_cli
// flutterfire configure
// flutter pub add firebase_core

// I will be using - auth & firestore
// flutter pub add firebase_auth
// flutter pub add cloud_firestore
// flutterfire configure


Future<void> main() async {
  // since firebase uses native bindings we need to ensure those are ready
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      home: Scaffold(
        appBar:  AppBar(title: const Text('Welcome to The Vet App!')),
        body: Center(
          child: LoginWidget(),
        ),
      ),
    );
  }
}

class LoginWidget extends StatefulWidget {
  const LoginWidget({super.key});

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  @override
  Widget build(BuildContext context) {

    var db = FirebaseFirestore.instance;
    //how to check when a user is connected

    //lets add some states!
    TextEditingController login = TextEditingController();
    TextEditingController password = TextEditingController();

    setState(() {
      login.text = "";
      password.text = "";
    });

    return  Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10.0),
          child: TextField(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Login'
            ),
            controller: login,
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10.0),
          child: TextField(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Password'
            ),
            controller: password,
            obscureText: true,
          ),),

        TextButton(
          onPressed: () async{
            try {
                final user = await FirebaseAuth.instance
                  .signInWithEmailAndPassword(
                    email: login.text, password: password.text
                  );
                print("USER LOGGED IN: ${user.user?.uid}");
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
              } catch (e){
                print(e);
              }
          }, 
          child: const Text("Log In")),

        TextButton(
          onPressed: () async{
            try {
              final user = await FirebaseAuth.instance
                .createUserWithEmailAndPassword(
                  email: login.text, password: password.text
                );
              print(user.user?.uid);
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
            } on FirebaseAuthException catch (e){
              if(e.code == 'weak-password'){
                print("Your password is weak, and so are you!");
              } else if(e.code == 'email-already-in-use'){
                print("Your password is weak, and so are you!");
              }
              print(e);
            }
          }, child: const Text("Sign Up")),

        TextButton(
          onPressed: () async{
            //create an object that will be translated into a document
            //remember - firestore has a structure in which collections contain documents
            //documents are similar to records in a relational db
            final puppy = <String, dynamic> {
              "Name" : "Killer",
              "Age" : 2,
              "Weight" : 3,
              "Pet Kind": "Penguin"
            };

            //add user into firestore collection
            db.collection("PETS").add(puppy).then(
              (DocumentReference doc) =>
                print("new document created")
            );
          }, child: const Text("Add record")),
      ],
    );
  }
}

class _RealTimeWidgetState extends StatefulWidget {
  const _RealTimeWidgetState({super.key});

  @override
  State<_RealTimeWidgetState> createState() => __RealTimeWidgetStateState();
}

class __RealTimeWidgetStateState extends State<_RealTimeWidgetState> {
  @override

  final Stream<QuerySnapshot> _petStream = 
    FirebaseFirestore.instance.collection("PETS").snapshots();
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _petStream,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot){
        return const Placeholder();
      },
    );
  }
}


//HOME PAGE WIDGET
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser!;

  List<String> petNames = [];

  Future getPetName() async{
    await FirebaseFirestore.instance.collection('PETS').get().then(
      (snapshot) => snapshot.docs.forEach((document) {
        print(document.reference);
        petNames.add(document.reference.id);
       }),
    );

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:Text(
              'Logged in as: ' + user.email!,
            ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('PET LIST'),
            Expanded(
              child: FutureBuilder(
                future: getPetName(),
                builder:(context, snapshot){
                  return ListView.builder(
                    itemCount: petNames.length,
                    itemBuilder: (context, index){
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child:ListTile(
                          title: GetPetName(documentId: petNames[index]),
                          tileColor: Color.fromARGB(255, 193, 240, 192),
                          trailing: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) =>  PetDetails(documentId: petNames[index],)),
                              );
                            },
                            child: Text('See Details'),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),   
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterPet()),
                );
              },
              child: Text('New Pet'),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pop(context);
              },
              child: const Text('Log Out'),
            ),
          ],) 
      ),
    );
  }
}

class PetDetails extends StatefulWidget {
  final String documentId;
  const PetDetails({Key? key, required this.documentId}): super(key: key);

  @override
  _PetDetailsState createState() => _PetDetailsState();
}

class _PetDetailsState extends State<PetDetails> {
  late Future<DocumentSnapshot> _petData;

  @override
  void initState(){
    super.initState();
    _petData = FirebaseFirestore.instance.collection('PETS').doc(widget.documentId).get();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: _petData,
      builder: (context, snapshot){
        if(snapshot.hasData){
          Map<String, dynamic>? data = snapshot.data!.data() as Map<String, dynamic>?;
          return Scaffold(
            appBar: AppBar(
              title: Text('Pet Details'),
            ),
            body: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text('Name: ${data!['Name']}'),
                  Text('Age: ${data!['Age']}'),
                  Text('Type: ${data!['Pet Kind']}'),
                  Text('Weight: ${data!['Weight']}'),
                ],
                ) ,
              ),
          );
        } else if (snapshot.hasError){
          return Text('Error: ${snapshot.error}');
        } else{
          return CircularProgressIndicator();
        }
      },);
  }
}

class RegisterPet extends StatefulWidget {
  const RegisterPet({super.key});

  @override
  State<RegisterPet> createState() => _RegisterPetState();
}

class _RegisterPetState extends State<RegisterPet> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register New Pet Page'),
      ),
    );
  }
}