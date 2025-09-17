import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:our_cabss/services/auth_serviece.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final nameTextEditingController = TextEditingController();
  final addressTextEditingController = TextEditingController();
  final phoneTextEditingController = TextEditingController();
  DatabaseReference userRef = FirebaseDatabase.instance.ref().child("users");

  Future<void> showUserNameDilogAleart(BuildContext context, String name) {
    nameTextEditingController.text = name;

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Update"),
          content: SingleChildScrollView(
            child: Column(
              children: [TextField(controller: nameTextEditingController)],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel", style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                userRef
                    .child(firebaseAuth.currentUser!.uid)
                    .update({"name": nameTextEditingController.text.trim()})
                    .then((value) {
                      nameTextEditingController.clear();
                      Fluttertoast.showToast(
                        msg: "Update Successfully. \n Reload the app to see the change",
                      );
                    }).catchError((errormassage) {
                      Fluttertoast.showToast(
                        msg: "Error Occurred.\n$errormassage",
                      );
                    });

                Navigator.pop(context);
              },
              child: Text("ok", style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  Future<void> showUserPhoneDilogAleart(BuildContext context, String phone) {
    phoneTextEditingController.text = phone;

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Update"),
          content: SingleChildScrollView(
            child: Column(
              children: [TextField(controller: phoneTextEditingController)],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel", style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                userRef
                    .child(firebaseAuth.currentUser!.uid)
                    .update({"phone": phoneTextEditingController.text.trim()})
                    .then((value) {
                      phoneTextEditingController.clear();
                      Fluttertoast.showToast(
                        msg: "Update Successfully. \n Reload the app to see the change",
                      );
                    }).catchError((errormassage) {
                      Fluttertoast.showToast(
                        msg: "Error Occurred.\n$errormassage",
                      );
                    });

                Navigator.pop(context);
              },
              child: Text("ok", style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  Future<void> showUserAddressDilogAleart(BuildContext context, String address) {
    addressTextEditingController.text = address;

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Update"),
          content: SingleChildScrollView(
            child: Column(
              children: [TextField(controller: addressTextEditingController)],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel", style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                userRef
                    .child(firebaseAuth.currentUser!.uid)
                    .update({"address": addressTextEditingController.text.trim()})
                    .then((value) {
                      addressTextEditingController.clear();
                      Fluttertoast.showToast(
                        msg: "Update Successfully. \n Reload the app to see the change",
                      );
                    }).catchError((errormassage) {
                      Fluttertoast.showToast(
                        msg: "Error Occurred.\n$errormassage",
                      );
                    });

                Navigator.pop(context);
              },
              child: Text("ok", style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }
 
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.arrow_back_ios),
          ),
          title: Text(
            "Profile",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Colors.black,
            ),
          ),
          centerTitle: true,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 50),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(50),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue,
                  ),
                  child: Icon(Icons.person, color: Colors.white),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${userModelCurrentInfo!.name!}",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        showUserNameDilogAleart(
                          context,
                          userModelCurrentInfo!.name!,
                        );
                      },
                      icon: Icon(Icons.edit),
                    ),
                  ],
                ),
                Divider(thickness: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${userModelCurrentInfo!.phone!}",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        showUserPhoneDilogAleart(
                          context,
                          userModelCurrentInfo!.phone!,
                        );
                      },
                      icon: Icon(Icons.edit),
                    ),
                  ],
                ),
                Divider(thickness: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${userModelCurrentInfo!.address!}",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        showUserAddressDilogAleart(
                          context,
                          userModelCurrentInfo!.address!,
                        );
                      },
                      icon: Icon(Icons.edit),
                    ),
                  ],
                ),
                Divider(thickness: 1),
                Text(
                  "${userModelCurrentInfo!.email!}",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}