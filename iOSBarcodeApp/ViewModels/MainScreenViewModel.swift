import Foundation
import CoreData

class MainScreenViewModel {
    // MARK: - Properties
    private let coreDataManager = CoreDataManager.shared
    private var despatches: [Despatch] = []
    
    // MARK: - Callbacks
    var onDespatchesUpdated: (() -> Void)?
    
    // MARK: - Methods
    func loadDespatches() {
        despatches = coreDataManager.fetchDespatches()
        onDespatchesUpdated?()
    }
    
    func getDespatchCount() -> Int {
        return despatches.count
    }
    
    func getDespatch(at index: Int) -> Despatch? {
        guard index < despatches.count else { return nil }
        return despatches[index]
    }
    
    func getAllDespatches() -> [Despatch] {
        return despatches
    }
    
    func deleteDespatch(at index: Int) {
        guard index < despatches.count else { return }
        let despatch = despatches[index]
        coreDataManager.deleteDespatch(despatch)
        despatches.remove(at: index)
        onDespatchesUpdated?()
    }
    
    func deleteDespatch(_ despatch: Despatch) {
        coreDataManager.deleteDespatch(despatch)
        if let index = despatches.firstIndex(of: despatch) {
            despatches.remove(at: index)
        }
        onDespatchesUpdated?()
    }
    
    func addDespatch(title: String, invoiceNumber: String?) {
        let newDespatch = coreDataManager.createDespatch(title: title, invoiceNumber: invoiceNumber)
        despatches.append(newDespatch)
    }
} 