package com.example.music_player_app

import android.content.ContentUris
import android.content.Context
import android.net.Uri
import android.provider.MediaStore
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class MediaStoreHelper : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "music_scanner")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getAllSongs" -> result.success(getAllSongs())
            else -> result.notImplemented()
        }
    }

    private fun getAllSongs(): List<Map<String, Any?>> {
        val songs = mutableListOf<Map<String, Any?>>()
        val uri: Uri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.DATA,
            MediaStore.Audio.Media.DATE_MODIFIED
        )

        val sortOrder = "${MediaStore.Audio.Media.DATE_MODIFIED} DESC"

        context.contentResolver.query(uri, projection, null, null, sortOrder)?.use { cursor ->
            val idCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
            val titleCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
            val artistCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
            val durationCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)
            val dataCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)
            val modifiedCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DATE_MODIFIED)

            while (cursor.moveToNext()) {
                val id = cursor.getLong(idCol)
                val artUri = ContentUris.withAppendedId(
                    Uri.parse("content://media/external/audio/albumart"), id
                ).toString()

                songs.add(
                    mapOf(
                        "id" to id,
                        "title" to cursor.getString(titleCol),
                        "artist" to cursor.getString(artistCol),
                        "duration" to cursor.getLong(durationCol),
                        "path" to cursor.getString(dataCol),
                        "albumArt" to artUri,
                        "dateModified" to cursor.getLong(modifiedCol)
                    )
                )
            }
        }
        return songs
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
