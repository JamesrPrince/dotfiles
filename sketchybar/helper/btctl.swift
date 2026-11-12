// SketchyBarBluetooth.app: Bluetooth for the bar. macOS gives Bluetooth to apps with their own
// permission, so this is a tiny app (see build.sh) instead of blueutil run from SketchyBar.
// Uses IOBluetooth directly, no blueutil. Output is JSON on stdout.
//   (no arguments)   ask for the Bluetooth permission (the Allow prompt), then print the status
//   status           {"auth","power","devices":[{"address","name","connected"}]}
//   power on|off     switch Bluetooth, then print the status
//   connect <addr>   connect the paired device, then print the status
//   disconnect <addr>
// Without the permission, every command except the bare run only prints {"auth": "..."}.
import CoreBluetooth
import Foundation
import IOBluetooth

// Same call blueutil uses to switch the controller on and off
@_silgen_name("IOBluetoothPreferenceSetControllerPowerState")
func IOBluetoothPreferenceSetControllerPowerState(_ state: Int32)

func authName() -> String {
    switch CBCentralManager.authorization {
    case .allowedAlways: return "allowed"
    case .notDetermined: return "undetermined"
    case .denied: return "denied"
    case .restricted: return "restricted"
    @unknown default: return "unknown"
    }
}

func powerOn() -> Bool {
    return IOBluetoothHostController.default()?.powerState == kBluetoothHCIPowerStateON
}

func paired() -> [IOBluetoothDevice] {
    return (IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice]) ?? []
}

func find(_ address: String) -> IOBluetoothDevice? {
    let want = address.lowercased().replacingOccurrences(of: ":", with: "-")
    return paired().first { ($0.addressString ?? "").lowercased().replacingOccurrences(of: ":", with: "-") == want }
}

func json(_ object: Any) {
    if let data = try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]),
       let text = String(data: data, encoding: .utf8) { print(text) }
}

func status() {
    guard authName() == "allowed" else { json(["auth": authName()]); return }
    let power = powerOn()
    let devices: [[String: Any]] = power ? paired().map {
        ["address": ($0.addressString ?? "").lowercased().replacingOccurrences(of: ":", with: "-"),
         "name": $0.nameOrAddress ?? "Unknown", "connected": $0.isConnected()]
    } : []
    json(["auth": "allowed", "power": power, "devices": devices])
}

func waitUntil(_ seconds: Double, _ done: () -> Bool) {
    let end = Date().addingTimeInterval(seconds)
    while Date() < end && !done() { RunLoop.main.run(until: Date().addingTimeInterval(0.1)) }
}

let args = Array(CommandLine.arguments.dropFirst())

// The prompt appears when the permission is asked for, and only then
final class Asker: NSObject, CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {}
}

if args.isEmpty {
    let asker = Asker()
    let manager = CBCentralManager(delegate: asker, queue: nil)
    waitUntil(90) { CBCentralManager.authorization != .notDetermined }
    _ = manager
    status()
    exit(0)
}

guard authName() == "allowed" else { json(["auth": authName()]); exit(0) }

switch args[0] {
case "power":
    if args.count > 1 {
        IOBluetoothPreferenceSetControllerPowerState(args[1] == "on" ? 1 : 0)
        waitUntil(5) { powerOn() == (args[1] == "on") }
    }
case "connect":
    if args.count > 1, let device = find(args[1]), !device.isConnected() { _ = device.openConnection() }
case "disconnect":
    if args.count > 1, let device = find(args[1]), device.isConnected() { _ = device.closeConnection() }
default:
    break
}
status()
