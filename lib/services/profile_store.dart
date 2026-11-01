import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/profile_details.dart';

abstract class ProfileStore {
  Stream<List<ProfileDetails>> watch(String uid);
  Future<void> write(String uid, ProfileDetails profile);
}

class FirestoreProfileStore implements ProfileStore {
  CollectionReference<Map<String, dynamic>> _profiles(String uid) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('profiles');
  @override
  Stream<List<ProfileDetails>> watch(String uid) => _profiles(uid)
          .snapshots(includeMetadataChanges: true)
          .where((s) => !s.metadata.isFromCache)
          .map((s) {
        final result = <ProfileDetails>[];
        for (final doc in s.docs) {
          try {
            final p = ProfileDetails.fromJson(doc.data());
            if (p.name.isNotEmpty && p.updatedAt >= 0) result.add(p);
          } catch (_) {}
        }
        return result;
      });
  @override
  Future<void> write(String uid, ProfileDetails profile) async {
    final id = base64Url.encode(utf8.encode(profile.name));
    final ref = _profiles(uid).doc(id);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final old = (await tx.get(ref)).data()?['updatedAt'];
      if (old is num && old >= profile.updatedAt) return;
      tx.set(ref, profile.toJson());
    }).timeout(const Duration(seconds: 10));
  }
}
