package com.rotisimo.ff;

import android.app.Activity;
import android.util.DisplayMetrics;
import android.widget.FrameLayout;

import com.google.android.gms.ads.AdListener;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.AdSize;
import com.google.android.gms.ads.AdView;
import com.google.android.gms.ads.FullScreenContentCallback;
import com.google.android.gms.ads.LoadAdError;
import com.google.android.gms.ads.MobileAds;
import com.google.android.gms.ads.rewarded.RewardedAd;
import com.google.android.gms.ads.rewarded.RewardedAdLoadCallback;
import com.google.android.ump.ConsentInformation;
import com.google.android.ump.ConsentRequestParameters;
import com.google.android.ump.UserMessagingPlatform;

import java.util.concurrent.atomic.AtomicBoolean;

/** Banner abajo + anuncio con recompensa (Combo PRO). Los códigos están en gradle.properties. */
final class Anuncios {

    interface AlTerminar { void listo(boolean premio); }

    private final Activity act;
    private final FrameLayout contenedor;
    private final AtomicBoolean iniciado = new AtomicBoolean(false);
    private RewardedAd recompensa;
    private boolean cargando = false;

    Anuncios(Activity act, FrameLayout contenedor) {
        this.act = act;
        this.contenedor = contenedor;
    }

    /** Pide el consentimiento cuando la ley lo exige (Europa, etc.) y luego inicia los anuncios. */
    void iniciar() {
        ConsentInformation ci = UserMessagingPlatform.getConsentInformation(act);
        ci.requestConsentInfoUpdate(act, new ConsentRequestParameters.Builder().build(),
                () -> UserMessagingPlatform.loadAndShowConsentFormIfRequired(act, err -> {
                    if (ci.canRequestAds()) arrancar();
                }),
                err -> arrancar());
        if (ci.canRequestAds()) arrancar();
    }

    private void arrancar() {
        if (iniciado.getAndSet(true)) return;
        MobileAds.initialize(act, estado -> {
            act.runOnUiThread(() -> {
                ponerBanner();
                cargarRecompensa();
            });
        });
    }

    private void ponerBanner() {
        AdView banner = new AdView(act);
        banner.setAdUnitId(BuildConfig.ADMOB_BANNER);
        DisplayMetrics m = act.getResources().getDisplayMetrics();
        int anchoDp = (int) (m.widthPixels / m.density);
        banner.setAdSize(AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(act, anchoDp));
        banner.setAdListener(new AdListener() {
            @Override public void onAdLoaded() { contenedor.setVisibility(android.view.View.VISIBLE); }
            @Override public void onAdFailedToLoad(LoadAdError e) { contenedor.setVisibility(android.view.View.GONE); }
        });
        contenedor.removeAllViews();
        contenedor.addView(banner);
        banner.loadAd(new AdRequest.Builder().build());
    }

    private void cargarRecompensa() {
        if (cargando || recompensa != null) return;
        cargando = true;
        RewardedAd.load(act, BuildConfig.ADMOB_RECOMPENSA, new AdRequest.Builder().build(), new RewardedAdLoadCallback() {
            @Override public void onAdLoaded(RewardedAd ad) { recompensa = ad; cargando = false; }
            @Override public void onAdFailedToLoad(LoadAdError e) { recompensa = null; cargando = false; }
        });
    }

    /** Muestra el anuncio con recompensa. premio=true solo si lo vio completo. */
    void verRecompensa(AlTerminar fin) {
        if (!iniciado.get()) { fin.listo(false); return; }
        if (recompensa == null) { cargarRecompensa(); fin.listo(false); return; }
        final boolean[] gano = {false};
        RewardedAd ad = recompensa;
        recompensa = null;
        ad.setFullScreenContentCallback(new FullScreenContentCallback() {
            @Override public void onAdDismissedFullScreenContent() { fin.listo(gano[0]); cargarRecompensa(); }
            @Override public void onAdFailedToShowFullScreenContent(com.google.android.gms.ads.AdError e) { fin.listo(false); cargarRecompensa(); }
        });
        ad.show(act, item -> gano[0] = true);
    }
}
