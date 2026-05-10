import NetworkExtension

class PacketTunnelProvider: NEPacketTunnelProvider {
    private var delayMs: Int = 100
    
    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        // Получаем задержку из опций
        if let delayValue = options?["delayMs"] as? Int {
            delayMs = delayValue
        }
        
        // Настройка сетевых параметров
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")
        
        // IPv4 настройки
        let ipv4Settings = NEIPv4Settings(addresses: ["192.168.1.2"], subnetMasks: ["255.255.255.0"])
        ipv4Settings.includedRoutes = [NEIPv4Route.default()]
        settings.ipv4Settings = ipv4Settings
        
        // DNS настройки
        let dnsSettings = NEDNSSettings(servers: ["8.8.8.8", "8.8.4.4"])
        settings.dnsSettings = dnsSettings
        
        // Применяем настройки
        setTunnelNetworkSettings(settings) { error in
            if let error = error {
                completionHandler(error)
                return
            }
            
            // Запускаем обработку пакетов
            self.startPacketForwarding()
            completionHandler(nil)
        }
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        // Обновление задержки от приложения
        if let message = try? JSONSerialization.jsonObject(with: messageData) as? [String: Any],
           let newDelay = message["delayMs"] as? Int {
            delayMs = newDelay
        }
        completionHandler?(nil)
    }
    
    private func startPacketForwarding() {
        // Читаем пакеты из виртуального интерфейса
        packetFlow.readPackets { [weak self] packets, protocols in
            guard let self = self else { return }
            
            // Добавляем задержку перед отправкой пакетов
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(self.delayMs)) {
                // Отправляем пакеты обратно с задержкой
                self.packetFlow.writePackets(packets, withProtocols: protocols)
            }
            
            // Продолжаем читать пакеты
            self.startPacketForwarding()
        }
    }
}
