import 'dart:typed_data';

/// Everything a CV template needs to render one document.
class CvData {
  final String name;
  final String title;
  final String email;
  final String phone;
  final String address;
  final String dob;
  final String gender;
  final String maritalStatus;
  final String nationality;
  final String father;
  final String mother;
  final String objective;
  final String education;
  final String certifications;
  final String experience;
  final String projects;
  final String skills;
  final String languages;
  final String hobbies;
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
    this.gender = '',
    this.maritalStatus = '',
    this.nationality = '',
    this.father = '',
    this.mother = '',
    this.objective = '',
    required this.education,
    this.certifications = '',
    required this.experience,
    this.projects = '',
    required this.skills,
    this.languages = '',
    this.hobbies = '',
    this.declaration = '',
    this.photo,
    this.template = 0,
  });
}
