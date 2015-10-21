/*global cordova, module*/

module.exports = {
    listenForMessages: function (successCallback, errorCallback) {
      cordova.exec(successCallback, errorCallback, "SIS", "listenForMessages", []);
    },
    markMessageAsRead: function (id, successCallback, errorCallback) {
      cordova.exec(successCallback, errorCallback, "SIS", "markMessageAsRead", [id]);
    },
    deleteMessage: function (id, successCallback, errorCallback) {
      cordova.exec(successCallback, errorCallback, "SIS", "deleteMessage", [id]);
    },
    listenForMapItems: function (successCallback, errorCallback) {
      cordova.exec(successCallback, errorCallback, "SIS", "listenForMapItems", []);
    },
    getCompleteMapData: function (successCallback, errorCallback) {
      cordova.exec(successCallback, errorCallback, "SIS", "getCompleteMapData", []);
    }
};
