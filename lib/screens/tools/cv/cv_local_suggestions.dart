/// One offline, editable suggestion for a CV field.
class CvTextSuggestion {
  final String label;
  final String text;

  const CvTextSuggestion({required this.label, required this.text});
}

/// Small, fact-safe CV starters tailored from details already on the device.
///
/// These templates never call a service or invent achievements. Anything in
/// square brackets is a prompt for the user to replace with their own facts.
class CvLocalSuggestions {
  CvLocalSuggestions._();

  static const standardDeclaration =
      'I hereby declare that the information provided above is true to the '
      'best of my knowledge and belief.';

  static List<CvTextSuggestion> objectives({
    required String role,
    required String skills,
  }) {
    final cleanRole = role.trim();
    final skillPhrase = _skillPhrase(skills);
    final rolePhrase = 'opportunities as $cleanRole';

    return [
      CvTextSuggestion(
        label: 'Fresher',
        text: cleanRole.isEmpty
            ? 'Motivated entry-level candidate ready to apply $skillPhrase, '
                'contribute dependable work, and build practical experience.'
            : 'Motivated entry-level candidate seeking $rolePhrase, ready to '
                'apply $skillPhrase and build practical experience.',
      ),
      CvTextSuggestion(
        label: 'Experienced',
        text: cleanRole.isEmpty
            ? 'Experienced professional with strengths in $skillPhrase, '
                'focused on reliable delivery and continued growth.'
            : 'Experienced $cleanRole with strengths in $skillPhrase, '
                'focused on reliable delivery and continued growth.',
      ),
      CvTextSuggestion(
        label: 'General',
        text: cleanRole.isEmpty
            ? 'Seeking an opportunity to apply $skillPhrase, support team goals, '
                'and continue developing professionally.'
            : 'Seeking $rolePhrase, where I can apply $skillPhrase, support '
                'team goals, and continue developing professionally.',
      ),
    ];
  }

  /// Role-aware skill ideas. They are suggestions only; the user chooses which
  /// ones are true for them, and the caller keeps them editable.
  static List<String> skillsForProfile({
    required String role,
    required String education,
    required String experience,
  }) {
    final profile = '$role $education $experience'.toLowerCase();

    if (RegExp(r'\b(teacher|teaching|tutor|educator|school|faculty)\b')
        .hasMatch(profile)) {
      return const [
        'Lesson Planning',
        'Classroom Management',
        'Student Assessment',
        'Communication',
        'MS Office',
        'Time Management',
        'Subject Knowledge',
      ];
    }

    if (RegExp(
            r'\b(accountant|accounting|accounts|finance|commerce|b\.com|tally|gst)\b')
        .hasMatch(profile)) {
      return const [
        'MS Excel',
        'Bookkeeping',
        'Tally',
        'GST Basics',
        'Data Entry',
        'Attention to Detail',
        'Record Keeping',
      ];
    }

    if (RegExp(
            r'\b(office|admin|administrator|data entry|clerk|secretary|back office|receptionist)\b')
        .hasMatch(profile)) {
      return const [
        'MS Excel',
        'Data Entry',
        'Typing',
        'Documentation',
        'Record Keeping',
        'Communication',
        'Time Management',
      ];
    }

    if (RegExp(
            r'\b(sales|marketing|retail|customer service|customer support|business development|crm)\b')
        .hasMatch(profile)) {
      return const [
        'Communication',
        'Customer Service',
        'Negotiation',
        'Lead Generation',
        'CRM',
        'Problem Solving',
        'Teamwork',
      ];
    }

    if (RegExp(r'\b(nurse|nursing|healthcare|medical|clinical|pharmacy)\b')
        .hasMatch(profile)) {
      return const [
        'Patient Care',
        'Communication',
        'Record Keeping',
        'Teamwork',
        'Time Management',
        'First Aid',
        'Attention to Detail',
      ];
    }

    if (RegExp(
            r'\b(developer|programmer|software|flutter|dart|android|web|python|database|it|coding|computer science|computer applications|bca|data analyst)\b')
        .hasMatch(profile)) {
      if (profile.contains('flutter') || profile.contains('dart')) {
        return const [
          'Flutter',
          'Dart',
          'Firebase',
          'Git',
          'REST APIs',
          'SQL',
          'Problem Solving',
          'Debugging',
        ];
      }
      return const [
        'Problem Solving',
        'Git',
        'REST APIs',
        'SQL',
        'Python',
        'Debugging',
        'Teamwork',
        'Communication',
      ];
    }

    return const [
      'Communication',
      'Teamwork',
      'Problem Solving',
      'Time Management',
      'MS Excel',
      'Adaptability',
      'Attention to Detail',
    ];
  }

  static String workExperienceEntry({required String role}) {
    final jobTitle = role.trim().isEmpty ? '[Job title]' : role.trim();
    return '• $jobTitle — [Company] ([Start year]–[End year])\n'
        '  - [Main responsibility or task]\n'
        '  - [Achievement or result, if known]';
  }

  static const internshipEntry =
      '• Internship — [Organization] ([Start year]–[End year])\n'
      '  - Supported [task or team] using [skill or tool].\n'
      '  - Completed [deliverable or result].';

  static const projectEntry =
      '• [Project name] — [What it does] ([Tools used])\n'
      '  - [What you built, improved, or contributed].';

  static List<CvTextSuggestion> declarations({required String name}) {
    final cleanName = name.trim();
    return [
      const CvTextSuggestion(
        label: 'Standard',
        text: standardDeclaration,
      ),
      CvTextSuggestion(
        label: cleanName.isEmpty ? 'Short' : 'With my name',
        text: cleanName.isEmpty
            ? 'I confirm that the information in this CV is accurate to the '
                'best of my knowledge.'
            : 'I, $cleanName, confirm that the information in this CV is '
                'accurate to the best of my knowledge.',
      ),
    ];
  }

  static String _skillPhrase(String raw) {
    final chosen = raw
        .split(RegExp(r'[,;\n]'))
        .map((skill) => skill.trim())
        .where((skill) => skill.isNotEmpty)
        .toSet()
        .take(3)
        .toList();

    if (chosen.isEmpty) return 'my relevant skills';
    if (chosen.length == 1) return chosen.single;
    if (chosen.length == 2) return '${chosen[0]} and ${chosen[1]}';
    return '${chosen[0]}, ${chosen[1]}, and ${chosen[2]}';
  }
}
