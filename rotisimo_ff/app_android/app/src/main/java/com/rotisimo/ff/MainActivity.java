package com.rotisimo.ff;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Intent;
import android.graphics.Color;
import android.os.Bundle;
import android.webkit.JavascriptInterface;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Toast;

public class MainActivity extends Activity {

    private static final String[] JUEGOS = {"com.dts.freefireth", "com.dts.freefiremax"};
    private WebView web;

    @SuppressLint("SetJavaScriptEnabled")
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().setStatusBarColor(Color.parseColor("#0b0d12"));
        getWindow().setNavigationBarColor(Color.parseColor("#0b0d12"));
        web = new WebView(this);
        web.setBackgroundColor(Color.parseColor("#0b0d12"));
        WebSettings s = web.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setAllowFileAccess(true);
        web.setWebViewClient(new WebViewClient());
        web.addJavascriptInterface(new Puente(), "Android");
        web.loadUrl("file:///android_asset/index.html");
        setContentView(web);
    }

    class Puente {
        @JavascriptInterface public boolean esApp() { return true; }

        @JavascriptInterface public void copiar(String texto) {
            runOnUiThread(() -> {
                ClipboardManager cm = getSystemService(ClipboardManager.class);
                cm.setPrimaryClip(ClipData.newPlainText("Rotísimo", texto));
            });
        }

        @JavascriptInterface public void abrirJuego() {
            runOnUiThread(() -> {
                for (String p : JUEGOS) {
                    Intent i = getPackageManager().getLaunchIntentForPackage(p);
                    if (i != null) { startActivity(i); return; }
                }
                Toast.makeText(MainActivity.this, "No encontré el juego instalado", Toast.LENGTH_LONG).show();
            });
        }
    }
}
