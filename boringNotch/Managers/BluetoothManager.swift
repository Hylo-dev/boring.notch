//
//  BluetoothManager.swift
//  boringNotch
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 02/12/25.
//

import Foundation
import Combine
import CoreAudio
import IOBluetooth

struct ConnectedHeadphone: Equatable {
    let name        : String
    let batteryLevel: Int?
    let isApple     : Bool
    
    var icon: String {
        let nameLower = name.lowercased()
        
        if nameLower.contains("airpods max") { return "airpodsmax" }
        if nameLower.contains("pro")         { return "airpodspro" }
        if nameLower.contains("airpods")     { return "airpods" }
        
        return "headphones"
    }
    
}

class BluetoothManager: ObservableObject {
    static let shared = BluetoothManager()
    
    @Published var currentHeadphone: ConnectedHeadphone? = nil
    @Published var isHeadphoneConnected: Bool = false
    
    private var lastDeviceID: AudioObjectID = kAudioObjectUnknown
    
    private init() {
        // Avvia il monitoraggio all'avvio
        startMonitoringAudioHardware()
    }
    
    // MARK: - CoreAudio Monitoring
    
    private func startMonitoringAudioHardware() {
        // Ascolta il cambio del dispositivo di output predefinito
        var defaultDevAddr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &defaultDevAddr,
            nil
        ) { [weak self] _, _ in
            self?.checkCurrentOutputDevice()
        }
        
        // Controllo iniziale
        checkCurrentOutputDevice()
    }
    
    private func checkCurrentOutputDevice() {
        let currentDeviceID = systemOutputDeviceID()
        
        // Evitiamo refresh inutili se il device è lo stesso
        guard currentDeviceID != lastDeviceID else { return }
        lastDeviceID = currentDeviceID
        
        // 1. Controlliamo se è Bluetooth
        guard isBluetoothDevice(deviceID: currentDeviceID) else {
            DispatchQueue.main.async {
                self.currentHeadphone = nil
                self.isHeadphoneConnected = false
            }
            return
        }
        
        // 2. Otteniamo il nome dal CoreAudio
        let deviceName = getAudioDeviceName(deviceID: currentDeviceID) ?? "Bluetooth Audio"
        
        // 3. Cerchiamo info extra (Batteria) via IOBluetooth
        // Nota: CoreAudio ci dà l'audio, IOBluetooth ci dà la batteria. Dobbiamo abbinarli per nome/mac address.
        let battery = fetchBatteryLevel(deviceName: deviceName)
        
        let headphone = ConnectedHeadphone(
            name: deviceName,
            batteryLevel: battery,
            isApple: deviceName.lowercased().contains("airpods") || deviceName.lowercased().contains("beats")
        )
        
        // 4. Pubblichiamo il risultato
        Task { @MainActor in
            self.currentHeadphone = headphone
            self.isHeadphoneConnected = true
            
            print("New device connected")
            
            // Qui puoi triggerare la tua notifica personalizzata
            //BoringViewCoordinator.shared.showHeadphoneConnected(info: headphone)
        }
    }
    
    // MARK: - IOBluetooth Helpers (Battery)
    
    private func fetchBatteryLevel(deviceName: String) -> Int? {
        // Ottieni tutti i dispositivi accoppiati
        guard let devices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else { return nil }
        
        // Cerchiamo il device che è CONNESSO e ha un nome simile
        if let targetDevice = devices.first(where: { device in
            return device.isConnected() && (device.name == deviceName || deviceName.contains(device.name))
        }) {
            
            // Tenta di leggere la batteria standard
            // Nota: Per AirPods complessi (Case, Left, Right) servirebbe IOKit avanzato.
            // batteryPercentSingle da IOBluetooth è spesso sufficiente per cuffie generiche o media aggregata.
//            if targetDevice.batteryPercentSingle > 0 {
//                 return Int(targetDevice.batteryPercentSingle)
//            }
            
            return 0
            
            // Alcuni device Apple espongono la batteria in modo diverso,
            // ma batteryPercentSingle è il metodo pubblico più sicuro senza usare API Private.
        }
        
        return nil
    }
    
    // MARK: - CoreAudio Low Level Helpers
    
    private func systemOutputDeviceID() -> AudioObjectID {
        var deviceID = kAudioObjectUnknown
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &size, &deviceID)
        return deviceID
    }
    
    private func isBluetoothDevice(deviceID: AudioObjectID) -> Bool {
        var transportType: UInt32 = 0
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyTransportType,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var size = UInt32(MemoryLayout<UInt32>.size)
        
        guard AudioObjectHasProperty(deviceID, &addr) else { return false }
        AudioObjectGetPropertyData(deviceID, &addr, 0, nil, &size, &transportType)
        
        return transportType == kAudioDeviceTransportTypeBluetooth ||
               transportType == kAudioDeviceTransportTypeBluetoothLE
    }
    
    private func getAudioDeviceName(deviceID: AudioObjectID) -> String? {
        var name: CFString = "" as CFString
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var size = UInt32(MemoryLayout<CFString>.size)
        
        guard AudioObjectHasProperty(deviceID, &addr) else { return nil }
        AudioObjectGetPropertyData(deviceID, &addr, 0, nil, &size, &name)
        return name as String
    }
}
