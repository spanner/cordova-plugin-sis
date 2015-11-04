package org.spanner.plugin.sis;

import com.google.gson.Gson;

import org.apache.cordova.*;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.List;

import de.sissoftware.sisframework.sfl.mapping.OnSISMappingSFLListener;
import de.sissoftware.sisframework.sfl.mapping.SISMappingExponentialBackoffAction;
import de.sissoftware.sisframework.sfl.mapping.SISMappingSFLLibrary;
import de.sissoftware.sisframework.sfl.messaging.OnSISMessagingSFLMessagesListener;
import de.sissoftware.sisframework.sfl.messaging.SISMessagingSFLLibrary;

public class SIS extends CordovaPlugin {
    private CallbackContext messagingCallbackContext;
    private CallbackContext mappingCallbackContext;
    private SISMappingSFLLibrary mappingSFL;
    private SISMessagingSFLLibrary messagingSFL;
    private Gson gson = new Gson();

    @Override
    protected void pluginInitialize() {
        super.pluginInitialize();
        mappingSFL = SISMappingSFLLibrary.getInstance(cordova.getActivity());
        mappingSFL.registerOnSISMappingSFLListener(mOnSISMappingSFLListener);

        messagingSFL = SISMessagingSFLLibrary.getInstance(cordova.getActivity());
        messagingSFL.registerOnSISMessagingSFLMessagesListener(mOnSISMessagingSFLMessagesListener);

    }

    @Override
    public boolean execute(String action, JSONArray data, CallbackContext callbackContext) throws JSONException {
        if (action.equals("listenForMessages")) {
            messagingCallbackContext = callbackContext;
            onNewLocationBasedMessages();
            onNewBroadcastMessages();
            return true;
        } else if (action.equals("listenForMapItems")) {
            mappingCallbackContext = callbackContext;
            onNewMapData();
            return true;
        } else if (action.equals("markMessageAsRead")) {
            markMessageAsRead(data.get(0).toString());
            return true;
        } else if (action.equals("deleteMessage")) {
            deleteMessage(data.get(0).toString());
            return true;
        } else {
            return false;
        }
    }

    private void callBackAndKeepOpen(CallbackContext cbContext, PluginResult result) {
        result.setKeepCallback(true);
        cbContext.sendPluginResult(result);
    }

    // messaging ->

    private void markMessageAsRead(String id) {
        messagingSFL.markMessageAsRead(messagingSFL.getBroadcastMessage(id));
    }

    private void deleteMessage(String id) {
        messagingSFL.removeMessage(messagingSFL.getBroadcastMessage(id));
    }

    private void onNewLocationBasedMessages() {
        if (messagingCallbackContext != null) {
            PluginResult result = new PluginResult(PluginResult.Status.OK, getLocationBasedMessagesJson());
            callBackAndKeepOpen(messagingCallbackContext, result);
        }
    }

    private void onNewBroadcastMessages() {
        if (messagingCallbackContext != null) {
            PluginResult result = new PluginResult(PluginResult.Status.OK, getBroadcastMessagesJson());
            callBackAndKeepOpen(messagingCallbackContext, result);
        }
    }

    private JSONObject messagesJson(String jsonString) {
        JSONObject json = new JSONObject();
        try {
            json.put("messages",new JSONArray(jsonString));
        }
        catch (JSONException e) {}
        return json;
    }

    private JSONObject getLocationBasedMessagesJson() {
        return messagesJson(gson.toJson(messagingSFL.getAllUnreadLocationBasedMessages()));
    }

    private JSONObject getBroadcastMessagesJson() {
        return messagesJson(gson.toJson(messagingSFL.getAllUnreadBroadcastMessages()));
    }

    private OnSISMessagingSFLMessagesListener mOnSISMessagingSFLMessagesListener = new OnSISMessagingSFLMessagesListener() {

        @Override
        public void onSISLocationBasedMessagesAvailable() {
            onNewLocationBasedMessages();
        }

        @Override
        public void onSISBroadcastMessagesAvailable() {
            onNewBroadcastMessages();
        }

        @Override
        public void onSISMessageChannelsDeleted(List<String> channelIDs) {}
    };


    // mapping ->

    private void onNewMapData() {
        if (mappingCallbackContext != null) {
            PluginResult result = new PluginResult(PluginResult.Status.OK, getSISMapJson());
            callBackAndKeepOpen(mappingCallbackContext, result);
        }
    }

    private JSONObject getSISMapJson() {
        JSONObject json = new JSONObject();
        try {
            json.put("pois",new JSONArray(gson.toJson(mappingSFL.getPois())));
            json.put("routes",new JSONArray(gson.toJson(mappingSFL.getRoutes())));
            json.put("zones",new JSONArray(gson.toJson(mappingSFL.getZones())));
        }
        catch (JSONException e) {}
        return json;
    }

    private OnSISMappingSFLListener mOnSISMappingSFLListener = new OnSISMappingSFLListener() {
        @Override
        public void onSISNewMapData() { onNewMapData(); }

        @Override
        public void onSISNewDynamicPoiData() {}
        @Override
        public void onSISMapStatisticsUploadSuccess() {}
        @Override
        public void onSISMapStatisticsUploadFailed() {}
        @Override
        public void onSISMapStatisticsEnabled() {}
        @Override
        public void onSISMapStatisticsDisabled() {}
        @Override
        public void onSISMapInfoChanged(Double timeOfLastUpload, int sizeOfBufferQueue) {}
        @Override
        public void onSISMapExponentialBackoffAction(SISMappingExponentialBackoffAction action) {}
    };
}
