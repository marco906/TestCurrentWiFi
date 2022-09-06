//
//  TestCurrentWiFiApp.swift
//  TestCurrentWiFi
//
//  Created by Marco Wenzel on 06/09/2022.
//

import SwiftUI
import NetworkExtension
import SystemConfiguration.CaptiveNetwork

@main
struct TestCurrentWiFiApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State var statusText = "You must allow location access to get WiFi info"
    
    var body: some View {
        VStack {
            Text(statusText)
            Button("Get current network") {
                getCurrentNetwork()
            }
            .buttonStyle(.bordered)
            .padding()
        }
        .task {
            // ask for location permission
            LocationManager.shared.startLocationManager()
        }
        // respond to location permission status changes
        .onReceive(NotificationCenter.default.publisher(for: .LocationAccessStatusChanged)) { notification in
            if let granted = notification.object as? Bool {
                self.changeStatusText(accesGranted: granted)
            }
        }
    }
    
    func getCurrentNetwork() {
        
        // You must have the following to get the current wifi
        // - com.apple.developer.networking.wifi-info entitlement is requrired from iOS 12
        // - granted permission to user location
        
        if #available(iOS 14.0, *) {
            // MARK: new API NEHotspotnetwork
            NEHotspotNetwork.fetchCurrent { network in
                guard let network = network else {
                    return
                }
                let description = "SSID \(network.ssid) BSSID \(network.bssid)"
                print(description)
                
                DispatchQueue.main.async {
                    self.statusText = description
                }
            }
        
        } else {
            // MARK: old API CNCopyCurrentNetworkInfo for iOS 11 to 13
            guard let interfaceNames = CNCopySupportedInterfaces() as? [String] else {
                return
            }
            
            for interfaceName in interfaceNames {
                guard let info = CNCopyCurrentNetworkInfo(interfaceName as CFString) as? [String: AnyObject] else {
                    continue
                }
                
                guard let ssid = info[kCNNetworkInfoKeySSID as String] as? String else {
                    continue
                }
                let description = "SSID \(ssid)"
                print(description)
                
                self.statusText = description
                break
            }
        }
    }
    
    func changeStatusText(accesGranted: Bool) {
        statusText = accesGranted ? "✅ Location Access granted, network info available"
                                    : "❌ Location Access denied. Go to device settings and enable location for this app to get network info"
    }
}
