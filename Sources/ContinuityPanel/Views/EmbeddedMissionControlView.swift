import AppKit
import SwiftUI
import WebKit

enum EmbeddedBrowserState: Equatable {
    case loading
    case ready
    case failed(String)
}

struct EmbeddedMissionControlView: NSViewRepresentable {
    let url: URL
    let reloadToken: UUID
    let onStateChange: (EmbeddedBrowserState) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onStateChange: onStateChange, reloadToken: reloadToken)
    }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsMagnification = true
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.onStateChange = onStateChange

        if context.coordinator.reloadToken != reloadToken {
            context.coordinator.reloadToken = reloadToken
            onStateChange(.loading)
            webView.reload()
            return
        }

        guard let currentURL = webView.url else { return }
        if currentURL.host != url.host || currentURL.port != url.port {
            onStateChange(.loading)
            webView.load(URLRequest(url: url))
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var onStateChange: (EmbeddedBrowserState) -> Void
        var reloadToken: UUID

        init(onStateChange: @escaping (EmbeddedBrowserState) -> Void, reloadToken: UUID) {
            self.onStateChange = onStateChange
            self.reloadToken = reloadToken
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation?) {
            onStateChange(.loading)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
            onStateChange(.ready)
        }

        func webView(
            _ webView: WKWebView,
            didFailProvisionalNavigation navigation: WKNavigation?,
            withError error: Error
        ) {
            onStateChange(.failed(error.localizedDescription))
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation?, withError error: Error) {
            onStateChange(.failed(error.localizedDescription))
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let destination = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }

            if destination.host == "127.0.0.1" && destination.port == 3000 {
                decisionHandler(.allow)
            } else if destination.scheme == "about" {
                decisionHandler(.allow)
            } else {
                NSWorkspace.shared.open(destination)
                decisionHandler(.cancel)
            }
        }

        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            guard navigationAction.targetFrame == nil, let destination = navigationAction.request.url else {
                return nil
            }
            NSWorkspace.shared.open(destination)
            return nil
        }

        func webView(
            _ webView: WKWebView,
            runJavaScriptAlertPanelWithMessage message: String,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping () -> Void
        ) {
            let alert = NSAlert()
            alert.alertStyle = .informational
            alert.messageText = message
            alert.addButton(withTitle: "OK")
            present(alert, in: webView) { _ in completionHandler() }
        }

        func webView(
            _ webView: WKWebView,
            runJavaScriptConfirmPanelWithMessage message: String,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping (Bool) -> Void
        ) {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = message
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Cancel")
            present(alert, in: webView) { response in
                completionHandler(response == .alertFirstButtonReturn)
            }
        }

        private func present(
            _ alert: NSAlert,
            in webView: WKWebView,
            completion: @escaping (NSApplication.ModalResponse) -> Void
        ) {
            if let window = webView.window {
                alert.beginSheetModal(for: window, completionHandler: completion)
            } else {
                completion(alert.runModal())
            }
        }
    }
}
