package com.ayudante.survival;

import android.Manifest;
import android.app.Activity;
import android.content.ContentValues;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.provider.MediaStore;
import android.provider.Settings;
import android.webkit.JavascriptInterface;
import android.webkit.WebView;
import android.widget.Toast;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;

public class MainActivity extends Activity {

    static final String MINECRAFT = "com.mojang.minecraftpe";
    static final String ADDON = "AyudanteSurvival.mcaddon";

    private WebView web;
    private boolean esperandoPermisoBurbuja = false;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().setStatusBarColor(Color.parseColor("#0d1a2b"));
        web = Panel.crearWebView(this);
        web.addJavascriptInterface(new Puente(), "Android");
        web.loadUrl("file:///android_asset/panel.html");
        setContentView(web);
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (esperandoPermisoBurbuja && Settings.canDrawOverlays(this)) {
            esperandoPermisoBurbuja = false;
            iniciarBurbuja();
        }
    }

    @Override
    public void onBackPressed() {
        if (web != null && web.canGoBack()) web.goBack();
        else super.onBackPressed();
    }

    // ---------- Acciones ----------

    void activarBurbuja() {
        if (!Settings.canDrawOverlays(this)) {
            esperandoPermisoBurbuja = true;
            Toast.makeText(this, "Activa \"Mostrar sobre otras apps\" para Ayudante Survival y vuelve", Toast.LENGTH_LONG).show();
            startActivity(new Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:" + getPackageName())));
            return;
        }
        iniciarBurbuja();
    }

    private void iniciarBurbuja() {
        if (Build.VERSION.SDK_INT >= 33 && checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
            requestPermissions(new String[]{Manifest.permission.POST_NOTIFICATIONS}, 1);
        }
        startForegroundService(new Intent(this, BurbujaService.class));
        Toast.makeText(this, "Burbuja activada. Abre Minecraft y tócala para ver el panel.", Toast.LENGTH_LONG).show();
        abrirMinecraft();
    }

    void abrirMinecraft() {
        Intent i = getPackageManager().getLaunchIntentForPackage(MINECRAFT);
        if (i == null) {
            Toast.makeText(this, "No encontré Minecraft instalado", Toast.LENGTH_LONG).show();
            return;
        }
        startActivity(i);
    }

    private File copiarAddon() throws Exception {
        File f = new File(getCacheDir(), ADDON);
        try (InputStream in = getAssets().open(ADDON); OutputStream out = new FileOutputStream(f)) {
            byte[] buf = new byte[16384];
            int n;
            while ((n = in.read(buf)) > 0) out.write(buf, 0, n);
        }
        return f;
    }

    void instalarAddon() {
        try {
            copiarAddon();
            Uri uri = Uri.parse("content://com.ayudante.survival.archivos/" + ADDON);
            Intent i = new Intent(Intent.ACTION_VIEW);
            i.setDataAndType(uri, "application/octet-stream");
            i.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_ACTIVITY_NEW_TASK);
            i.setPackage(MINECRAFT);
            try {
                startActivity(i);
                Toast.makeText(this, "Minecraft va a importar el add-on", Toast.LENGTH_LONG).show();
            } catch (Exception e) {
                i.setPackage(null);
                startActivity(Intent.createChooser(i, "Abrir add-on con..."));
            }
        } catch (Exception e) {
            Toast.makeText(this, "No se pudo abrir: " + e.getMessage() + ". Prueba \"Guardar en Descargas\".", Toast.LENGTH_LONG).show();
        }
    }

    void guardarAddon() {
        if (Build.VERSION.SDK_INT < 29) {
            Toast.makeText(this, "En tu versión de Android usa \"Instalar en Minecraft\"", Toast.LENGTH_LONG).show();
            return;
        }
        try {
            ContentValues v = new ContentValues();
            v.put(MediaStore.MediaColumns.DISPLAY_NAME, ADDON);
            v.put(MediaStore.MediaColumns.MIME_TYPE, "application/octet-stream");
            Uri uri = getContentResolver().insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, v);
            try (InputStream in = getAssets().open(ADDON); OutputStream out = getContentResolver().openOutputStream(uri)) {
                byte[] buf = new byte[16384];
                int n;
                while ((n = in.read(buf)) > 0) out.write(buf, 0, n);
            }
            Toast.makeText(this, "Guardado en Descargas. Ábrelo desde tu gestor de archivos.", Toast.LENGTH_LONG).show();
        } catch (Exception e) {
            Toast.makeText(this, "No se pudo guardar: " + e.getMessage(), Toast.LENGTH_LONG).show();
        }
    }

    // ---------- Puente con el panel ----------

    class Puente {
        @JavascriptInterface public boolean esApp() { return true; }
        @JavascriptInterface public boolean esFlotante() { return false; }
        @JavascriptInterface public void activarBurbuja() { runOnUiThread(MainActivity.this::activarBurbuja); }
        @JavascriptInterface public void abrirMinecraft() { runOnUiThread(MainActivity.this::abrirMinecraft); }
        @JavascriptInterface public void instalarAddon() { runOnUiThread(MainActivity.this::instalarAddon); }
        @JavascriptInterface public void guardarAddon() { runOnUiThread(MainActivity.this::guardarAddon); }
        @JavascriptInterface public void cerrarBurbuja() {
            runOnUiThread(() -> stopService(new Intent(MainActivity.this, BurbujaService.class)));
        }
    }
}
