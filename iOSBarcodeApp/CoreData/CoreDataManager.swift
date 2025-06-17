import CoreData
import Foundation

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private init() {}
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "iOSBarcodeApp")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("CoreData store failed to load with error: \(error)")
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    // MARK: - Save Context
    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }
    
    // MARK: - Despatch Operations
    func createDespatch(title: String, invoiceNumber: String?) -> Despatch {
        let despatch = Despatch(context: context)
        despatch.title = title
        despatch.invoiceNumber = invoiceNumber
        saveContext()
        return despatch
    }
    
    func fetchDespatches() -> [Despatch] {
        let request: NSFetchRequest<Despatch> = Despatch.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching despatchs: \(error)")
            return []
        }
    }
    
    func deleteDespatch(_ despatch: Despatch) {
        context.delete(despatch)
        saveContext()
    }
    
    // MARK: - Product Operations
    func addProduct(name: String, to despatch: Despatch) -> DespatchProduct {
        let product = DespatchProduct(context: context)
        product.name = name
        product.despatch = despatch
        saveContext()
        return product
    }
    
    func fetchProducts(for despatch: Despatch) -> [DespatchProduct] {
        guard let products = despatch.products?.allObjects as? [DespatchProduct] else {
            return []
        }
        return products.sorted { $0.name ?? "" < $1.name ?? "" }
    }
    
    func deleteProduct(_ product: DespatchProduct) {
        context.delete(product)
        saveContext()
    }
    
    // MARK: - Serial Number Operations
    func addSerialNumber(value: String, to product: DespatchProduct) -> SerialNumber {
        let serialNumber = SerialNumber(context: context)
        serialNumber.value = value
        serialNumber.product = product
        saveContext()
        return serialNumber
    }
    
    func fetchSerialNumbers(for product: DespatchProduct) -> [SerialNumber] {
        guard let serialNumbers = product.serialNumbers?.allObjects as? [SerialNumber] else {
            return []
        }
        return serialNumbers.sorted { $0.value ?? "" < $1.value ?? "" }
    }
    
    func deleteSerialNumber(_ serialNumber: SerialNumber) {
        context.delete(serialNumber)
        saveContext()
    }
} 