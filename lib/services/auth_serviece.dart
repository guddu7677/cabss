import 'package:firebase_auth/firebase_auth.dart';
import 'package:our_cabss/models/direction_details_info.dart';
import 'package:our_cabss/models/user_model.dart';

final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
User? currentUser;
UserModel? userModelCurrentInfo;
DirectionDetailsInfo? tripDirectionDetailsInfo;
  String? userDropOffAddress="";