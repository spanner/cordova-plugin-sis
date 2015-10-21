package org.spanner.plugin.sis;

import android.app.Activity;

import org.apache.cordova.*;
import org.json.JSONArray;
import org.json.JSONException;

import java.util.List;

import de.sissoftware.sisframework.internal.log.SISLog;
import de.sissoftware.sisframework.sfl.mapping.OnSISMappingSFLListener;
import de.sissoftware.sisframework.sfl.mapping.SISMappingExponentialBackoffAction;
import de.sissoftware.sisframework.sfl.mapping.SISMappingSFLLibrary;
import de.sissoftware.sisframework.sfl.mapping.data.SISMapItem;
import de.sissoftware.sisframework.sfl.messaging.OnSISMessagingSFLMessagesListener;
import de.sissoftware.sisframework.sfl.messaging.SISMessagingSFLLibrary;
import de.sissoftware.sisframework.sfl.messaging.data.SISBroadcastMessage;
import de.sissoftware.sisframework.sfl.messaging.data.SISLocationBasedMessage;

public class SIS extends CordovaPlugin {
    private CallbackContext messagesCallbackContext;
    private CallbackContext mappingCallbackContext;


    @Override
    protected void pluginInitialize() {
        super.pluginInitialize();
        SISMappingSFLLibrary.getInstance(cordova.getActivity());
    }

    @Override
    public boolean execute(String action, JSONArray data, CallbackContext callbackContext) throws JSONException {
        if (action.equals("listenForMessages")) {
            messagesCallbackContext = callbackContext;
            SISMessagingSFLLibrary.getInstance(cordova.getActivity()).registerOnSISMessagingSFLMessagesListener(mOnSISMessagingSFLMessagesListener);
            return true;
        } else if (action.equals("listenForMapItems")) {
            mappingCallbackContext = callbackContext;
            SISMappingSFLLibrary.getInstance(cordova.getActivity()).registerOnSISMappingSFLListener(mOnSISMappingSFLListener);
            return true;
        } else if (action.equals("getAllMapItems")) {
            List<SISMapItem> map_items = SISMappingSFLLibrary.getInstance(cordova.getActivity()).getCompleteMapData();
            callbackContext.success("get map items");
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

    private void getLatestLocationBasedMessage() {
        List<SISLocationBasedMessage> messages = SISMessagingSFLLibrary.getInstance(cordova.getActivity()).getAllLocationBasedMessages();
        SISLocationBasedMessage message = messages.get(messages.size() - 1);
        SISLog.d("Mike: getLocationBasedMessages()", message.getTitle().getText("en")+": "+message.getText().getText("en"));

        PluginResult result = new PluginResult(PluginResult.Status.OK, message.getTitle().getText("en")+": "+message.getText().getText("en"));
        callBackAndKeepOpen(messagesCallbackContext, result);
    }

    private void getLatestBroadcastMessage() {
        List<SISBroadcastMessage> messages = SISMessagingSFLLibrary.getInstance(cordova.getActivity()).getAllBroadcastMessages();
        SISBroadcastMessage message = messages.get(messages.size() - 1);
        SISLog.d("Mike: getBroadcastMessages()", message.getTitle().getText("en") + ": " + message.getText().getText("en"));

        PluginResult result = new PluginResult(PluginResult.Status.OK, message.getTitle().getText("en")+": "+message.getText().getText("en"));
        callBackAndKeepOpen(messagesCallbackContext, result);
    }

    private OnSISMessagingSFLMessagesListener mOnSISMessagingSFLMessagesListener = new OnSISMessagingSFLMessagesListener() {

        @Override
        public void onSISLocationBasedMessagesAvailable() {
            getLatestLocationBasedMessage();
        }

        @Override
        public void onSISBroadcastMessagesAvailable() {
            getLatestBroadcastMessage();
        }

        @Override
        public void onSISMessageChannelsDeleted(List<String> channelIDs) {}
    };


    // mapping ->

    private void getSISMapData() {
        List<SISMapItem> map_items = SISMappingSFLLibrary.getInstance(cordova.getActivity()).getCompleteMapData();
        SISMapItem map_item = map_items.get(map_items.size() - 1);
        PluginResult result = new PluginResult(PluginResult.Status.OK, "getSISMapData"+map_item.getTitle());
        callBackAndKeepOpen(mappingCallbackContext, result);
    }

    private void getSISDynamicPoiData() {
        PluginResult result = new PluginResult(PluginResult.Status.OK, "getSISDynamicPoiData");
        callBackAndKeepOpen(mappingCallbackContext, result);
    }

    private OnSISMappingSFLListener mOnSISMappingSFLListener = new OnSISMappingSFLListener() {
        @Override
        public void onSISNewMapData() {
            SISLog.d("____________Mike", "new map data");
            getSISMapData();
        }

        @Override
        public void onSISNewDynamicPoiData() {
            getSISDynamicPoiData();
        }

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
