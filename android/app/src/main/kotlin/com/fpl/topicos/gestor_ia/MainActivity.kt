package com.fpl.topicos.gestor_ia

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

// The default template relies on FlutterEngine finding
// io.flutter.plugins.GeneratedPluginRegistrant via reflection at runtime
// (Class.forName). In this project's release build that reflective lookup
// fails ("could not find or invoke the GeneratedPluginRegistrant" in
// logcat) even though the generated class is present and correct, so every
// platform channel (flutter_secure_storage included) ends up with no
// handler attached, surfacing as MissingPluginException. Registering
// explicitly here uses a compile-time reference instead of reflection,
// bypassing whatever breaks the reflective path.
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GeneratedPluginRegistrant.registerWith(flutterEngine)
    }
}
