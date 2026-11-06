package com.maiancu.app;

import android.os.Bundle;
import com.getcapacitor.BridgeActivity;

// Honest-partial -> the suburb data the goal names -> the phone app -> the bridge's plugins
// Goal:      behavior 161 — the page reaches the in-app browser (@capacitor/browser), the status
//            bar and the log, and none of Capacitor's CapacitorHttp, CapacitorCookies or WebView.
// Invariant: the three stubs are registered before super.onCreate builds the bridge, so they
//            replace the core plugins of the same name (NoHttp, NoCookies, NoWebView).
// Capability: BridgeActivity.registerPlugin adds to the bridge's initial plugins, registered
//            after the core ones (@capacitor/android 8.5.3 Bridge.registerAllPlugins).
public class MainActivity extends BridgeActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        registerPlugin(NoHttp.class);
        registerPlugin(NoCookies.class);
        registerPlugin(NoWebView.class);
        super.onCreate(savedInstanceState);
    }
}
