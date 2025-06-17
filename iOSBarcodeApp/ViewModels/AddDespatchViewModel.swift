import Foundation
import CoreData

struct Product {
    let name: String
    var serialNumbers: [String]
}

class AddDespatchViewModel {
    // MARK: - Properties
    let coreDataManager = CoreDataManager.shared
    private(set) var products: [Product] = []
    private(set) var title: String = ""
    private(set) var invoiceNumber: String = ""
    var editingDespatch: Despatch?
    
    // MARK: - Methods
    func updateTitle(_ newTitle: String) {
        title = newTitle
    }
    
    func updateInvoiceNumber(_ newNumber: String) {
        invoiceNumber = newNumber
    }
    
    func addProduct(name: String, serialNumbers: [String]) {
        let product = Product(name: name, serialNumbers: serialNumbers)
        products.append(product)
    }
    
    func removeProduct(at index: Int) {
        guard index < products.count else { return }
        products.remove(at: index)
    }
    
    func saveProduct(name: String, serialNumbers: [String], at index: Int?) {
        if let index = index, index < products.count {
            // Mevcut ürünü güncelle
            products[index] = Product(name: name, serialNumbers: serialNumbers)
        } else {
            // Yeni ürün ekle
            let product = Product(name: name, serialNumbers: serialNumbers)
            products.append(product)
        }
    }
    
    func getProductCount() -> Int {
        return products.count
    }
    
    func getProduct(at index: Int) -> Product? {
        guard index < products.count else { return nil }
        return products[index]
    }
    
    func loadDespatchForEditing(_ despatch: Despatch) {
        editingDespatch = despatch
        title = despatch.title ?? ""
        invoiceNumber = despatch.invoiceNumber ?? ""
        
        // Ürünleri yükle
        products = []
        let products = coreDataManager.fetchProducts(for: despatch)
        for product in products {
            let serialNumbers = coreDataManager.fetchSerialNumbers(for: product)
            let serialNumberValues = serialNumbers.compactMap { $0.value }
            self.products.append(Product(name: product.name ?? "", serialNumbers: serialNumberValues))
        }
    }
    
    func saveDespatch() -> Bool {
        do {
            if let editingDespatch = editingDespatch {
                // Mevcut sevkiyatı güncelle
                editingDespatch.title = title
                editingDespatch.invoiceNumber = invoiceNumber
                
                // Mevcut ürünleri sil
                if let existingProducts = editingDespatch.products?.allObjects as? [DespatchProduct] {
                    for product in existingProducts {
                        coreDataManager.deleteProduct(product)
                    }
                }
            } else {
                // Yeni sevkiyat oluştur
                let despatch = coreDataManager.createDespatch(title: title, invoiceNumber: invoiceNumber)
                editingDespatch = despatch
            }
            
            // Yeni ürünleri ekle
            for product in products {
                if let despatch = editingDespatch {
                    let newProduct = coreDataManager.addProduct(name: product.name, to: despatch)
                    for serialNumber in product.serialNumbers {
                        _ = coreDataManager.addSerialNumber(value: serialNumber, to: newProduct)
                    }
                }
            }
            
            return true
        } catch {
            print("Error saving despatch: \(error)")
            return false
        }
    }
} 