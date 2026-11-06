package com.maiancu.app;

import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

// Honest-partial -> the suburb data the goal names -> the phone app -> what a page script can reach
// Goal:      behavior 161 — a script in the page the app loads (maiancu.com, or a web dependency
//            gone bad) reaches no more than it does on the website plus the in-app browser.
// Invariant: Capacitor's core CapacitorHttp plugin (native HTTP to any host with no CORS, the phone's own network included) is replaced by this stub:
//            every method rejects «disabled in Mai An Cư», and nothing is sent anywhere.
// Capability: @capacitor/android 8.5.3 registers CapacitorHttp whatever npm plugins are installed
//            (Bridge.registerAllPlugins), then this app's own (MainActivity, registerPlugin),
//            into one map keyed by name, so a plugin of ours with the same name replaces it.
//            The core one has already loaded by then and added the JavascriptInterface
//            «CapacitorHttpAndroidInterface»; load() here removes it before the first page loads
//            (Bridge: registerAllPlugins, then loadWebView), and native-bridge.js checks for it
//            with typeof before use.
@CapacitorPlugin(name = "CapacitorHttp")
public class NoHttp extends Plugin {

    @Override
    public void load() {
        getBridge().getWebView().removeJavascriptInterface("CapacitorHttpAndroidInterface");
        super.load();
    }

    private static void refuse(PluginCall call) {
        call.reject("disabled in Mai An Cư");
    }

    @PluginMethod
    public void request(PluginCall call) {
        refuse(call);
    }

    @PluginMethod
    public void get(PluginCall call) {
        refuse(call);
    }

    @PluginMethod
    public void post(PluginCall call) {
        refuse(call);
    }

    @PluginMethod
    public void put(PluginCall call) {
        refuse(call);
    }

    @PluginMethod
    public void patch(PluginCall call) {
        refuse(call);
    }

    @PluginMethod
    public void delete(PluginCall call) {
        refuse(call);
    }
}
