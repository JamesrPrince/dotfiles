// SketchyBarWiFi.app: the Wi-Fi name and a scan of nearby networks, for the Wi-Fi popup.
// It is an app bundle so macOS gives it its own Location permission (the network name
// is hidden without it). Output, tab separated, one record per line:
//   AUTH <granted|undetermined|denied|restricted>
//   CUR  <power> <rssi> <noise> <rate> <ssid>
//   CH   <channel> <band> <width MHz>      (the connected network; no Location access needed)
//   SUP  <channel,channel,...>             (channels this Mac can use in the connected band)
//   NET  <rssi> <lock 0|1> <ssid>          (granted only; strongest first, one per name)
//   AP   <rssi> <band> <channel> <width> <ssid>   (granted only; every access point seen, hidden ones too)
// band is 1 (2.4 GHz), 2 (5 GHz) or 3 (6 GHz).
// Run with no arguments to answer the Location prompt once ("open SketchyBarWiFi.app");
// "--scan" (what the bar uses) never prompts and exits at once if not yet allowed.
// Build: see build.sh
import AppKit
import CoreLocation
import CoreWLAN

func authName(_ s: CLAuthorizationStatus) -> String {
  switch s {
  case .authorizedAlways, .authorized: return "granted"
  case .denied: return "denied"
  case .restricted: return "restricted"
  default: return "undetermined"
  }
}

final class Asker: NSObject, CLLocationManagerDelegate {
  let manager = CLLocationManager()
  var onDone: (() -> Void)?
  func start(prompt: Bool, done: @escaping () -> Void) {
    onDone = done
    manager.delegate = self
    if manager.authorizationStatus == .notDetermined && prompt {
      manager.requestAlwaysAuthorization()   // answered in locationManagerDidChangeAuthorization
    } else {
      done()
    }
  }
  func locationManagerDidChangeAuthorization(_ m: CLLocationManager) {
    if m.authorizationStatus != .notDetermined { onDone?(); onDone = nil }
  }
}

func bandCode(_ b: CWChannelBand) -> Int {
  switch b { case .band2GHz: return 1; case .band5GHz: return 2; case .band6GHz: return 3; default: return 0 }
}
func widthMHz(_ w: CWChannelWidth) -> Int {
  switch w { case .width20MHz: return 20; case .width40MHz: return 40; case .width80MHz: return 80; case .width160MHz: return 160; default: return 0 }
}

func report(_ auth: CLAuthorizationStatus) {
  print("AUTH\t\(authName(auth))")
  guard let iface = CWWiFiClient.shared().interface() else { print("CUR\tnone\t0\t0\t0\t"); return }
  let granted = authName(auth) == "granted"
  let ssid = granted ? (iface.ssid() ?? "") : ""
  print("CUR\t\(iface.powerOn() ? "on" : "off")\t\(iface.rssiValue())\t\(iface.noiseMeasurement())\t\(Int(iface.transmitRate()))\t\(ssid)")
  if let ch = iface.wlanChannel() {
    print("CH\t\(ch.channelNumber)\t\(bandCode(ch.channelBand))\t\(widthMHz(ch.channelWidth))")
    let supNums = (iface.supportedWLANChannels() ?? []).filter { $0.channelBand == ch.channelBand }
      .map { $0.channelNumber }
    let sup = Array(Set(supNums)).sorted().map(String.init).joined(separator: ",")
    if !sup.isEmpty { print("SUP\t\(sup)") }
  }
  guard granted, iface.powerOn() else { return }
  guard let found = try? iface.scanForNetworks(withName: nil) else { return }
  var best: [String: (Int, Bool)] = [:]
  for n in found {
    if let ch = n.wlanChannel {
      print("AP\t\(n.rssiValue)\t\(bandCode(ch.channelBand))\t\(ch.channelNumber)\t\(widthMHz(ch.channelWidth))\t\(n.ssid ?? "")")
    }
    guard let name = n.ssid, !name.isEmpty else { continue }
    let lock = !n.supportsSecurity(.none)
    if let old = best[name], old.0 >= n.rssiValue { continue }
    best[name] = (n.rssiValue, lock)
  }
  for (name, v) in best.sorted(by: { $0.value.0 > $1.value.0 }) {
    print("NET\t\(v.0)\t\(v.1 ? 1 : 0)\t\(name)")
  }
}

setvbuf(stdout, nil, _IOLBF, 0)
let prompt = !CommandLine.arguments.contains("--scan")
let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let asker = Asker()
asker.start(prompt: prompt) {
  report(asker.manager.authorizationStatus)
  exit(0)
}
if prompt { app.activate(ignoringOtherApps: true) }
// Give up on a prompt nobody answers.
DispatchQueue.main.asyncAfter(deadline: .now() + 90) { report(asker.manager.authorizationStatus); exit(0) }
RunLoop.main.run()
