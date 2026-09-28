import 'cv_data.dart';

/// Maps text down to characters the CV templates can actually draw.
///
/// The templates render with the built-in Helvetica font, which only covers
/// Latin-1 (U+0020 - U+00FF). Anything above that range is drawn as an empty
/// box, so an em dash pasted from Word, a curly quote from WhatsApp or a rupee
/// sign all came out as `□` on the PDF.
///
/// Everything the user types is passed through [clean] before a template sees
/// it, which fixes the problem once for all ten designs instead of per
/// template. Typographic characters are mapped to the closest Latin-1
/// equivalent; anything still undrawable is dropped rather than printed as a
/// box.
///
/// If the templates ever move to a bundled Unicode font, this class is the one
/// place that needs to change.
class CvTextSanitizer {
  const CvTextSanitizer._();

  /// Multi-character replacements are allowed, so `—` can become `-` and `₹`
  /// can become `Rs.`.
  static const Map<int, String> _replacements = {
    0x2010: '-', // hyphen
    0x2011: '-', // non-breaking hyphen
    0x2012: '-', // figure dash
    0x2013: '-', // en dash
    0x2014: '-', // em dash
    0x2015: '-', // horizontal bar
    0x2018: "'", // left single quote
    0x2019: "'", // right single quote
    0x201A: "'", // single low quote
    0x201B: "'", // single high-reversed quote
    0x201C: '"', // left double quote
    0x201D: '"', // right double quote
    0x201E: '"', // double low quote
    0x2022: '\u00B7', // bullet -> middle dot (drawable)
    0x2023: '\u00B7', // triangular bullet
    0x25CF: '\u00B7', // black circle
    0x25AA: '\u00B7', // black small square
    0x2026: '...', // ellipsis
    0x20B9: 'Rs.', // indian rupee
    0x2192: '->', // right arrow
    0x2190: '<-', // left arrow
    0x2713: '+', // check mark
    0x2714: '+', // heavy check mark
    0x00A0: ' ', // non-breaking space
    0x2009: ' ', // thin space
    0x200B: '', // zero width space
  };

  /// Characters that may pass through untouched even though they are control
  /// codes, because they carry the layout of multi-line fields.
  static const Set<int> _keepControl = {0x09, 0x0A, 0x0D};

  /// Returns [input] with every character replaced by something the templates
  /// can render.
  static String clean(String input) {
    if (input.isEmpty) return input;
    // Fast path: pure ASCII is always safe and is the common case.
    var ascii = true;
    for (final rune in input.runes) {
      if (rune > 0x7F) {
        ascii = false;
        break;
      }
    }
    if (ascii) return input;

    final out = StringBuffer();
    for (final rune in input.runes) {
      final mapped = _replacements[rune];
      if (mapped != null) {
        out.write(mapped);
      } else if (_keepControl.contains(rune)) {
        out.writeCharCode(rune);
      } else if (rune >= 0x20 && rune <= 0xFF) {
        out.writeCharCode(rune);
      }
      // Anything else cannot be drawn by the built-in font: drop it instead of
      // printing a box. Latin-1 covers the Bengali and Devanagari ranges not at
      // all, so those would be boxes on every page today.
    }
    return out.toString();
  }

  /// The first character in [input] that [clean] would drop, or null when the
  /// whole string can be printed.
  ///
  /// [clean] also rewrites punctuation that merely has a nicer Latin-1 stand-in
  /// — an em dash becomes a hyphen, a bullet becomes a middle dot — and the user
  /// never needs to hear about that. Only characters that vanish completely are
  /// reported by this method, which is what the form warns about.
  static String? lostChar(String input) {
    for (final rune in input.runes) {
      if (_replacements.containsKey(rune)) continue;
      if (_keepControl.contains(rune)) continue;
      if (rune >= 0x20 && rune <= 0xFF) continue;
      return String.fromCharCode(rune);
    }
    return null;
  }

  /// Labels of the CV fields whose text would lose characters in the PDF, in
  /// the order they appear in the form. Empty when everything can be printed.
  ///
  /// Bengali and other Indic scripts always show up here today: they fall
  /// outside Latin-1 and the built-in font has no glyphs for them.
  static List<String> undrawableFields(CvData data) {
    final fields = <String, String>{
      'Full Name': data.name,
      'Professional Title': data.title,
      'Email': data.email,
      'Mobile': data.phone,
      'Address': data.address,
      'Date of Birth': data.dob,
      "Father's Name": data.father,
      'Career Objective': data.objective,
      'Education': data.education,
      'Experience': data.experience,
      'Skills': data.skills,
      'Languages': data.languages,
      'Declaration': data.declaration,
    };
    return [
      for (final entry in fields.entries)
        if (lostChar(entry.value) != null) entry.key,
    ];
  }

  /// Returns a copy of [data] with every text field cleaned.
  static CvData cleanData(CvData data) => CvData(
        name: clean(data.name),
        title: clean(data.title),
        email: clean(data.email),
        phone: clean(data.phone),
        address: clean(data.address),
        dob: clean(data.dob),
        father: clean(data.father),
        objective: clean(data.objective),
        education: clean(data.education),
        experience: clean(data.experience),
        skills: clean(data.skills),
        languages: clean(data.languages),
        declaration: clean(data.declaration),
        photo: data.photo,
        template: data.template,
      );
}
