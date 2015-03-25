# cordova-allobonjour

## About

> AlloBonjour provides Network Service Discovery (NSD) for your app. It will allow you
to identify other devices on the local network that support the requested service.

## Supported platforms

- iOS

## Installation

  cordova plugin add cordova-plugin-allobonjour

## Deinstall

  cordova plugin remove cordova-plugin-allobonjour

## Methods

This plugin defines a global `AlloBonjour` object.

### startDiscovery(serviceType, domain)

`AlloBonjour.startDiscovery` will initiate discovery and return a list of discovered
services.

Don’t forget to stop discovery with `AlloBonjour.stopDiscovery`, using a timeout for example.

    AlloBonjour.startDiscovery("_http._tcp.", "local.",
      function(services) {
        var i, service;

        for (i; i < services.length; i++) {
          service = services[i];
          console.log("Found: " + service.name + " " + service.type + " " + service.domain);
        }
      },
      function(err) {
        // Discovery could not be initiated
      }
    );

    window.setTimeout(
      AlloBonjour.stopDiscovery, 5000);

### stopDiscovery()

`AlloBonjour.stopDiscovery` can be called to stop an ongoing discovery.

    AlloBonjour.stopDiscovery();


### resolve(serviceName, serviceType, domain)

Return a list of addresses of a service, provided you know its name, type and domain.
Each address will provide IP and port number of the service.

    AlloBonjour.resolve("Printer", "_ipp._tcp", ".local",
      function(service) {
        var i, address;

        for (i; i < service.addresses; i++) {
          address = addresses[i];
          console.log("Address " + i + " " + address.ip + " " + address.port);
        }
      },
      function(err) {
        // Unsuccessful resolve
      }
    );

