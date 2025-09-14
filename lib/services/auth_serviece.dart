import 'package:firebase_auth/firebase_auth.dart';
import 'package:our_cabss/models/user_model.dart';

final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
User? currentUser;
UserModel? userModelCurrentInfo;