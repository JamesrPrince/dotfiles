// Prints Wi-Fi state as "power rssi noise txrate ssid" ("on -52 -92 867 Home").
// Build: swiftc -O -o wifi wifi.swift
import CoreWLAN

guard let iface = CWWiFiClient.shared().interface() else { print("none 0 0 0"); exit(0) }
let power = iface.powerOn() ? "on" : "off"
print(power, iface.rssiValue(), iface.noiseMeasurement(), Int(iface.transmitRate()), iface.ssid() ?? "")
