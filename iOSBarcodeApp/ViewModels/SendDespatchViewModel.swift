import Foundation
import CoreData
import CocoaAsyncSocket

// MARK: - Despatch Extension
extension Despatch: Encodable {
    enum CodingKeys: String, CodingKey {
        case title
        case invoiceNumber
        case products
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(invoiceNumber, forKey: .invoiceNumber)
        
        if let products = products?.allObjects as? [DespatchProduct] {
            try container.encode(products, forKey: .products)
        }
    }
}

// MARK: - DespatchProduct Extension
extension DespatchProduct: Encodable {
    enum CodingKeys: String, CodingKey {
        case name
        case serialNumbers
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        
        if let serialNumbers = serialNumbers?.allObjects as? [SerialNumber] {
            let serialNumberValues = serialNumbers.compactMap { $0.value }
            try container.encode(serialNumberValues, forKey: .serialNumbers)
        }
    }
}

class SendDespatchViewModel: NSObject {
    // MARK: - Properties
    private var despatch: Despatch?
    private var isSending = false
    private var socket: GCDAsyncSocket?
    
    // MARK: - Callbacks
    var onSendingStateChanged: ((Bool) -> Void)?
    var onError: ((String) -> Void)?
    var onSuccess: (() -> Void)?
    
    // MARK: - Initialization
    init(despatch: Despatch?) {
        self.despatch = despatch
        super.init()
        setupSocket()
    }
    
    // MARK: - Private Methods
    private func setupSocket() {
        socket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)
    }
    
    // MARK: - Public Methods
    func getDespatchInfo() -> (title: String?, invoiceNumber: String?) {
        return (despatch?.title, despatch?.invoiceNumber)
    }
    
    func getProducts() -> [(name: String, serialNumbers: [String])] {
        guard let products = despatch?.products?.allObjects as? [DespatchProduct] else {
            return []
        }
        
        return products.compactMap { product in
            guard let name = product.name else { return nil }
            let serialNumbers = (product.serialNumbers?.allObjects as? [SerialNumber])?.compactMap { $0.value } ?? []
            return (name: name, serialNumbers: serialNumbers)
        }
    }
    
    func sendDespatch(to ip: String, port: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let despatch = despatch, !isSending else { return }
        
        isSending = true
        onSendingStateChanged?(true)
        
        do {
            try socket?.connect(toHost: ip, onPort: UInt16(port))
            
            // JSON verisini hazırla
            let jsonData = try JSONEncoder().encode(despatch)
            
            // Veriyi gönder
            socket?.write(jsonData, withTimeout: 10, tag: 0)
            
        } catch {
            DispatchQueue.main.async {
                self.isSending = false
                self.onSendingStateChanged?(false)
                completion(.failure(error))
            }
        }
    }
}

// MARK: - GCDAsyncSocketDelegate
extension SendDespatchViewModel: GCDAsyncSocketDelegate {
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        print("Bağlantı başarılı: \(host):\(port)")
    }
    
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        if let error = err {
            print("Bağlantı hatası: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.isSending = false
                self.onSendingStateChanged?(false)
                self.onError?(error.localizedDescription)
            }
        } else {
            print("Bağlantı kapandı")
        }
    }
    
    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        print("Veri gönderildi")
        DispatchQueue.main.async {
            self.isSending = false
            self.onSendingStateChanged?(false)
            self.onSuccess?()
        }
    }
} 