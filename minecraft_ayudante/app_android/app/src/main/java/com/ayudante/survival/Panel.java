package com.ayudante.survival;

import android.annotation.SuppressLint;
import android.content.Context;
import android.graphics.Color;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

/** Crea el WebView que muestra el panel (incluido dentro de la app, funciona sin internet). */
final class Panel {
    private Panel() {}

    @SuppressLint("SetJavaScriptEnabled")
    static WebView crearWebView(Context ctx) {
        WebView web = new WebView(ctx);
        web.setBackgroundColor(Color.parseColor("#0d1a2b"));
        WebSettings s = web.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setDatabaseEnabled(true);
        s.setAllowFileAccess(true);
        web.setWebViewClient(new WebViewClient());
        return web;
    }
}
