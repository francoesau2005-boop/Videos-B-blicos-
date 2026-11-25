package com.ayudante.survival;

import android.annotation.SuppressLint;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Intent;
import android.content.pm.ServiceInfo;
import android.graphics.Color;
import android.graphics.PixelFormat;
import android.graphics.drawable.GradientDrawable;
import android.os.Build;
import android.os.IBinder;
import android.util.DisplayMetrics;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.view.WindowManager;
import android.webkit.JavascriptInterface;
import android.webkit.WebView;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

/** Burbuja flotante sobre Minecraft. Al tocarla abre el panel encima del juego. */
public class BurbujaService extends Service {

    private static final String CANAL = "burbuja";
    private static final String ACCION_CERRAR = "cerrar";

    private WindowManager wm;
    private ImageView burbuja;
    private WindowManager.LayoutParams pBurbuja;
    private LinearLayout ventana;
    private WindowManager.LayoutParams pVentana;
    private WebView web;
    private boolean abierta = false;

    @Override public IBinder onBind(Intent intent) { return null; }

    private int dp(float v) { return Math.round(v * getResources().getDisplayMetrics().density); }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent != null && ACCION_CERRAR.equals(intent.getAction())) {
            stopSelf();
            return START_NOT_STICKY;
        }
        mostrarNotificacion();
        if (burbuja == null) crearBurbuja();
        return START_STICKY;
    }

    private void mostrarNotificacion() {
        NotificationManager nm = getSystemService(NotificationManager.class);
        nm.createNotificationChannel(new NotificationChannel(CANAL, "Burbuja flotante", NotificationManager.IMPORTANCE_LOW));
        PendingIntent cerrar = PendingIntent.getService(this, 0,
                new Intent(this, BurbujaService.class).setAction(ACCION_CERRAR), PendingIntent.FLAG_IMMUTABLE);
        PendingIntent abrirApp = PendingIntent.getActivity(this, 1,
                new Intent(this, MainActivity.class), PendingIntent.FLAG_IMMUTABLE);
        Notification n = new Notification.Builder(this, CANAL)
                .setSmallIcon(android.R.drawable.ic_menu_compass)
                .setContentTitle("Ayudante Survival")
                .setContentText("Toca la burbuja sobre el juego para abrir el panel")
                .setContentIntent(abrirApp)
                .addAction(new Notification.Action.Builder(null, "Quitar burbuja", cerrar).build())
                .setOngoing(true)
                .build();
        if (Build.VERSION.SDK_INT >= 34) startForeground(1, n, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE);
        else startForeground(1, n);
    }

    @SuppressLint("ClickableViewAccessibility")
    private void crearBurbuja() {
        wm = getSystemService(WindowManager.class);

        burbuja = new ImageView(this);
        burbuja.setImageResource(R.mipmap.ic_launcher);
        int pad = dp(4);
        burbuja.setPadding(pad, pad, pad, pad);
        GradientDrawable fondo = new GradientDrawable();
        fondo.setShape(GradientDrawable.OVAL);
        fondo.setColor(Color.parseColor("#E612243a"));
        fondo.setStroke(dp(2), Color.parseColor("#5aa2ff"));
        burbuja.setBackground(fondo);
        burbuja.setAlpha(0.9f);

        pBurbuja = new WindowManager.LayoutParams(dp(54), dp(54),
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE | WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
                PixelFormat.TRANSLUCENT);
        pBurbuja.gravity = Gravity.TOP | Gravity.START;
        pBurbuja.x = dp(8);
        pBurbuja.y = dp(120);

        burbuja.setOnTouchListener(new View.OnTouchListener() {
            float tx, ty;
            int ix, iy;
            boolean movio;

            @Override
            public boolean onTouch(View v, MotionEvent e) {
                switch (e.getAction()) {
                    case MotionEvent.ACTION_DOWN:
                        tx = e.getRawX(); ty = e.getRawY();
                        ix = pBurbuja.x; iy = pBurbuja.y;
                        movio = false;
                        return true;
                    case MotionEvent.ACTION_MOVE:
                        float dx = e.getRawX() - tx, dy = e.getRawY() - ty;
                        if (Math.abs(dx) > dp(6) || Math.abs(dy) > dp(6)) movio = true;
                        if (movio) {
                            pBurbuja.x = ix + (int) dx;
                            pBurbuja.y = iy + (int) dy;
                            wm.updateViewLayout(burbuja, pBurbuja);
                        }
                        return true;
                    case MotionEvent.ACTION_UP:
                        if (!movio) alternarVentana();
                        return true;
                }
                return false;
            }
        });
        wm.addView(burbuja, pBurbuja);
    }

    private void crearVentana() {
        DisplayMetrics m = getResources().getDisplayMetrics();
        boolean horizontal = m.widthPixels > m.heightPixels;

        ventana = new LinearLayout(this);
        ventana.setOrientation(LinearLayout.VERTICAL);
        GradientDrawable borde = new GradientDrawable();
        borde.setColor(Color.parseColor("#0d1a2b"));
        borde.setStroke(dp(2), Color.parseColor("#5aa2ff"));
        borde.setCornerRadius(dp(10));
        ventana.setBackground(borde);
        ventana.setClipToOutline(true);
        ventana.setPadding(dp(2), dp(2), dp(2), dp(2));

        // barra superior: título + minimizar
        LinearLayout barra = new LinearLayout(this);
        barra.setOrientation(LinearLayout.HORIZONTAL);
        barra.setGravity(Gravity.CENTER_VERTICAL);
        barra.setPadding(dp(12), dp(4), dp(4), dp(4));
        TextView titulo = new TextView(this);
        titulo.setText("Ayudante Survival");
        titulo.setTextColor(Color.parseColor("#e3edf8"));
        titulo.setTextSize(15);
        barra.addView(titulo, new LinearLayout.LayoutParams(0, -2, 1));
        TextView minimizar = boton("Minimizar");
        minimizar.setOnClickListener(v -> alternarVentana());
        barra.addView(minimizar);
        ventana.addView(barra);

        web = Panel.crearWebView(this);
        web.addJavascriptInterface(new Puente(), "Android");
        web.loadUrl("file:///android_asset/panel.html");
        ventana.addView(web, new LinearLayout.LayoutParams(-1, 0, 1));

        int ancho = horizontal ? Math.min(dp(440), (int) (m.widthPixels * 0.55)) : m.widthPixels - dp(16);
        int alto = horizontal ? m.heightPixels - dp(24) : (int) (m.heightPixels * 0.7);
        pVentana = new WindowManager.LayoutParams(ancho, alto,
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
                PixelFormat.TRANSLUCENT);
        pVentana.gravity = horizontal ? (Gravity.END | Gravity.CENTER_VERTICAL) : (Gravity.BOTTOM | Gravity.CENTER_HORIZONTAL);
        pVentana.y = horizontal ? 0 : dp(8);
        pVentana.x = horizontal ? dp(8) : 0;
        pVentana.softInputMode = WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE;
    }

    private TextView boton(String texto) {
        TextView b = new TextView(this);
        b.setText(texto);
        b.setTextColor(Color.parseColor("#08131f"));
        b.setTextSize(14);
        b.setPadding(dp(14), dp(8), dp(14), dp(8));
        GradientDrawable f = new GradientDrawable();
        f.setColor(Color.parseColor("#5aa2ff"));
        f.setCornerRadius(dp(6));
        b.setBackground(f);
        return b;
    }

    private void alternarVentana() {
        if (ventana == null) crearVentana();
        if (abierta) {
            wm.removeView(ventana);
            abierta = false;
        } else {
            wm.addView(ventana, pVentana);
            abierta = true;
            // la burbuja queda encima de la ventana
            wm.removeView(burbuja);
            wm.addView(burbuja, pBurbuja);
        }
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        try { if (abierta) wm.removeView(ventana); } catch (Exception ignored) {}
        try { if (burbuja != null) wm.removeView(burbuja); } catch (Exception ignored) {}
        if (web != null) web.destroy();
        burbuja = null;
    }

    class Puente {
        @JavascriptInterface public boolean esApp() { return true; }
        @JavascriptInterface public boolean esFlotante() { return true; }
        @JavascriptInterface public void minimizar() { burbuja.post(BurbujaService.this::alternarVentana); }
        @JavascriptInterface public void cerrarBurbuja() { burbuja.post(BurbujaService.this::stopSelf); }
        @JavascriptInterface public void activarBurbuja() {}
        @JavascriptInterface public void abrirMinecraft() {}
        @JavascriptInterface public void instalarAddon() {}
        @JavascriptInterface public void guardarAddon() {}
    }
}
