package org.hyperledger.ariesframework.agent

import android.util.Log
import kotlinx.coroutines.DelicateCoroutinesApi
import kotlinx.coroutines.FlowPreview
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.filter
import kotlinx.coroutines.flow.filterIsInstance
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.timeout
import kotlinx.coroutines.launch
import kotlin.time.Duration.Companion.seconds

class EventBus {
    private val _events = MutableSharedFlow<Any>()
    val events = _events.asSharedFlow()

    suspend fun publish(event: Any) {
        Log.e("EventBus","--> publish\n\n")

        _events.emit(event)
    }

    @OptIn(DelicateCoroutinesApi::class)
    inline fun <reified T> subscribe(crossinline onEvent: suspend (T) -> Unit) {
        Log.e("EventBus","--> subscribe\n\n")

        GlobalScope.launch {
            events.filterIsInstance<T>()
                .collect { event ->
                    coroutineContext.ensureActive()
                    onEvent(event)
                }
        }
    }

    @OptIn(FlowPreview::class)
    suspend inline fun <reified T> waitFor(crossinline predicate: suspend (T) -> Boolean): Boolean {
        Log.e("EventBus","--> waitFor\n\n")

        return try {
            events.filterIsInstance<T>()
                .filter { predicate(it) }
                .timeout(20.seconds)
                .first()
            true
        } catch (e: Exception) {
            false
        }
    }
}
