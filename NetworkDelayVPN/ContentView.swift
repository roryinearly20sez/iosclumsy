import SwiftUI
import NetworkExtension

struct ContentView: View {
    @StateObject private var vpnManager = VPNManager()
    @State private var delayMs: Double = 100
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Статус VPN
                VStack(spacing: 10) {
                    Image(systemName: vpnManager.isConnected ? "checkmark.shield.fill" : "shield.slash")
                        .font(.system(size: 60))
                        .foregroundColor(vpnManager.isConnected ? .green : .gray)
                    
                    Text(vpnManager.isConnected ? "VPN Подключен" : "VPN Отключен")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .padding(.top, 40)
                
                // Настройка задержки
                VStack(alignment: .leading, spacing: 15) {
                    Text("Задержка сети")
                        .font(.headline)
                    
                    HStack {
                        Text("\(Int(delayMs)) мс")
                            .font(.title3)
                            .fontWeight(.medium)
                            .frame(width: 80, alignment: .leading)
                        
                        Slider(value: $delayMs, in: 0...2000, step: 10)
                            .onChange(of: delayMs) { newValue in
                                if vpnManager.isConnected {
                                    vpnManager.updateDelay(Int(newValue))
                                }
                            }
                    }
                    
                    HStack(spacing: 10) {
                        ForEach([50, 100, 250, 500, 1000], id: \.self) { value in
                            Button("\(value)") {
                                delayMs = Double(value)
                                if vpnManager.isConnected {
                                    vpnManager.updateDelay(value)
                                }
                            }
                            .buttonStyle(.bordered)
                            .tint(Int(delayMs) == value ? .blue : .gray)
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Кнопка подключения
                Button(action: {
                    if vpnManager.isConnected {
                        vpnManager.disconnect()
                    } else {
                        vpnManager.connect(delayMs: Int(delayMs))
                    }
                }) {
                    Text(vpnManager.isConnected ? "Отключить VPN" : "Подключить VPN")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(vpnManager.isConnected ? Color.red : Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
                
                if let error = vpnManager.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .navigationTitle("Network Delay VPN")
        }
    }
}

#Preview {
    ContentView()
}
