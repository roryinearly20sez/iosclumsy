import NetworkExtension

class PacketTunnelProvider: NEPacketTunnelProvider {
    private var delayMs: Int = 100
    private var pendingPackets: [(Data, NEPacketTunnelFlow.Direction)] = []
    
    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        if let delayValue = options?["delayMs"] as? Int {
            delayMs = delayValue
        }
        
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")
        
        let ipv4Settings = NEIPv4Settings(addresses: ["192.168.1.2"], subnetMasks: ["255.255.255.0"])
        ipv4Settings.includedRoutes = [NEIPv4Route.default()]
        settings.ipv4Settings = ipv4Settings
        
        let dnsSettings = NEDNSSettings(servers: ["8.8.8.8", "8.8.4.4"])
        settings.dnsSettings = dnsSettings
        
        setTunnelNetworkSettings(settings) { error in
            if let error = error {
                completionHandler(error)
                return
            }
            
            self.startPacketForwarding()
            completionHandler(nil)
        }
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        if let message = try? JSONSerialization.jsonObject(with: messageData) as? [String: Any],
           let newDelay = message["delayMs"] as? Int {
            delayMs = newDelay
        }
        completionHandler?(nil)
    }
    
    private func startPacketForwarding() {
        packetFlow.readPackets { [weak self] packets, protocols in
            guard let self = self else { return }
            
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(self.delayMs)) {
                self.packetFlow.writePackets(packets, withProtocols: protocols)
            }
            
            self.startPacketForwarding()
        }
    }
}
