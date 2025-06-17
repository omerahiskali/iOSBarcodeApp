import Foundation

class AddDespatchLineViewModel {
    // MARK: - Properties
    private var model: DespatchLineModel
    var editingProductIndex: Int?
    private var newlyScannedCount: Int = 0 // Yeni taranan seri numarası sayısı
    
    // MARK: - Callbacks
    var onProductNameUpdated: ((String) -> Void)?
    var onSerialNumbersUpdated: (([String]) -> Void)?
    var onSaveCompleted: ((Bool) -> Void)?
    var onProductSaved: ((String, [String], Int?) -> Void)?
    var onNewlyScannedCountUpdated: ((Int) -> Void)? // Yeni callback
    
    // MARK: - Initialization
    init() {
        self.model = DespatchLineModel()
    }
    
    // MARK: - Methods
    func updateProductName(_ name: String) {
        model.updateProductName(name)
        onProductNameUpdated?(name)
    }
    
    func addSerialNumber(_ serialNumber: String) -> Bool {
        let success = model.addSerialNumber(serialNumber)
        if success {
            newlyScannedCount += 1
            onSerialNumbersUpdated?(model.getAllSerialNumbers())
            onNewlyScannedCountUpdated?(newlyScannedCount)
        }
        return success
    }
    
    func addSerialNumbers(_ newSerialNumbers: [String]) {
        model.addSerialNumbers(newSerialNumbers)
        newlyScannedCount += newSerialNumbers.count
        onSerialNumbersUpdated?(model.getAllSerialNumbers())
        onNewlyScannedCountUpdated?(newlyScannedCount)
    }
    
    func removeSerialNumber(at index: Int) {
        model.removeSerialNumber(at: index)
        onSerialNumbersUpdated?(model.getAllSerialNumbers())
    }
    
    func getSerialNumberCount() -> Int {
        return model.getSerialNumberCount()
    }
    
    func getSerialNumber(at index: Int) -> String? {
        return model.getSerialNumber(at: index)
    }
    
    func isSerialNumberExists(_ serialNumber: String) -> Bool {
        return model.isSerialNumberExists(serialNumber)
    }
    
    func saveProduct() {
        // Burada veritabanına kaydetme işlemi yapılmayacak
        // Sadece başarılı olduğunu varsayalım
        onSaveCompleted?(true)
    }
    
    func loadProductData(productName: String, serialNumbers: [String]) {
        model.updateProductName(productName)
        model.addSerialNumbers(serialNumbers)
        newlyScannedCount = 0 // Düzenleme modunda yeni tarama sayısını sıfırla
        onProductNameUpdated?(productName)
        onSerialNumbersUpdated?(serialNumbers)
        onNewlyScannedCountUpdated?(0)
    }
    
    // MARK: - Getters
    var productName: String {
        return model.productName
    }
    
    var serialNumbers: [String] {
        return model.getAllSerialNumbers()
    }
    
    var newlyScannedSerialNumberCount: Int {
        return newlyScannedCount
    }
} 