import Foundation

struct DespatchLineModel {
    // MARK: - Properties
    private(set) var productName: String
    private(set) var serialNumbers: [String]
    
    // MARK: - Initialization
    init(productName: String = "", serialNumbers: [String] = []) {
        self.productName = productName
        self.serialNumbers = serialNumbers
    }
    
    // MARK: - Methods
    mutating func updateProductName(_ name: String) {
        productName = name
    }
    
    mutating func addSerialNumber(_ serialNumber: String) -> Bool {
        if serialNumbers.contains(serialNumber) {
            return false
        }
        serialNumbers.append(serialNumber)
        return true
    }
    
    mutating func addSerialNumbers(_ newSerialNumbers: [String]) {
        let uniqueSerialNumbers = newSerialNumbers.filter { !serialNumbers.contains($0) }
        serialNumbers.append(contentsOf: uniqueSerialNumbers)
    }
    
    mutating func removeSerialNumber(at index: Int) {
        guard index < serialNumbers.count else { return }
        serialNumbers.remove(at: index)
    }
    
    func getSerialNumberCount() -> Int {
        return serialNumbers.count
    }
    
    func getSerialNumber(at index: Int) -> String? {
        guard index < serialNumbers.count else { return nil }
        return serialNumbers[index]
    }
    
    func isSerialNumberExists(_ serialNumber: String) -> Bool {
        return serialNumbers.contains(serialNumber)
    }
    
    func getAllSerialNumbers() -> [String] {
        return serialNumbers
    }
} 