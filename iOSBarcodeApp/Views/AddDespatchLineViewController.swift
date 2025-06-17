import UIKit

class AddDespatchLineViewController: UIViewController {
    // MARK: - Properties
    private var viewModel: AddDespatchLineViewModel!
    private var isFirstAppearance = true
    
    var editingProduct: Product? // Dışarıdan gelecek ürün objesi
    var editingProductIndex: Int? // Dışarıdan gelecek ürün indeksi
    
    // Callback for saving product
    var onProductSaved: ((String, [String], Int?) -> Void)?
    
    // MARK: - UI Elements
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.backgroundColor = .clear
        return sv
    }()
    private let contentView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .clear
        return v
    }()

    private let productFormCard: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .white
        v.layer.cornerRadius = 10
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.08
        v.layer.shadowOffset = CGSize(width: 0, height: 2)
        v.layer.shadowRadius = 8
        return v
    }()

    private let productNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Ürün Adı"
        label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        return label
    }()
    private let productNameTextField: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.placeholder = "Ürün adını giriniz"
        tf.font = UIFont.systemFont(ofSize: 15)
        tf.backgroundColor = .white
        tf.layer.cornerRadius = 10
        tf.layer.shadowColor = UIColor.black.cgColor
        tf.layer.shadowOpacity = 0.08
        tf.layer.shadowOffset = CGSize(width: 0, height: 2)
        tf.layer.shadowRadius = 4
        tf.layer.borderWidth = 0.5
        tf.layer.borderColor = UIColor.systemGray4.cgColor
        tf.setLeftPaddingPoints(20)
        return tf
    }()

    private let productNameBarcodeButtonContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .systemBlue
        v.layer.cornerRadius = 12
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.15
        v.layer.shadowOffset = CGSize(width: 2, height: 2)
        v.layer.shadowRadius = 4
        return v
    }()
    private let productNameBarcodeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 12
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.15
        button.layer.shadowOffset = CGSize(width: 2, height: 2)
        button.layer.shadowRadius = 4
        
        var config = UIButton.Configuration.plain()
        let config2 = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
            .applying(UIImage.SymbolConfiguration(scale: .large))
        config.image = UIImage(systemName: "barcode.viewfinder", withConfiguration: config2)
        config.baseForegroundColor = .white
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        button.configuration = config
        
        return button
    }()
    
    private let serialNumbersCard: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .white
        v.layer.cornerRadius = 10
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.08
        v.layer.shadowOffset = CGSize(width: 0, height: 2)
        v.layer.shadowRadius = 8
        return v
    }()

    private let serialNumbersHeaderContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let serialNumbersLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Seri Numaraları"
        label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        return label
    }()
    
    private let addSerialNumberBarcodeButtonContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .systemBlue
        v.layer.cornerRadius = 12
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.15
        v.layer.shadowOffset = CGSize(width: 2, height: 2)
        v.layer.shadowRadius = 4
        return v
    }()
    private let addSerialNumberBarcodeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 12
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.15
        button.layer.shadowOffset = CGSize(width: 2, height: 2)
        button.layer.shadowRadius = 4
        
        var config = UIButton.Configuration.plain()
        let config2 = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
            .applying(UIImage.SymbolConfiguration(scale: .large))
        config.image = UIImage(systemName: "barcode.viewfinder", withConfiguration: config2)
        config.baseForegroundColor = .white
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        button.configuration = config
        
        return button
    }()

    private let serialNumbersTableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.layer.cornerRadius = 10
        tableView.layer.masksToBounds = true
        return tableView
    }()
    
    private var serialNumbers: [String] = [] { // Seri numaralarını tutacak dizi
        didSet {
            updateSaveButtonTitle()
        }
    }
    private var serialNumberTableViewHeightConstraint: NSLayoutConstraint?

    private let saveButtonContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .white
        v.layer.cornerRadius = 20
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.08
        v.layer.shadowOffset = CGSize(width: 0, height: -2)
        v.layer.shadowRadius = 8
        return v
    }()
    
    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        var config = UIButton.Configuration.filled()
        config.title = "Kaydet"
        config.baseForegroundColor = .white
        config.baseBackgroundColor = .systemGreen
        config.cornerStyle = .medium
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.systemFont(ofSize: 17, weight: .bold)
            return outgoing
        }
        button.configuration = config
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.08
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        return button
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .systemGray
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()

    private var containerHeightConstraint: NSLayoutConstraint?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "MainColor")
        
        // ViewModel'i başlat
        viewModel = AddDespatchLineViewModel()
        
        // Navigation bar ayarları
        navigationItem.title = "Yeni Ürün Ekle"
        
        // View'ları oluştur
        setupViews()
        
        // Constraint'leri ve bindings'i hemen aktifleştir
        activateConstraints()
        setupBindings()
        
        // Başlangıçta tüm view'ları gizle
        productFormCard.alpha = 0
        serialNumbersCard.alpha = 0
        saveButtonContainer.alpha = 0
        
        updateSaveButtonTitle()
        
        // TableView ayırıcı stilini kapat
        serialNumbersTableView.separatorStyle = .none
        
        // Klavyeyi kapatmak için tap gesture ekle
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        // TextField değişikliklerini dinle
        productNameTextField.addTarget(self, action: #selector(productNameTextFieldChanged), for: .editingChanged)
        
        // Düzenleme modu için ürün verilerini yükle
        if let product = editingProduct {
            navigationItem.title = "Ürün Düzenle"
            viewModel.editingProductIndex = editingProductIndex
            viewModel.loadProductData(productName: product.name, serialNumbers: product.serialNumbers)
        }
        
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        
        // Geri butonu için özel davranış
        navigationItem.hidesBackButton = true
        let backButton = UIBarButtonItem(image: UIImage(systemName: "chevron.left"),
                                       style: .plain,
                                       target: self,
                                       action: #selector(backButtonTapped))
        backButton.tintColor = .white
        navigationItem.leftBarButtonItem = backButton
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Açılış animasyonları
        UIView.animate(withDuration: 0.2, delay: 0.05, options: .curveEaseOut) {
            self.productFormCard.alpha = 1
            self.productFormCard.transform = .identity
        }
        
        UIView.animate(withDuration: 0.2, delay: 0.1, options: .curveEaseOut) {
            self.serialNumbersCard.alpha = 1
            self.serialNumbersCard.transform = .identity
        }
        
        UIView.animate(withDuration: 0.2, delay: 0.15, options: .curveEaseOut) {
            self.saveButtonContainer.alpha = 1
            self.saveButtonContainer.transform = .identity
        }
        
        updateSerialNumberTableViewHeight()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateSerialNumberTableViewHeight()
    }
    
    // MARK: - Setup
    private func setupViews() {
        // ScrollView ve contentView
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Product Form Card ve içeriği
        contentView.addSubview(productFormCard)
        productFormCard.addSubview(productNameLabel)
        productFormCard.addSubview(productNameTextField)
        productFormCard.addSubview(productNameBarcodeButtonContainer)
        productNameBarcodeButtonContainer.addSubview(productNameBarcodeButton)
        
        // Serial Numbers Card ve içeriği
        contentView.addSubview(serialNumbersCard)
        serialNumbersCard.addSubview(serialNumbersHeaderContainer)
        serialNumbersHeaderContainer.addSubview(serialNumbersLabel)
        serialNumbersHeaderContainer.addSubview(addSerialNumberBarcodeButtonContainer)
        addSerialNumberBarcodeButtonContainer.addSubview(addSerialNumberBarcodeButton)
        serialNumbersCard.addSubview(serialNumbersTableView)
        
        // Save Button Container ve içeriği
        view.addSubview(saveButtonContainer)
        saveButtonContainer.addSubview(saveButton)
        saveButtonContainer.addSubview(statusLabel)
        
        // Bottom spacer
        let bottomSpacer = UIView()
        bottomSpacer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bottomSpacer)
        
        // TableView ayarları
        serialNumbersTableView.delegate = self
        serialNumbersTableView.dataSource = self
        serialNumbersTableView.register(SerialNumberCell.self, forCellReuseIdentifier: "SerialNumberCell")
        serialNumbersTableView.register(UITableViewCell.self, forCellReuseIdentifier: "EmptySerialNumberCell")
        
        // Button targets
        productNameBarcodeButton.addTarget(self, action: #selector(scanProductNameButtonTapped), for: .touchUpInside)
        addSerialNumberBarcodeButton.addTarget(self, action: #selector(scanSerialNumberButtonTapped), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        
        // Başlangıç pozisyonları
        productFormCard.transform = CGAffineTransform(translationX: 0, y: 20)
        serialNumbersCard.transform = CGAffineTransform(translationX: 0, y: 20)
        saveButtonContainer.transform = CGAffineTransform(translationX: 0, y: 20)
    }
    
    private func activateConstraints() {
        // ScrollView ve contentView constraints
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        // Product Form Card constraints
        NSLayoutConstraint.activate([
            productFormCard.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            productFormCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            productFormCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            productNameLabel.topAnchor.constraint(equalTo: productFormCard.topAnchor, constant: 20),
            productNameLabel.leadingAnchor.constraint(equalTo: productFormCard.leadingAnchor, constant: 16),
            productNameLabel.trailingAnchor.constraint(equalTo: productFormCard.trailingAnchor, constant: -16),
            
            productNameTextField.topAnchor.constraint(equalTo: productNameLabel.bottomAnchor, constant: 8),
            productNameTextField.leadingAnchor.constraint(equalTo: productFormCard.leadingAnchor, constant: 12),
            productNameTextField.trailingAnchor.constraint(equalTo: productNameBarcodeButtonContainer.leadingAnchor, constant: -8),
            productNameTextField.heightAnchor.constraint(equalToConstant: 52),
            
            productNameBarcodeButtonContainer.centerYAnchor.constraint(equalTo: productNameTextField.centerYAnchor),
            productNameBarcodeButtonContainer.trailingAnchor.constraint(equalTo: productFormCard.trailingAnchor, constant: -12),
            productNameBarcodeButtonContainer.widthAnchor.constraint(equalToConstant: 52),
            productNameBarcodeButtonContainer.heightAnchor.constraint(equalToConstant: 52),
            
            productNameBarcodeButton.topAnchor.constraint(equalTo: productNameBarcodeButtonContainer.topAnchor),
            productNameBarcodeButton.leadingAnchor.constraint(equalTo: productNameBarcodeButtonContainer.leadingAnchor),
            productNameBarcodeButton.trailingAnchor.constraint(equalTo: productNameBarcodeButtonContainer.trailingAnchor),
            productNameBarcodeButton.bottomAnchor.constraint(equalTo: productNameBarcodeButtonContainer.bottomAnchor),
            
            productFormCard.bottomAnchor.constraint(equalTo: productNameTextField.bottomAnchor, constant: 20)
        ])

        // Serial Numbers Card constraints
        NSLayoutConstraint.activate([
            serialNumbersCard.topAnchor.constraint(equalTo: productFormCard.bottomAnchor, constant: 40),
            serialNumbersCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            serialNumbersCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            serialNumbersHeaderContainer.topAnchor.constraint(equalTo: serialNumbersCard.topAnchor, constant: 20),
            serialNumbersHeaderContainer.leadingAnchor.constraint(equalTo: serialNumbersCard.leadingAnchor, constant: 16),
            serialNumbersHeaderContainer.trailingAnchor.constraint(equalTo: serialNumbersCard.trailingAnchor, constant: -16),
            serialNumbersHeaderContainer.heightAnchor.constraint(equalToConstant: 40),
            
            serialNumbersLabel.leadingAnchor.constraint(equalTo: serialNumbersHeaderContainer.leadingAnchor),
            serialNumbersLabel.centerYAnchor.constraint(equalTo: serialNumbersHeaderContainer.centerYAnchor),
            
            addSerialNumberBarcodeButtonContainer.trailingAnchor.constraint(equalTo: serialNumbersHeaderContainer.trailingAnchor),
            addSerialNumberBarcodeButtonContainer.centerYAnchor.constraint(equalTo: serialNumbersHeaderContainer.centerYAnchor),
            addSerialNumberBarcodeButtonContainer.widthAnchor.constraint(equalToConstant: 52),
            addSerialNumberBarcodeButtonContainer.heightAnchor.constraint(equalToConstant: 52),
            
            addSerialNumberBarcodeButton.topAnchor.constraint(equalTo: addSerialNumberBarcodeButtonContainer.topAnchor),
            addSerialNumberBarcodeButton.leadingAnchor.constraint(equalTo: addSerialNumberBarcodeButtonContainer.leadingAnchor),
            addSerialNumberBarcodeButton.trailingAnchor.constraint(equalTo: addSerialNumberBarcodeButtonContainer.trailingAnchor),
            addSerialNumberBarcodeButton.bottomAnchor.constraint(equalTo: addSerialNumberBarcodeButtonContainer.bottomAnchor),
            
            serialNumbersTableView.topAnchor.constraint(equalTo: serialNumbersHeaderContainer.bottomAnchor, constant: 16),
            serialNumbersTableView.leadingAnchor.constraint(equalTo: serialNumbersCard.leadingAnchor, constant: 8),
            serialNumbersTableView.trailingAnchor.constraint(equalTo: serialNumbersCard.trailingAnchor, constant: -8),
            serialNumbersTableView.bottomAnchor.constraint(equalTo: serialNumbersCard.bottomAnchor, constant: -8)
        ])

        // Save Button Container constraints
        NSLayoutConstraint.activate([
            saveButtonContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            saveButtonContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            saveButtonContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            saveButtonContainer.heightAnchor.constraint(equalToConstant: 145),
            
            saveButton.leadingAnchor.constraint(equalTo: saveButtonContainer.leadingAnchor, constant: 32),
            saveButton.trailingAnchor.constraint(equalTo: saveButtonContainer.trailingAnchor, constant: -32),
            saveButton.heightAnchor.constraint(equalToConstant: 56),
            saveButton.centerYAnchor.constraint(equalTo: saveButtonContainer.centerYAnchor, constant: -10),
            
            statusLabel.leadingAnchor.constraint(equalTo: saveButtonContainer.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: saveButtonContainer.trailingAnchor, constant: -16),
            statusLabel.bottomAnchor.constraint(equalTo: saveButton.topAnchor, constant: -8)
        ])
        
        // Bottom spacer constraints
        if let bottomSpacer = contentView.subviews.last {
            NSLayoutConstraint.activate([
                bottomSpacer.topAnchor.constraint(equalTo: serialNumbersTableView.bottomAnchor, constant: 24),
                bottomSpacer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                bottomSpacer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                bottomSpacer.heightAnchor.constraint(equalToConstant: 160),
                bottomSpacer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])
        }
        
        // TableView height constraint
        serialNumberTableViewHeightConstraint = serialNumbersTableView.heightAnchor.constraint(equalToConstant: 0)
        serialNumberTableViewHeightConstraint?.isActive = true
    }
    
    private func setupBindings() {
        viewModel.onProductNameUpdated = { [weak self] name in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.productNameTextField.text = name
            }
        }
        
        viewModel.onSerialNumbersUpdated = { [weak self] serialNumbers in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.serialNumbersTableView.reloadData()
                self.updateUI()
            }
        }
        
        viewModel.onNewlyScannedCountUpdated = { [weak self] count in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.updateStatusLabel(count: count)
            }
        }
        
        viewModel.onSaveCompleted = { [weak self] success in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if success {
                    self.showSuccessMessage()
                } else {
                    self.showErrorMessage()
                }
            }
        }
    }

    private func updateUI() {
        updateSerialNumberTableViewHeight()
        updateSaveButtonTitle()
        updateStatusLabel(count: viewModel.getSerialNumberCount())
    }
    
    private func updateStatusLabel(count: Int) {
        if count > 0 {
            statusLabel.text = "\(count) adet yeni seri numarası eklendi"
            statusLabel.textColor = .systemGreen
        } else {
            statusLabel.text = "Henüz seri numarası eklenmedi"
            statusLabel.textColor = .systemGray
        }
    }
    
    private func updateSaveButtonTitle() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let count = self.viewModel.getSerialNumberCount()
            if count == 0 {
                self.saveButton.setTitle("Kaydet", for: .normal)
            } else {
                self.saveButton.setTitle("Kaydet (\(count))", for: .normal)
            }
        }
    }
    
    private func showSuccessMessage() {
        statusLabel.text = "Ürün başarıyla kaydedildi"
        statusLabel.textColor = .systemGreen
    }
    
    private func showErrorMessage() {
        statusLabel.text = "Ürün kaydedilirken bir hata oluştu"
        statusLabel.textColor = .systemRed
    }

    // MARK: - Actions
    @objc private func scanProductNameButtonTapped() {
        // Buton animasyonu
        UIView.animate(withDuration: 0.15, animations: { [weak self] in
            guard let self = self else { return }
            self.productNameBarcodeButton.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
            self.productNameBarcodeButtonContainer.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        }) { [weak self] _ in
            guard let self = self else { return }
            UIView.animate(withDuration: 0.15, delay: 0.05, options: .curveEaseOut) {
                self.productNameBarcodeButton.transform = CGAffineTransform.identity
                self.productNameBarcodeButtonContainer.transform = CGAffineTransform.identity
            } completion: { [weak self] _ in
                guard let self = self else { return }
                let scannerVC = BarcodeScannerViewController()
                scannerVC.modalPresentationStyle = .fullScreen
                scannerVC.scannerPurpose = .productName
                scannerVC.onProductBarcodeScanned = { [weak self] (barcodeValue: String) in
                    DispatchQueue.main.async {
                        self?.viewModel.updateProductName(barcodeValue)
                        self?.productNameTextField.text = barcodeValue
                    }
                }
                self.present(scannerVC, animated: true)
            }
        }
    }
    
    @objc private func scanSerialNumberButtonTapped() {
        // Buton animasyonu
        UIView.animate(withDuration: 0.15, animations: { [weak self] in
            guard let self = self else { return }
            self.addSerialNumberBarcodeButton.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
            self.addSerialNumberBarcodeButtonContainer.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        }) { [weak self] _ in
            guard let self = self else { return }
            UIView.animate(withDuration: 0.15, delay: 0.05, options: .curveEaseOut) {
                self.addSerialNumberBarcodeButton.transform = CGAffineTransform.identity
                self.addSerialNumberBarcodeButtonContainer.transform = CGAffineTransform.identity
            } completion: { [weak self] _ in
                guard let self = self else { return }
                let scannerVC = BarcodeScannerViewController()
                scannerVC.modalPresentationStyle = .fullScreen
                scannerVC.scannerPurpose = .serialNumber
                scannerVC.existingSerialNumbers = self.viewModel.serialNumbers
                scannerVC.onSerialNumbersScanned = { [weak self] (serialNumbers: [String]) in
                    self?.viewModel.addSerialNumbers(serialNumbers)
                }
                self.present(scannerVC, animated: true)
            }
        }
    }

    @objc private func saveButtonTapped() {
        // Ürün adı kontrolü
        guard !viewModel.productName.isEmpty else {
            showAlert(title: "Hata", message: "Lütfen ürün adını giriniz.")
            return
        }
        
        // Seri numarası kontrolü
        guard viewModel.getSerialNumberCount() > 0 else {
            showAlert(title: "Hata", message: "Lütfen en az bir seri numarası ekleyiniz.")
            return
        }
        
        // Ürünü kaydet ve geri dön
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.onProductSaved?(self.viewModel.productName, self.viewModel.serialNumbers, self.viewModel.editingProductIndex)
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - TextField Handling
    @objc private func productNameTextFieldChanged() {
        viewModel.updateProductName(productNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
    }

    // MARK: - Helper Methods
    private func updateSerialNumberTableViewHeight() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let cellHeight: CGFloat = 50.0
            let minHeight: CGFloat = 200.0
            self.serialNumberTableViewHeightConstraint?.constant = max(minHeight, CGFloat(self.viewModel.getSerialNumberCount()) * cellHeight)
            UIView.animate(withDuration: 0.2) {
                self.view.layoutIfNeeded()
            }
        }
    }

    private func updateContainerHeight() {
        let baseHeight: CGFloat = 140 // Temel yükseklik
        let lineHeight: CGFloat = 20 // Her satır için ek yükseklik
        let statusText = statusLabel.text ?? ""
        let numberOfLines = statusText.components(separatedBy: "\n").count
        
        let newHeight = baseHeight + (CGFloat(numberOfLines - 1) * lineHeight)
        containerHeightConstraint?.constant = newHeight
        
        // Bottom spacer'ı da güncelle
        if let bottomSpacer = contentView.subviews.last {
            bottomSpacer.constraints.forEach { constraint in
                if constraint.firstAttribute == .height {
                    constraint.constant = newHeight
                }
            }
        }
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Keyboard Handling
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension AddDespatchLineViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = viewModel.getSerialNumberCount()
        return count == 0 ? 1 : count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if viewModel.getSerialNumberCount() == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "EmptySerialNumberCell") ?? UITableViewCell(style: .default, reuseIdentifier: "EmptySerialNumberCell")
            
            // Ana mesaj
            let mainLabel = UILabel()
            mainLabel.text = "Henüz seri numarası bulunmuyor"
            mainLabel.textAlignment = .center
            mainLabel.textColor = .systemGray
            mainLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
            mainLabel.translatesAutoresizingMaskIntoConstraints = false
            
            // Alt mesaj ve barkod ikonu bir arada
            let attributedString = NSMutableAttributedString(string: "Seri numarası eklemek için ")
            let imageAttachment = NSTextAttachment()
            imageAttachment.image = UIImage(systemName: "barcode.viewfinder")?.withTintColor(.systemGray2)
            imageAttachment.bounds = CGRect(x: 0, y: -2, width: 15, height: 15)
            attributedString.append(NSAttributedString(attachment: imageAttachment))
            attributedString.append(NSAttributedString(string: " butonuna tıklayın"))
            
            let subLabel = UILabel()
            subLabel.attributedText = attributedString
            subLabel.textAlignment = .center
            subLabel.textColor = .systemGray2
            subLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
            subLabel.numberOfLines = 1
            subLabel.adjustsFontSizeToFitWidth = true
            subLabel.minimumScaleFactor = 0.7
            subLabel.translatesAutoresizingMaskIntoConstraints = false
            
            cell.contentView.addSubview(mainLabel)
            cell.contentView.addSubview(subLabel)
            
            NSLayoutConstraint.activate([
                mainLabel.centerXAnchor.constraint(equalTo: cell.contentView.centerXAnchor),
                mainLabel.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor, constant: -15),
                
                subLabel.centerXAnchor.constraint(equalTo: cell.contentView.centerXAnchor),
                subLabel.topAnchor.constraint(equalTo: mainLabel.bottomAnchor, constant: 8),
                subLabel.leadingAnchor.constraint(greaterThanOrEqualTo: cell.contentView.leadingAnchor, constant: 16),
                subLabel.trailingAnchor.constraint(lessThanOrEqualTo: cell.contentView.trailingAnchor, constant: -16)
            ])
            
            cell.selectionStyle = .none
            cell.backgroundColor = .clear
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
            return cell
        }
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SerialNumberCell", for: indexPath) as? SerialNumberCell,
              let serialNumber = viewModel.getSerialNumber(at: indexPath.row) else {
            return UITableViewCell()
        }
        cell.configure(serialNumber: serialNumber, isLastCell: indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if viewModel.getSerialNumberCount() == 0 {
            return tableView.bounds.height
        }
        return 50.0
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return viewModel.getSerialNumberCount() > 0
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Önce tableView'ı güncellemeyi durdur
            tableView.beginUpdates()
            
            // Seri numarasını sil
            viewModel.removeSerialNumber(at: indexPath.row)
            
            // Eğer son seri numarası silindiyse
            if viewModel.getSerialNumberCount() == 0 {
                // Önce silme işlemini iptal et
                tableView.endUpdates()
                // Sonra tüm tableView'ı yenile
                DispatchQueue.main.async {
                    tableView.reloadData()
                    self.updateSaveButtonTitle()
                }
            } else {
                // Değilse sadece silinen satırı kaldır
                tableView.deleteRows(at: [indexPath], with: .fade)
                tableView.endUpdates()
                updateSaveButtonTitle()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Sil"
    }
}

// MARK: - TextField Extension
private extension UITextField {
    func setLeftPaddingPoints(_ amount:CGFloat){
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
}

// MARK: - SerialNumberCell
class SerialNumberCell: UITableViewCell {
    let serialNumberLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        label.textColor = .darkGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let separator: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.systemGray5
        return v
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear // Hücrenin arka planı şeffaf
        contentView.backgroundColor = .white // İçerik view'i beyaz
        contentView.layer.cornerRadius = 8 // Hafif yuvarlak köşeler
        contentView.layer.masksToBounds = true
        
        contentView.addSubview(serialNumberLabel)
        contentView.addSubview(separator)
        
        NSLayoutConstraint.activate([
            serialNumberLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            serialNumberLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            serialNumberLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(serialNumber: String, isLastCell: Bool) {
        serialNumberLabel.text = serialNumber
        separator.isHidden = isLastCell
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Hücrenin contentView'i tamamen kaplamasını sağla, kenar boşlukları için inset kaldırıldı
        contentView.frame = bounds
    }
} 
