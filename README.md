# Cordova SIS Plugin

This is an API relay that wraps around the interface provided by the SIS SDK to make it available in javascript.

## Status

Alpha! This is an early build that gives access only to the features we need first.
It's a test and proof of concept that is also about to go into production, so wish it luck.

## Installation

Clone the plugin

    $ git clone https://github.com/spanner/cordova-plugin-sis.git

Install the plugin

    $ cd cordova_app
    $ cordova plugin add ../cordova-plugin-sis
    

## Use

The plugin is really just a pipe. You pass through a success callback to one of its listening methods and every bit
of new content is piped through to that callback as it comes in.

For example, all we have done so far is to top up a backbone collection. Coffeescript:

    window.sis.listenForMessages @receiveMessages
    
    receiveMessages: (data) =>
      message_collection.add data

The `data` argument is an array of message objects with id, so the collection will dedupe for us.
It would also update if relevant, but not in this example because messages don't change once sent.


## Data structure

At the moment, data comes through in a somewhat simplified form more like the restful representation a web app
would be used to. I expect we will stop doing that and just pass it through, for greater fidelity.


## Initialization

Each callback pipe has to be set up by a javascript call:

    sis.listenForMessages(successCallback, errorCallback)

`successCallback(message data)` will be invoked every time a message comes in.
The `message data` argument will be an array of all unread messages.

    sis.listenForMapItems(successCallback, errorCallback)

`successCallback(map data)` is invoked every time a message comes in.
The `map data` argument is the same package as would returned by getCompleteMapData.


## SDK interface

Eventually we will represent every SIS SDK call but so far you can only do this:

    sis.markMessageAsRead(message_id)

Marks a single message as read and therefore removes it from the notified list.

    sis.deleteMessage(message_id)

Deletes a message record altogether.

    sis.getCompleteMapData()

Immediately returns a complete package of map data, as would be 
