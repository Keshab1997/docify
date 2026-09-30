#!/usr/bin/env python3
"""Guard the Google Sign-In configuration before an Android build runs.

    GS_JSON_B64=... python3 tool/check_firebase_config.py

Reads everything from the environment so nothing secret ever appears in a
workflow log:

    GS_JSON_B64        base64 of android/app/google-services.json
                       (the GOOGLE_SERVICES_JSON_BASE64 repository secret)
    SERVER_CLIENT_ID   the GOOGLE_SERVER_CLIENT_ID repository variable
    PACKAGE_NAME       applicationId the config must belong to
    REQUIRE_FIREBASE   non-empty -> an absent config is an error, not a warning

Why this exists
---------------
`google-services.json` being present and valid JSON is not enough. Google
Sign-In on Android needs a *Web application* OAuth client -- an `oauth_client`
entry with `client_type: 3`. The google-services Gradle plugin turns that
entry into the `default_web_client_id` string resource, and the
`google_sign_in` plugin uses it as the audience for the ID token.

A file downloaded before "Google" was enabled as an Authentication provider
has no such entry. The build still succeeds, the APK still installs, and the
failure only appears on the first tap:

    GoogleSignInException(code: clientConfigurationError,
        "serverClientId must be provided on Android")

Every check below is cheap and runs in milliseconds, so a broken config fails
the job before Gradle starts instead of after eight minutes of it.

Exit codes: 0 = safe to build (including an intentional guest build),
1 = this APK could never sign a user in.
"""

import base64
import binascii
import json
import os
import sys

# The client_type value Google uses for a "Web application" OAuth client.
WEB_CLIENT_TYPE = 3
ANDROID_CLIENT_TYPE = 1

DOCS = "docs/sync_setup.md"


def notice(msg):
    print("::notice::%s" % msg)


def warn(msg):
    print("::warning::%s" % msg)


def fail(msg):
    """Emit a GitHub error annotation and stop the build."""
    print("::error::%s" % msg)
    sys.exit(1)


