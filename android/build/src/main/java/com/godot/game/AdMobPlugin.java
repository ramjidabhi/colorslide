package com.godot.game;

import android.app.Activity;
import android.content.Context;
import android.net.ConnectivityManager;
import android.net.NetworkCapabilities;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.google.android.gms.ads.AdError;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.FullScreenContentCallback;
import com.google.android.gms.ads.LoadAdError;
import com.google.android.gms.ads.MobileAds;
import com.google.android.gms.ads.OnUserEarnedRewardListener;
import com.google.android.gms.ads.initialization.InitializationStatus;
import com.google.android.gms.ads.initialization.OnInitializationCompleteListener;
import com.google.android.gms.ads.interstitial.InterstitialAd;
import com.google.android.gms.ads.interstitial.InterstitialAdLoadCallback;
import com.google.android.gms.ads.rewarded.RewardItem;
import com.google.android.gms.ads.rewarded.RewardedAd;
import com.google.android.gms.ads.rewarded.RewardedAdLoadCallback;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;

import java.util.HashSet;
import java.util.Set;

/**
 * Production-ready AdMob Godot Android Plugin.
 * Exposes rewarded video and interstitial ads to GDScript.
 */
public class AdMobPlugin extends GodotPlugin {
    private static final String TAG = "AdMobPlugin";

    private RewardedAd rewardedAd = null;
    private boolean isLoadingRewarded = false;

    private InterstitialAd interstitialAd = null;
    private boolean isLoadingInterstitial = false;

    private boolean isInitialized = false;

    public AdMobPlugin(Godot godot) {
        super(godot);
    }

    @NonNull
    @Override
    public String getPluginName() {
        return "AdMob";
    }

    @NonNull
    @Override
    public Set<SignalInfo> getPluginSignals() {
        Set<SignalInfo> signals = new HashSet<>();
        signals.add(new SignalInfo("rewarded_ad_loaded"));
        signals.add(new SignalInfo("rewarded_ad_failed_to_load", Integer.class));
        signals.add(new SignalInfo("rewarded_ad_opened"));
        signals.add(new SignalInfo("rewarded_ad_closed"));
        signals.add(new SignalInfo("rewarded_ad_user_earned_reward", String.class, Integer.class));

        signals.add(new SignalInfo("interstitial_loaded"));
        signals.add(new SignalInfo("interstitial_failed_to_load", Integer.class));
        signals.add(new SignalInfo("interstitial_closed"));
        return signals;
    }

    @UsedByGodot
    public void init() {
        Activity activity = getActivity();
        if (activity == null) {
            Log.e(TAG, "Cannot init MobileAds: Activity is null");
            return;
        }

        activity.runOnUiThread(() -> {
            if (isInitialized) return;
            Log.i(TAG, "Initializing Google Mobile Ads SDK...");
            MobileAds.initialize(activity, new OnInitializationCompleteListener() {
                @Override
                public void onInitializationComplete(@NonNull InitializationStatus initializationStatus) {
                    isInitialized = true;
                    Log.i(TAG, "Google Mobile Ads SDK successfully initialized!");
                }
            });
        });
    }

