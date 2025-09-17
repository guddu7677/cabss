import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
// import 'package:our_cabs/services/auth_service.dart'; // only if you need custom logic

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =TextEditingController();

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  final _formKey = GlobalKey<FormState>();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      try {
        UserCredential authResult =
            await _auth.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        User? currentUser = authResult.user;
        if (currentUser != null) {
          Map<String, dynamic> userDataMap = {
            "id": currentUser.uid,
            "name": nameController.text.trim(),
            "email": emailController.text.trim(),
            "phone": phoneController.text.trim(),
            "address": addressController.text.trim(),
          };
          DatabaseReference userRef =
              FirebaseDatabase.instance.ref().child("users");

          userRef.child(currentUser.uid).set(userDataMap);

          Fluttertoast.showToast(msg: "Registration Successful");

          Navigator.pushReplacementNamed(context, "/LoginScreen"); 
        } else {
          Fluttertoast.showToast(msg: "Error: User is null");
        }
      } on FirebaseAuthException catch (e) {
        Fluttertoast.showToast(msg: "Error: ${e.message}");
      } catch (e) {
        Fluttertoast.showToast(msg: "Error: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool darkTheme =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Image.asset(
            //   darkTheme
            //       ? 'assets/images/ncity.jpeg'
            //       : "assets/images/cittyr.webp",
            //   height: 150,
            // ),
            const SizedBox(height: 16),
            Text(
              'Register',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildTextField(
                      controller: nameController,
                      hint: "Name",
                      darkTheme: darkTheme,
                      validator: (text) {
                        if (text == null || text.isEmpty) {
                          return "Name can't be empty";
                        }
                        if (text.length < 2) return "Enter a valid name";
                        return null;
                      }),
                  const SizedBox(height: 12),
                  _buildTextField(
                      controller: emailController,
                      hint: "Email",
                      darkTheme: darkTheme,
                      keyboardType: TextInputType.emailAddress,
                      validator: (text) {
                        if (text == null || text.isEmpty) {
                          return "Email can't be empty";
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(text)) {
                          return "Enter a valid email";
                        }
                        return null;
                      }),
                  const SizedBox(height: 12),
                  _buildTextField(
                      controller: phoneController,
                      hint: "Phone",
                      darkTheme: darkTheme,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(15),
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (text) {
                        if (text == null || text.isEmpty) {
                          return "Phone can't be empty";
                        }
                        if (text.length < 10) {
                          return "Enter a valid phone number";
                        }
                        return null;
                      }),
                  const SizedBox(height: 12),
                  _buildTextField(
                      controller: addressController,
                      hint: "Address",
                      darkTheme: darkTheme,
                      validator: (text) {
                        if (text == null || text.isEmpty) {
                          return "Address can't be empty";
                        }
                        return null;
                      }),
                  const SizedBox(height: 12),
                  _passwordField(
                      controller: passwordController,
                      hint: "Password",
                      darkTheme: darkTheme,
                      isVisible: _passwordVisible,
                      toggleVisibility: () {
                        setState(() {
                          _passwordVisible = !_passwordVisible;
                        });
                      }),
                  const SizedBox(height: 12),
                  _passwordField(
                      controller: confirmPasswordController,
                      hint: "Confirm Password",
                      darkTheme: darkTheme,
                      isVisible: _confirmPasswordVisible,
                      toggleVisibility: () {
                        setState(() {
                          _confirmPasswordVisible = !_confirmPasswordVisible;
                        });
                      },
                      validator: (text) {
                        if (text == null || text.isEmpty) {
                          return "Confirm your password";
                        }
                        if (text != passwordController.text) {
                          return "Passwords do not match";
                        }
                        return null;
                      }),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor:
                          darkTheme ? Colors.amber.shade400 : Colors.blue,
                    ),
                    onPressed: _submit,
                    child: const Text(
                      "Register",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.pushReplacementNamed(context, "/LoginScreen");
              },
              child: Text("Login"))
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool darkTheme,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: _inputDecoration(hint, darkTheme),
      validator: validator,
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String hint,
    required bool darkTheme,
    required bool isVisible,
    required VoidCallback toggleVisibility,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      decoration: _inputDecoration(hint, darkTheme).copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
            color: darkTheme ? Colors.amber : Colors.grey,
          ),
          onPressed: toggleVisibility,
        ),
      ),
      validator: validator,
    );
  }

  InputDecoration _inputDecoration(String hint, bool darkTheme) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: darkTheme ? Colors.black45 : Colors.grey.shade200,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(40),
        borderSide: BorderSide.none,
      ),
    );
  }
}
