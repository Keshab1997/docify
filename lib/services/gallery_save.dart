/// Saves a JPEG into the phone gallery, or downloads it in the browser.
library;

export 'gallery_save_mobile.dart'
    if (dart.library.js_interop) 'gallery_save_web.dart';
