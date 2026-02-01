package com.vuta.vuta

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.TextView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class VutaNativeAdFactory(private val context: Context) : GoogleMobileAdsPlugin.NativeAdFactory {
    override fun createNativeAd(nativeAd: NativeAd, customOptions: MutableMap<String, Any>?): NativeAdView {
        val inflater = LayoutInflater.from(context)
        val adView = inflater.inflate(R.layout.native_ad_vuta, null) as NativeAdView

        val headlineView = adView.findViewById<TextView>(R.id.ad_headline)
        val bodyView = adView.findViewById<TextView>(R.id.ad_body)
        val ctaView = adView.findViewById<Button>(R.id.ad_cta)

        headlineView.text = nativeAd.headline ?: ""
        bodyView.text = nativeAd.body ?: ""

        val cta = nativeAd.callToAction
        if (cta.isNullOrBlank()) {
            ctaView.visibility = View.GONE
        } else {
            ctaView.visibility = View.VISIBLE
            ctaView.text = cta
        }

        adView.headlineView = headlineView
        adView.bodyView = bodyView
        adView.callToActionView = ctaView

        adView.setNativeAd(nativeAd)
        return adView
    }
}
