package com.maiancu.app;

import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

// Honest-partial -> the suburb data the goal names -> the phone app -> what a page script can reach
// Goal:      behavior 161 — a script in the page the app loads (maiancu.com, or a web dependency
//            gone bad) reaches no more than it does on the website plus the in-app browser.
// Invariant: Capacitor's core WebView plugin (repointing what the app loads, and keeping it across launches) is replaced by this stub:
//            every method rejects «disabled in Mai An Cư», and nothing is sent anywhere.
// Capability: @capacitor/android 8.5.3 registers WebView whatever npm plugins are installed
//            (Bridge.registerAllPlugins), then this app's own (MainActivity, registerPlugin),
//            into one map keyed by name, so a plugin of ours with the same name replaces it.
@CapacitorPlugin(name = "WebView")
public class NoWebView extends Plugin {

    private static void refuse(PluginCall call) {
        call.reject("disabled in Mai An Cư");
    }

    @PluginMethod
    public void setServerAssetPath(PluginCall call) {
        refuse(call);
    }

    @PluginMethod
    public void setServerBasePath(PluginCall call) {
        refuse(call);
    }

    @PluginMethod
    public void getServerBasePath(PluginCall call) {
        refuse(call);
    }

    @PluginMethod
    public void persistServerBasePath(PluginCall call) {
        refuse(call);
    }
}
