import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';

class ProfileDetails {
  const ProfileDetails(
      {required this.name,
      this.avatar = 'person',
      this.isChild = false,
      this.maxRating = '+18',
      this.pinHash = '',
      this.pinSalt = '',
      this.updatedAt = 0,
      this.deleted = false});
  final String name, avatar, maxRating, pinHash, pinSalt;
  final bool isChild, deleted;
  final int updatedAt;
  bool get hasPin => pinHash.isNotEmpty;
  Map<String, dynamic> toJson() => {
        'name': name,
        'avatar': avatar,
        'isChild': isChild,
        'maxRating': maxRating,
        'pinHash': pinHash,
        'pinSalt': pinSalt,
        'updatedAt': updatedAt,
        'deleted': deleted
      };
  factory ProfileDetails.fromJson(Map<String, dynamic> json) => ProfileDetails(
      name: json['name'] as String,
      avatar: json['avatar'] as String? ?? 'person',
      isChild: json['isChild'] == true,
      maxRating: json['maxRating'] as String? ?? '+18',
      pinHash: json['pinHash'] as String? ?? '',
      pinSalt: json['pinSalt'] as String? ?? '',
      updatedAt: (json['updatedAt'] as num?)?.toInt() ?? 0,
      deleted: json['deleted'] == true);
  static Future<List<String>> encodePin(String pin) async {
    final salt = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final key =
        await Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: 100000, bits: 256)
            .deriveKeyFromPassword(password: pin, nonce: salt);
    return [base64Encode(await key.extractBytes()), base64Encode(salt)];
  }

  Future<bool> verifyPin(String pin) async {
    if (!hasPin) return true;
    try {
      final key = await Pbkdf2(
              macAlgorithm: Hmac.sha256(), iterations: 100000, bits: 256)
          .deriveKeyFromPassword(password: pin, nonce: base64Decode(pinSalt));
      final actual = await key.extractBytes();
      final expected = base64Decode(pinHash);
      if (actual.length != expected.length) return false;
      var different = 0;
      for (var i = 0; i < actual.length; i++) {
        different |= actual[i] ^ expected[i];
      }
      return different == 0;
    } catch (_) {
      return false;
    }
  }
}
