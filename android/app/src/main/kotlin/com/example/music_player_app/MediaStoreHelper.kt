package com.example.music_player_app

import android.app.Activity
import android.app.RecoverableSecurityException
import android.content.ContentUris
import android.content.Context
import android.content.Intent
import android.content.IntentSender
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

class MediaStoreHelper : FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var activity: Activity? = null
    private var pendingResult: Result? = null
    private val DELETE_REQUEST_CODE = 1001

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "music_scanner")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getAllSongs" -> result.success(getAllSongs())
            "deleteSong" -> {
                val path = call.argument<String>("path")
                if (path != null) {
                    deleteSong(path, result)
                } else {
                    result.error("INVALID_ARGUMENT", "Path cannot be null", null)
                }
            }
            "deleteSongs" -> {
                val paths = call.argument<List<String>>("paths")
                if (paths != null) {
                    deleteSongs(paths, result)
                } else {
                    result.error("INVALID_ARGUMENT", "Paths cannot be null", null)
                }
            }
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

    private fun deleteSongs(paths: List<String>, result: Result) {
        val uris = paths.mapNotNull { getUriFromPath(it) }

        if (uris.isEmpty()) {
            result.success(true) // Nothing to delete or files not found
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val intentSender = MediaStore.createDeleteRequest(context.contentResolver, uris).intentSender
            pendingResult = result
            try {
                activity?.startIntentSenderForResult(
                    intentSender,
                    DELETE_REQUEST_CODE,
                    null,
                    0,
                    0,
                    0
                )
            } catch (ex: IntentSender.SendIntentException) {
                pendingResult = null
                result.error("INTENT_ERROR", "Failed to launch delete confirmation", ex.message)
            }
        } else {
            // For Android 10 and below, we have to delete one by one or use the old method.
            // Since we want to support bulk delete, we'll try to delete all and report success if all deleted.
            // However, Android 10 might throw RecoverableSecurityException for each file.
            // This is a limitation on Android 10. For now, we'll iterate.
            // But to avoid multiple popups on Android 10, we can't really do much without complex logic.
            // Fortunately, most users are on Android 11+ where createDeleteRequest works.
            // We will fallback to single deletion logic for older versions if needed, but for now let's try loop.
            // Actually, for Android 10, we should probably just fail or warn.
            // But let's try to delete and if exception, we handle it.
            // A better approach for < R is to just call deleteSong for each, but that causes multiple popups.
            // Since the user specifically asked for "one popup", this is mainly for Android 11+.
            
            // Fallback for < Android 11:
            var allSuccess = true
            for (uri in uris) {
                 try {
                    context.contentResolver.delete(uri, null, null)
                } catch (e: Exception) {
                    allSuccess = false
                }
            }
            result.success(allSuccess)
        }
    }

    private fun deleteSong(path: String, result: Result) {
        val uri = getUriFromPath(path)
        if (uri == null) {
            result.error("NOT_FOUND", "File not found in MediaStore", null)
            return
        }

        try {
            val rowsDeleted = context.contentResolver.delete(uri, null, null)
            if (rowsDeleted > 0) {
                result.success(true)
            } else {
                result.success(false)
            }
        } catch (e: SecurityException) {
            val intentSender = when {
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.R -> {
                    MediaStore.createDeleteRequest(context.contentResolver, listOf(uri)).intentSender
                }
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q -> {
                    (e as? RecoverableSecurityException)?.userAction?.actionIntent?.intentSender
                }
                else -> null
            }

            if (intentSender != null) {
                pendingResult = result
                try {
                    activity?.startIntentSenderForResult(
                        intentSender,
                        DELETE_REQUEST_CODE,
                        null,
                        0,
                        0,
                        0
                    )
                } catch (ex: IntentSender.SendIntentException) {
                    pendingResult = null
                    result.error("INTENT_ERROR", "Failed to launch delete confirmation", ex.message)
                }
            } else {
                result.error("PERMISSION_DENIED", "Cannot delete file", e.message)
            }
        } catch (e: Exception) {
            result.error("DELETE_ERROR", "Error deleting file", e.message)
        }
    }

    private fun getUriFromPath(path: String): Uri? {
        val projection = arrayOf(MediaStore.Audio.Media._ID)
        val selection = "${MediaStore.Audio.Media.DATA} = ?"
        val selectionArgs = arrayOf(path)
        
        context.contentResolver.query(
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
            projection,
            selection,
            selectionArgs,
            null
        )?.use { cursor ->
            if (cursor.moveToFirst()) {
                val id = cursor.getLong(cursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID))
                return ContentUris.withAppendedId(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, id)
            }
        }
        return null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == DELETE_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK) {
                pendingResult?.success(true)
            } else {
                pendingResult?.success(false)
            }
            pendingResult = null
            return true
        }
        return false
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
