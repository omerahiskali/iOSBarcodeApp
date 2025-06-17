import Foundation
import Network
import CoreData

// CoreData modelimizi import ediyoruz
@objc(DespatchNetworkManager)
class DespatchNetworkManager: NSObject {
    static let shared = DespatchNetworkManager()
    
    private var browser: NetServiceBrowser?
    private var services: [NetService] = []
    private var selectedService: NetService?
    private var connection: NWConnection?
    
    private override init() {
        super.init()
    }
    
    // MARK: - Bonjour Service Discovery
    func startBrowsing(completion: @escaping (Result<[NetService], Error>) -> Void) {
        browser = NetServiceBrowser()
        browser?.delegate = self
        browser?.searchForServices(ofType: "_irsaliye._tcp", inDomain: "local")
        
        // 5 saniye sonra timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            if self?.services.isEmpty ?? true {
                completion(.failure(NSError(domain: "DespatchNetworkManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Servis bulunamadı"])))
            }
        }
    }
    
    // MARK: - Data Sending
    func sendDespatch(_ despatch: Despatch, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let selectedService = selectedService else {
            completion(.failure(NSError(domain: "DespatchNetworkManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "Servis seçilmedi"])))
            return
        }
        
        // Despatch verisini JSON'a çevir
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do {
            // Despatch verisini dictionary'ye çevir
            var despatchDict: [String: Any] = [:]
            despatchDict["title"] = despatch.title
            despatchDict["invoiceNumber"] = despatch.invoiceNumber
            
            // Ürünleri ekle
            if let products = despatch.products?.allObjects as? [DespatchProduct] {
                var productsArray: [[String: Any]] = []
                
                for product in products {
                    var productDict: [String: Any] = [:]
                    productDict["name"] = product.name
                    
                    // Seri numaralarını ekle
                    if let serialNumbers = product.serialNumbers?.allObjects as? [SerialNumber] {
                        let serialNumberValues = serialNumbers.compactMap { $0.value }
                        productDict["serialNumbers"] = serialNumberValues
                    }
                    
                    productsArray.append(productDict)
                }
                
                despatchDict["products"] = productsArray
            }
            
            // Dictionary'yi JSON'a çevir
            let jsonData = try JSONSerialization.data(withJSONObject: despatchDict, options: .prettyPrinted)
            
            // Debug için JSON string'i yazdır
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("Gönderilecek JSON:")
                print(jsonString)
            }
            
            // TCP bağlantısı oluştur
            let endpoint = NWEndpoint.service(name: selectedService.name, type: "_irsaliye._tcp", domain: "local", interface: nil)
            connection = NWConnection(to: endpoint, using: .tcp)
            
            connection?.stateUpdateHandler = { [weak self] state in
                switch state {
                case .ready:
                    self?.sendData(jsonData, completion: completion)
                case .failed(let error):
                    completion(.failure(error))
                case .waiting(let error):
                    completion(.failure(error))
                default:
                    break
                }
            }
            
            connection?.start(queue: .main)
            
        } catch {
            print("JSON dönüşüm hatası: \(error)")
            completion(.failure(error))
        }
    }
    
    private func sendData(_ data: Data, completion: @escaping (Result<Void, Error>) -> Void) {
        connection?.send(content: data, completion: .contentProcessed { [weak self] error in
            if let error = error {
                print("Veri gönderme hatası: \(error)")
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
            self?.connection?.cancel()
        })
    }
}

// MARK: - NetServiceBrowserDelegate
extension DespatchNetworkManager: NetServiceBrowserDelegate {
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        services.append(service)
        service.delegate = self
        service.resolve(withTimeout: 5)
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        if let index = services.firstIndex(of: service) {
            services.remove(at: index)
        }
    }
}

// MARK: - NetServiceDelegate
extension DespatchNetworkManager: NetServiceDelegate {
    func netServiceDidResolveAddress(_ sender: NetService) {
        selectedService = sender
    }
    
    func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        print("Servis çözümlenemedi: \(errorDict)")
    }
} 