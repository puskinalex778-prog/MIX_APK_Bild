package com.khranitoniks.guard

import android.app.Application
import com.khranitoniks.guard.service.Notifier

class KhApp : Application() {
    override fun onCreate() {
        super.onCreate()
        Notifier.createChannels(this)
    }
}
