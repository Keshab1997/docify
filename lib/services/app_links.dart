/// Links that ship with the app.
///
/// The web build is published by the repository's Web Preview workflow:
/// every branch gets its own `preview/<branch>/` folder on GitHub Pages,
/// and `main` is the one that stays. The About section links to it so the
/// app can be tried in a browser without installing the APK.
const String docifyWebPreviewUrl =
    'https://keshab1997.github.io/docify/preview/main/';

/// The designed "About Docify" page on the same GitHub Pages site as the
/// privacy policy and terms (source: docs/website/about.html).
const String docifyAboutUrl = 'https://keshab1997.github.io/docify/about.html';
