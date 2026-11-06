import Capacitor
import UIKit
import WebKit

// Honest-partial -> the suburb data the goal names -> the phone app -> the bridge's plugins
// Goal:      behavior 161 — the page reaches the in-app browser (@capacitor/browser), the status
//            bar and the log, and none of Capacitor's CapacitorHttp, CapacitorCookies or WebView.
// Invariant: the three stubs replace the core plugins of the same name before the first page
//            loads, and a page's prompt() carrying a CapacitorCookies.* or CapacitorHttp request
//            is answered here, never reaching CapacitorCookieManager — on iOS that prompt is
//            the second path in, as Android's JavascriptInterfaces are there (NoCookies.java).
// Capability: capacitorDidLoad runs in loadView, after the bridge registers its core plugins
//            and before viewDidLoad loads the page; registerPluginInstance replaces a plugin
//            of the same jsName («Overriding existing registered plugin»); the web view's
//            uiDelegate is WebViewDelegationHandler, whose runJavaScriptTextInputPanel
//            answers those prompts (@capacitor/ios 8.5.3 CAPBridgeViewController.swift,
//            CapacitorBridge.swift, WebViewDelegationHandler.swift).
class MainViewController: CAPBridgeViewController {
    private var promptGuard: PromptGuard?

    override func capacitorDidLoad() {
        bridge?.registerPluginInstance(NoHttp())
        bridge?.registerPluginInstance(NoCookies())
        bridge?.registerPluginInstance(NoWebView())
        if let webView = webView, let inner = webView.uiDelegate {
            let g = PromptGuard(inner)
            promptGuard = g // uiDelegate is weak
            webView.uiDelegate = g
        }
        CAPLog.print("⚡️  Mai An Cư: stubs for CapacitorHttp, CapacitorCookies, WebView; prompt guard \(promptGuard != nil ? "on" : "OFF")")
    }
}

/// Answers Capacitor's synchronous cookie / http prompts with "disabled"; forwards every other
/// WKUIDelegate call (alerts, confirms, ordinary prompts, file pickers) to Capacitor's handler.
final class PromptGuard: NSObject, WKUIDelegate {
    private let inner: WKUIDelegate

    init(_ inner: WKUIDelegate) {
        self.inner = inner
    }

    override func responds(to aSelector: Selector!) -> Bool {
        super.responds(to: aSelector) || inner.responds(to: aSelector)
    }

    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        inner.responds(to: aSelector) ? inner : nil
    }

    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String,
                 defaultText: String?, initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (String?) -> Void) {
        if let data = prompt.data(using: .utf8),
           let payload = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any],
           let type = payload["type"] as? String,
           type.hasPrefix("CapacitorCookies") || type == "CapacitorHttp" {
            CAPLog.print("⚡️  Mai An Cư: refused \(type) prompt")
            completionHandler(type.hasSuffix("isEnabled") || type == "CapacitorHttp" ? "false" : "")
            return
        }
        guard let ask = inner.webView(_:runJavaScriptTextInputPanelWithPrompt:defaultText:initiatedByFrame:completionHandler:) else {
            completionHandler(nil)
            return
        }
        ask(webView, prompt, defaultText, frame, completionHandler)
    }
}

private func refuse(_ call: CAPPluginCall) {
    call.reject("disabled in Mai An Cư")
}

@objc(NoHttp)
final class NoHttp: CAPPlugin, CAPBridgedPlugin {
    let identifier = "NoHttp"
    let jsName = "CapacitorHttp"
    let pluginMethods: [CAPPluginMethod] = ["request", "get", "post", "put", "patch", "delete"].map {
        CAPPluginMethod(name: $0, returnType: CAPPluginReturnPromise)
    }
    @objc func request(_ call: CAPPluginCall) { refuse(call) }
    @objc func get(_ call: CAPPluginCall) { refuse(call) }
    @objc func post(_ call: CAPPluginCall) { refuse(call) }
    @objc func put(_ call: CAPPluginCall) { refuse(call) }
    @objc func patch(_ call: CAPPluginCall) { refuse(call) }
    @objc func delete(_ call: CAPPluginCall) { refuse(call) }
}

@objc(NoCookies)
final class NoCookies: CAPPlugin, CAPBridgedPlugin {
    let identifier = "NoCookies"
    let jsName = "CapacitorCookies"
    let pluginMethods: [CAPPluginMethod] = ["getCookies", "setCookie", "deleteCookie", "clearCookies", "clearAllCookies"].map {
        CAPPluginMethod(name: $0, returnType: CAPPluginReturnPromise)
    }
    @objc func getCookies(_ call: CAPPluginCall) { refuse(call) }
    @objc func setCookie(_ call: CAPPluginCall) { refuse(call) }
    @objc func deleteCookie(_ call: CAPPluginCall) { refuse(call) }
    @objc func clearCookies(_ call: CAPPluginCall) { refuse(call) }
    @objc func clearAllCookies(_ call: CAPPluginCall) { refuse(call) }
}

@objc(NoWebView)
final class NoWebView: CAPPlugin, CAPBridgedPlugin {
    let identifier = "NoWebView"
    let jsName = "WebView"
    let pluginMethods: [CAPPluginMethod] = ["setServerAssetPath", "setServerBasePath", "getServerBasePath", "persistServerBasePath"].map {
        CAPPluginMethod(name: $0, returnType: CAPPluginReturnPromise)
    }
    @objc func setServerAssetPath(_ call: CAPPluginCall) { refuse(call) }
    @objc func setServerBasePath(_ call: CAPPluginCall) { refuse(call) }
    @objc func getServerBasePath(_ call: CAPPluginCall) { refuse(call) }
    @objc func persistServerBasePath(_ call: CAPPluginCall) { refuse(call) }
}