    @UsedByGodot
    public boolean is_internet_available() {
        Activity activity = getActivity();
        if (activity == null) return false;
        try {
            ConnectivityManager cm = (ConnectivityManager) activity.getSystemService(Context.CONNECTIVITY_SERVICE);
            if (cm == null) return false;
            NetworkCapabilities caps = cm.getNetworkCapabilities(cm.getActiveNetwork());
            if (caps == null) return false;
            return caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) &&
                   caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED);
        } catch (Exception e) {
            Log.w(TAG, "Failed to check network connectivity", e);
            return false;
        }
    }

    @UsedByGodot
    public boolean is_rewarded_ad_loaded() {
        return rewardedAd != null;
    }

    @UsedByGodot
    public void load_rewarded_ad(final String adUnitId) {
        Activity activity = getActivity();
        if (activity == null) return;

        activity.runOnUiThread(() -> {
            if (isLoadingRewarded) {
                Log.d(TAG, "Rewarded ad is already loading, skipping duplicate request.");
                return;
            }
            if (rewardedAd != null) {
                Log.d(TAG, "Rewarded ad is already loaded and ready.");
                runOnRenderThread(() -> emitSignal("rewarded_ad_loaded"));
                return;
            }

            isLoadingRewarded = true;
            Log.i(TAG, "Loading Rewarded Ad with Unit ID: " + adUnitId);
            AdRequest adRequest = new AdRequest.Builder().build();

            RewardedAd.load(activity, adUnitId, adRequest, new RewardedAdLoadCallback() {
                @Override
                public void onAdFailedToLoad(@NonNull LoadAdError loadAdError) {
                    isLoadingRewarded = false;
                    rewardedAd = null;
                    Log.w(TAG, "Rewarded ad failed to load: " + loadAdError.getMessage() + " (code: " + loadAdError.getCode() + ")");
                    runOnRenderThread(() -> emitSignal("rewarded_ad_failed_to_load", loadAdError.getCode()));
                }

                @Override
                public void onAdLoaded(@NonNull RewardedAd ad) {
                    isLoadingRewarded = false;
                    rewardedAd = ad;
                    Log.i(TAG, "Rewarded ad loaded successfully!");
                    runOnRenderThread(() -> emitSignal("rewarded_ad_loaded"));
                }
            });
        });
    }

    @UsedByGodot
    public void show_rewarded_ad() {
        Activity activity = getActivity();
        if (activity == null) {
            Log.e(TAG, "Cannot show rewarded ad: Activity is null");
            return;
        }

        activity.runOnUiThread(() -> {
            if (rewardedAd == null) {
                Log.w(TAG, "show_rewarded_ad called but rewardedAd is null!");
                runOnRenderThread(() -> emitSignal("rewarded_ad_failed_to_load", -1));
                return;
            }

            final RewardedAd currentAd = rewardedAd;
            currentAd.setFullScreenContentCallback(new FullScreenContentCallback() {
                @Override
                public void onAdShowedFullScreenContent() {
                    Log.i(TAG, "Rewarded ad displayed full screen.");
                    runOnRenderThread(() -> emitSignal("rewarded_ad_opened"));
                }

                @Override
                public void onAdDismissedFullScreenContent() {
                    Log.i(TAG, "Rewarded ad dismissed by user.");
                    rewardedAd = null;
                    runOnRenderThread(() -> emitSignal("rewarded_ad_closed"));
                }

                @Override
                public void onAdFailedToShowFullScreenContent(@NonNull AdError adError) {
                    Log.w(TAG, "Rewarded ad failed to show: " + adError.getMessage());
                    rewardedAd = null;
                    runOnRenderThread(() -> emitSignal("rewarded_ad_failed_to_load", adError.getCode()));
                }
            });

            currentAd.show(activity, new OnUserEarnedRewardListener() {
                @Override
                public void onUserEarnedReward(@NonNull RewardItem rewardItem) {
                    Log.i(TAG, "User earned reward: " + rewardItem.getAmount() + " " + rewardItem.getType());
                    runOnRenderThread(() -> emitSignal("rewarded_ad_user_earned_reward", rewardItem.getType(), rewardItem.getAmount()));
                }
            });
        });
    }

    @UsedByGodot
    public boolean is_interstitial_loaded() {
        return interstitialAd != null;
    }

    @UsedByGodot
    public void load_interstitial(final String adUnitId) {
        Activity activity = getActivity();
        if (activity == null) return;

        activity.runOnUiThread(() -> {
            if (isLoadingInterstitial || interstitialAd != null) return;

            isLoadingInterstitial = true;
            Log.i(TAG, "Loading Interstitial Ad: " + adUnitId);
            AdRequest adRequest = new AdRequest.Builder().build();

            InterstitialAd.load(activity, adUnitId, adRequest, new InterstitialAdLoadCallback() {
                @Override
                public void onAdLoaded(@NonNull InterstitialAd ad) {
                    isLoadingInterstitial = false;
                    interstitialAd = ad;
                    Log.i(TAG, "Interstitial ad loaded successfully.");
                    runOnRenderThread(() -> emitSignal("interstitial_loaded"));
                }

                @Override
                public void onAdFailedToLoad(@NonNull LoadAdError loadAdError) {
                    isLoadingInterstitial = false;
                    interstitialAd = null;
                    Log.w(TAG, "Interstitial ad failed to load: " + loadAdError.getMessage());
                    runOnRenderThread(() -> emitSignal("interstitial_failed_to_load", loadAdError.getCode()));
                }
            });
        });
    }

    @UsedByGodot
    public void show_interstitial() {
        Activity activity = getActivity();
        if (activity == null) return;

        activity.runOnUiThread(() -> {
            if (interstitialAd == null) {
                Log.w(TAG, "show_interstitial called but interstitialAd is null.");
                return;
            }

            final InterstitialAd currentAd = interstitialAd;
            currentAd.setFullScreenContentCallback(new FullScreenContentCallback() {
                @Override
                public void onAdDismissedFullScreenContent() {
                    interstitialAd = null;
                    runOnRenderThread(() -> emitSignal("interstitial_closed"));
                }

                @Override
                public void onAdFailedToShowFullScreenContent(@NonNull AdError adError) {
                    interstitialAd = null;
                    runOnRenderThread(() -> emitSignal("interstitial_closed"));
                }
            });

            currentAd.show(activity);
        });
    }
}
