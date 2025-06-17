import Foundation
import CoreData

// MARK: - Despatch Model
@objc(DespatchModel)
public class DespatchModel: NSManagedObject, Encodable {
    @NSManaged public var title: String?
    @NSManaged public var invoiceNumber: String?
    @NSManaged public var products: NSSet?
    
    // MARK: - Encodable
    enum CodingKeys: String, CodingKey {
        case title
        case invoiceNumber
        case products
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(invoiceNumber, forKey: .invoiceNumber)
        
        if let products = products?.allObjects as? [DespatchProductModel] {
            try container.encode(products, forKey: .products)
        }
    }
}

// MARK: - DespatchProduct Model
@objc(DespatchProductModel)
public class DespatchProductModel: NSManagedObject, Encodable {
    @NSManaged public var name: String?
    @NSManaged public var serialNumbers: NSSet?
    
    enum CodingKeys: String, CodingKey {
        case name
        case serialNumbers
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        
        if let serialNumbers = serialNumbers?.allObjects as? [SerialNumberModel] {
            let serialNumberValues = serialNumbers.compactMap { $0.value }
            try container.encode(serialNumberValues, forKey: .serialNumbers)
        }
    }
}

// MARK: - SerialNumber Model
@objc(SerialNumberModel)
public class SerialNumberModel: NSManagedObject {
    @NSManaged public var value: String?
} 