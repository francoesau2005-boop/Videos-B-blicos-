package com.rotisimo.ff;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Intent;
import android.graphics.Color;
import android.net.Uri;
import android.webkit.ValueCallback;
import android.webkit.WebChromeClient;
import android.os.Bundle;
import android.webkit.JavascriptInterface;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Toast;

public class MainActivity extends Activity {

    private static final String[] JUEGOS = {"com.dts.freefireth", "com.dts.freefiremax"};
    private static final int PEDIR_IMAGEN = 7;
    private WebView web;
    private ValueCallback<Uri[]> alElegir;

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
        // permite elegir una imagen de la galería con <input type="file">
        web.setWebChromeClient(new WebChromeClient() {
            @Override
            public boolean onShowFileChooser(WebView v, ValueCallback<Uri[]> cb, FileChooserParams params) {
                if (alElegir != null) alElegir.onReceiveValue(null);
                alElegir = cb;
                Intent i = new Intent(Intent.ACTION_GET_CONTENT);
                i.addCategory(Intent.CATEGORY_OPENABLE);
                String[] tipos = params.getAcceptTypes();
                i.setType(tipos.length > 0 && tipos[0].startsWith("image") ? "image/*" : "*/*");
                try {
                    startActivityForResult(Intent.createChooser(i, "Elige una imagen"), PEDIR_IMAGEN);
                } catch (Exception e) {
                    alElegir = null;
                    Toast.makeText(MainActivity.this, "No encontré una galería", Toast.LENGTH_LONG).show();
                    return false;
                }
                return true;
            }
        });
        web.addJavascriptInterface(new Puente(), "Android");
        web.loadUrl("file:///android_asset/index.html");
        setContentView(web);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == PEDIR_IMAGEN && alElegir != null) {
            alElegir.onReceiveValue(WebChromeClient.FileChooserParams.parseResult(resultCode, data));
            alElegir = null;
        }
    }

    @Override
    public void onBackPressed() {
        web.evaluateJavascript("(function(){var h=document.getElementById('hoja');if(h&&!h.hidden){cerrarHoja();return 1}return 0})()", r -> {
            if (!"1".equals(r)) MainActivity.super.onBackPressed();
        });
    }

    class Puente {
        @JavascriptInterface public boolean esApp() { return true; }

        @JavascriptInterface public void copiar(String texto) {
            runOnUiThread(() -> {
                ClipboardManager cm = getSystemService(ClipboardManager.class);
                cm.setPrimaryClip(ClipData.newPlainText("Rotísimo", texto));
            });
        }

        // guarda un archivo (paquete de imágenes) en Descargas
        @JavascriptInterface public void guardarArchivo(String nombre, String contenido) {
            runOnUiThread(() -> {
                try {
                    android.content.ContentValues v = new android.content.ContentValues();
                    v.put(android.provider.MediaStore.MediaColumns.DISPLAY_NAME, nombre);
                    v.put(android.provider.MediaStore.MediaColumns.MIME_TYPE, "application/json");
                    java.io.OutputStream out;
                    if (android.os.Build.VERSION.SDK_INT >= 29) {
                        Uri uri = getContentResolver().insert(android.provider.MediaStore.Downloads.EXTERNAL_CONTENT_URI, v);
                        out = getContentResolver().openOutputStream(uri);
                    } else {
                        java.io.File f = new java.io.File(getExternalFilesDir(null), nombre);
                        out = new java.io.FileOutputStream(f);
                    }
                    out.write(contenido.getBytes(java.nio.charset.StandardCharsets.UTF_8));
                    out.close();
                    Toast.makeText(MainActivity.this, "Guardado en Descargas: " + nombre, Toast.LENGTH_LONG).show();
                } catch (Exception e) {
                    Toast.makeText(MainActivity.this, "No se pudo guardar: " + e.getMessage(), Toast.LENGTH_LONG).show();
                }
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
