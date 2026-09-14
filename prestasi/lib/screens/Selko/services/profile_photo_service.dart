import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePhotoService {
final ImagePicker _picker = ImagePicker();

Future<void> pickAndUploadProfilePhoto() async {
try {
print('STEP 1');


  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    print('USER NULL');
    return;
  }

  print('UID = ${user.uid}');

  final XFile? image = await _picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 70,
  );

  if (image == null) {
    print('IMAGE BATAL DIPILIH');
    return;
  }

  print('STEP 2');
  print('PATH = ${image.path}');

  final bytes = await image.readAsBytes();

  print('STEP 3');
  print('SIZE = ${bytes.length}');

  final ref = FirebaseStorage.instance
      .ref()
      .child('profile_photos')
      .child('${user.uid}.jpg');

  print('STEP 4');

  await ref.putData(
    bytes,
    SettableMetadata(
      contentType: 'image/jpeg',
    ),
  );

  print('STEP 5');

  final downloadUrl = await ref.getDownloadURL();

  print('URL = $downloadUrl');

  await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .update({
    'photoURL': downloadUrl,
  });

  print('STEP 6 SELESAI');
} catch (e) {
  print('ERROR = $e');
}

}
}
