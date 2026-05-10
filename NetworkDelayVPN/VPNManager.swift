import Foundation
import NetworkExtension

class VPNManager: ObservableObject {
    @Published var isConnected = false
    @Published var errorMessage: String?
    
    private var manager: NETunnelProviderManager?
    
    init() {
        loadVPNConfiguration()
        observeVPNStatus()
    }
    
    private func loadVPNConfiguration() {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = "Ошибка загрузки: \(error.localizedDescription)"
                }
                return
            }
            
            DispatchQueue.main.async {
                self?.manager = managers?.first
                self?.updateConnectionStatus()
            }
        }
    }
    
    private func observeVPNStatus() {
        NotificationCenter.default.addObserver(
            forName: .NEVPNStatusDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateConnectionStatus()
        }
    }
    
    private func updateConnectionStatus() {
        guard let manager = manager else {
            isConnected = false
            return
        }
        
        switch manager.connection.status {
        case .connected:
            isConnected = true
            errorMessage = "VPN подключен"
        case .disconnected, .invalid:
            isConnected = false
        case .connecting:
            errorMessage = "Подключение..."
        case .disconnecting:
            errorMessage = "Отключение..."
        case .reasserting:
            errorMessage = "Переподключение..."
        @unknown default:
            isConnected = false
        }
    }
    
    func connect(delayMs: Int) {
        if manager == nil {
            createVPNConfiguration(delayMs: delayMs)
        } else {
            startVPN(delayMs: delayMs)
        }
    }
    
    private func createVPNConfiguration(delayMs: Int) {
        let manager = NETunnelProviderManager()
        manager.localizedDescription = "Network Delay VPN"
        
        let proto = NETunnelProviderProtocol()
        proto.providerBundleIdentifier = "com.example.NetworkDelayVPN.PacketTunnel"
        proto.serverAddress = "127.0.0.1"
        proto.providerConfiguration = ["delayMs": delayMs as NSObject]
        
        manager.protocolConfiguration = proto
        manager.isEnabled = true
        
        manager.saveToPreferences { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = "Ошибка: \(error.localizedDescription)"
                }
                return
            }
            
            manager.loadFromPreferences { error in
                if let error = error {
                    DispatchQueue.main.async {
                        self?.errorMessage = "Ошибка: \(error.localizedDescription)"
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    self?.manager = manager
                    self?.startVPN(delayMs: delayMs)
                }
            }
        }
    }
    
    private func startVPN(delayMs: Int) {
        guard let manager = manager else { return }
        
        do {
            let options: [String: NSObject] = ["delayMs": delayMs as NSObject]
            try manager.connection.startVPNTunnel(options: options)
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Ошибка запуска: \(error.localizedDescription)"
            }
        }
    }
    
    func disconnect() {
        manager?.connection.stopVPNTunnel()
    }
    
    func updateDelay(_ delayMs: Int) {
        guard let session = manager?.connection as? NETunnelProviderSession else { return }
        
        let message = ["delayMs": delayMs]
        guard let data = try? JSONSerialization.data(withJSONObject: message) else { return }
        
        do {
            try session.sendProviderMessage(data) { _ in }
        } catch {
            print("Ошибка обновления задержки: \(error)")
        }
    }
}