def load_config(raw_b64):
    """Decode the secret into the google-services.json object."""
    try:
        decoded = base64.b64decode(raw_b64, validate=True)
    except (binascii.Error, ValueError) as exc:
        fail(
            "GOOGLE_SERVICES_JSON_BASE64 is not valid base64 (%s). Re-create "
            "it with: base64 -w0 android/app/google-services.json" % exc
        )
    try:
        return json.loads(decoded.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        fail(
            "GOOGLE_SERVICES_JSON_BASE64 decodes to something that is not JSON "
            "(%s). Did the base64 get truncated or pick up a shell prompt?"
            % exc
        )


def package_names(config):
    """Every android package_name the config knows about."""
    names = []
    for client in config.get("client", []):
        info = client.get("client_info", {})
        android = info.get("android_client_info", {})
        name = android.get("package_name")
        if name:
            names.append(name)
    return names


def oauth_clients(config, client_type):
    """All oauth_client ids of one client_type across every app in the file."""
    found = []
    for client in config.get("client", []):
        for oauth in client.get("oauth_client", []):
            if oauth.get("client_type") == client_type:
                cid = oauth.get("client_id", "")
                if cid:
                    found.append(cid)
    return found


def main():
    raw_b64 = os.environ.get("GS_JSON_B64", "").strip()
    server_client_id = os.environ.get("SERVER_CLIENT_ID", "").strip()
    package_name = os.environ.get("PACKAGE_NAME", "").strip()
    require_firebase = bool(os.environ.get("REQUIRE_FIREBASE", "").strip())

    print("Google Sign-In configuration check")
    print("  package_name          : %s" % (package_name or "(unset)"))
    print("  GOOGLE_SERVER_CLIENT_ID: %s" % (server_client_id or "(not set)"))
    print("  require-firebase      : %s" % ("yes" if require_firebase else "no"))

    if not raw_b64:
        if require_firebase:
            fail(
                "GOOGLE_SERVICES_JSON_BASE64 is not set but require-firebase is "
                "on, so this build would ship with Sign-In silently disabled. "
                "Set the secret (base64 -w0 android/app/google-services.json) "
                "or turn require-firebase off for an intentional guest build. "
                "See %s step 2." % DOCS
            )
        warn(
            "GOOGLE_SERVICES_JSON_BASE64 is not set: this APK will be "
            "guest-only and the Profile screen will say \"Sign-in not enabled "
            "on this build\". Intentional? Then ignore this. See %s step 2."
            % DOCS
        )
        return 0

    config = load_config(raw_b64)

    # 1. Right app? The Gradle plugin hard-fails on a mismatch, but saying so
    #    here points at the fix instead of at a wall of Gradle output.
    if package_name:
        names = package_names(config)
        if names and package_name not in names:
            fail(
                "google-services.json is for package(s) %s but this app is %s "
                "- wrong Firebase app or wrong project. Download the file for "
                "the %s Android app. See %s step 2."
                % (names, package_name, package_name, DOCS)
            )
        print("  package in config     : yes (%s)" % package_name)

    project = config.get("project_info", {})
    print(
        "  firebase project      : %s (number %s)"
        % (
            project.get("project_id", "?"),
            project.get("project_number", "?"),
        )
    )

    web_clients = oauth_clients(config, WEB_CLIENT_TYPE)
    android_clients = oauth_clients(config, ANDROID_CLIENT_TYPE)
    print("  web oauth clients     : %d %s" % (len(web_clients), web_clients))
    print("  android oauth clients : %d" % len(android_clients))

    # 2. The check that actually matters.
    if web_clients:
        if not android_clients:
            warn(
                "google-services.json has a Web OAuth client but no Android "
                "one (package_name + SHA-1). Firebase normally creates that "
                "when you register the app; without it Sign-In fails with "
                "api_exception. See %s step 1." % DOCS
            )
        if server_client_id and server_client_id not in web_clients:
            warn(
                "GOOGLE_SERVER_CLIENT_ID (%s) is not one of the Web OAuth "
                "clients inside google-services.json (%s). The build compiles "
                "the variable in, so it wins - but the two disagreeing usually "
                "means the secret is stale. Re-download the file, or clear the "
                "variable and let default_web_client_id do the job. See %s "
                "step 6." % (server_client_id, web_clients, DOCS)
            )
        elif not server_client_id:
            notice(
                "google-services.json carries a Web OAuth client, so the "
                "google-services plugin will generate default_web_client_id "
                "and Sign-In has an audience. GOOGLE_SERVER_CLIENT_ID is not "
                "needed."
            )
        else:
            notice(
                "Web OAuth client present and GOOGLE_SERVER_CLIENT_ID agrees "
                "with it."
            )
        return 0

    if server_client_id:
        notice(
            "google-services.json has no Web OAuth client, but "
            "GOOGLE_SERVER_CLIENT_ID (%s) is set and will be compiled in as "
            "serverClientId, which is enough. Cleaner fix: enable Google under "
            "Firebase > Authentication > Sign-in method, re-download the file "
            "and re-set GOOGLE_SERVICES_JSON_BASE64. See %s step 6."
            % (server_client_id, DOCS)
        )
        return 0

    fail(
        "google-services.json contains NO Web OAuth client (client_type 3) and "
        "GOOGLE_SERVER_CLIENT_ID is empty. The APK will have no "
        "default_web_client_id, google_sign_in will initialise without a "
        "serverClientId, and the first tap on \"Sign in with Google\" will "
        "fail with clientConfigurationError: \"serverClientId must be provided "
        "on Android\". Fix, then re-run this build:\n"
        "  1. Firebase console > project %s > Authentication > Sign-in method "
        "> Google > Enable.\n"
        "  2. Project settings > Your apps > add a Web app (this creates the "
        "<id>.apps.googleusercontent.com client).\n"
        "  3. Re-download google-services.json - it must now contain an "
        "oauth_client with client_type 3.\n"
        "  4. base64 -w0 android/app/google-services.json  ->  update the "
        "GOOGLE_SERVICES_JSON_BASE64 secret.\n"
        "  5. Belt and braces: also set the GOOGLE_SERVER_CLIENT_ID repository "
        "variable to that web client id.\n"
        "  6. Uninstall the old app before testing the new APK.\n"
        "Full walkthrough: %s steps 2 and 6."
        % (project.get("project_id", "?"), DOCS)
    )
    return 1


if __name__ == "__main__":
    sys.exit(main())
