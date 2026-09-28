import 'dart:typed_data';

/// Everything a CV template needs to render one document.
class CvData {
  final String name;
  final String title;
  final String email;
  final String phone;
  final String address;
  final String dob;
  final String father;
  final String objective;
  final String education;
  final String experience;
  final String skills;
  final String languages;
  final String declaration;
  final Uint8List? photo;
  final int template;

  const CvData({
    required this.name,
    this.title = '',
    required this.email,
    required this.phone,
    this.address = '',
    this.dob = '',
    this.father = '',
    this.objective = '',
    required this.education,
    required this.experience,
    required this.skills,
    this.languages = '',
    this.declaration = '',
    this.photo,
    this.template = 0,
  });
}
