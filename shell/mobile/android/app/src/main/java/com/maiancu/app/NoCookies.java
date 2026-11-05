package com.maiancu.app;

import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

// Honest-partial -> the suburb data the goal names -> the phone app -> what a page script can reach
// Goal:      behavior 161 — a script in the page the app loads (maiancu.com, or a web dependency
//            gone bad) reaches no more than it does on the website plus the in-app browser.
// Invariant: Capacitor's core CapacitorCookies plugin (setting or clearing cookies for any URL in the web view's jar) is replaced by this stub:
//            every method rejects «disabled in Mai An Cư», and nothing is sent anywhere.
// Capability: @capacitor/android 8.5.3 registers CapacitorCookies whatever npm plugins are installed
//            (Bridge.registerAllPlugins), then this app's own (MainActivity, registerPlugin),
//            into one map keyed by name, so a plugin of ours with the same name replaces it.
//            The core one has already loaded by then and added the JavascriptInterface
//            «CapacitorCookiesAndroidInterface»; load() here removes it before the first page loads
//            (Bridge: registerAllPlugins, then loadWebView), and native-bridge.js checks for it
//            with typeof before use.
@CapacitorPlugin(name = "CapacitorCookies")
public class NoCookies extends Plugin {

    @Override
    public void load() {
        getBridge().getWebView().removeJavascriptInterface("CapacitorCookiesAndroidInterface");
        super.load();
    }

    private static void refuse(PluginCall call) {
        call.reject("disabled in Mai An Cư");
    }

    @PluginMethod
    public void getCookies(PluginCall call) {
        refuse(call);
    }

    @PluginMethod
    public void setCookie(PluginCall call) {
        refuse(call);
    }

    @PluginMethod
    public void deleteCookie(PluginCall call) {
        refuse(call);
    }

    @PluginMethod
    public void clearCookies(PluginCall call) {
        refuse(call);
    }

    @PluginMethod
    public void clearAllCookies(PluginCall call) {
        refuse(call);
    }
}
