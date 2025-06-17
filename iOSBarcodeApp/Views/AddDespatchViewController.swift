import UIKit

class AddDespatchViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    // MARK: - Properties
    let viewModel = AddDespatchViewModel()
    private let tableRowHeight: CGFloat = 80
    
    // Düzenleme modu için property
    var editingDespatch: Despatch? {
        didSet {
            if let despatch = editingDespatch {
                viewModel.loadDespatchForEditing(despatch)
                title = "Sevkiyat Düzenle"
                titleTextField.text = despatch.title
                numberTextField.text = despatch.invoiceNumber
            }
        }
    }
    
    // MARK: - UI Elements
    private let productCount: Int = 3
    private var tableViewHeightConstraint: NSLayoutConstraint?
    
    // Safe area'yı dolduran açık gri arka plan
    private let backgroundView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .systemGroupedBackground
        return v
    }()
    // ScrollView ve contentView
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
    // Üstteki kart (başlık ve irsaliye numarası)
    private let formCard: UIView = {
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
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Başlık"
        label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    private let titleTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Başlık giriniz"
        tf.font = UIFont.systemFont(ofSize: 15)
        tf.backgroundColor = .white
        tf.layer.cornerRadius = 10
        tf.layer.shadowColor = UIColor.black.cgColor
        tf.layer.shadowOpacity = 0.08
        tf.layer.shadowOffset = CGSize(width: 0, height: 2)
        tf.layer.shadowRadius = 4
        tf.layer.borderWidth = 0.5
        tf.layer.borderColor = UIColor.systemGray4.cgColor
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.setLeftPaddingPoints(20)
        return tf
    }()
    private let numberLabel: UILabel = {
        let label = UILabel()
        label.text = "İrsaliye Numarası"
        label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    private let numberTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "İrsaliye numarası giriniz"
        tf.font = UIFont.systemFont(ofSize: 15)
        tf.backgroundColor = .white
        tf.layer.cornerRadius = 10
        tf.layer.shadowColor = UIColor.black.cgColor
        tf.layer.shadowOpacity = 0.08
        tf.layer.shadowOffset = CGSize(width: 0, height: 2)
        tf.layer.shadowRadius = 4
        tf.layer.borderWidth = 0.5
        tf.layer.borderColor = UIColor.systemGray4.cgColor
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.setLeftPaddingPoints(20)
        return tf
    }()
    // Ürünler başlığı
    private let productsLabel: UILabel = {
        let label = UILabel()
        label.text = "Ürünler"
        label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    // Ürün ekleme butonu container
    private let addProductButtonContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .systemGreen // Yeşil renk
        v.layer.cornerRadius = 20 // Tam yuvarlak
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.3
        v.layer.shadowOffset = CGSize(width: 4, height: 4)
        v.layer.shadowRadius = 6
        return v
    }()
    // Ürün ekleme butonu
    private let addProductButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .clear
        button.layer.cornerRadius = 20
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.3
        button.layer.shadowOffset = CGSize(width: 4, height: 4)
        button.layer.shadowRadius = 6
        
        // Plus ikonu - daha küçük ve sade (MainScreen'deki gibi)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .light) // Boyut 18, kalınlık light
        let image = UIImage(systemName: "plus", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = .white
        
        button.imageView?.contentMode = .scaleAspectFit
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        return button
    }()
    // TableView kartı
    private let tableCard: UIView = {
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
    private let productsTableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.layer.cornerRadius = 12
        tableView.layer.masksToBounds = true
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        return tableView
    }()
    // Kaydet butonu için container
    private let saveButtonContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .white
        v.layer.cornerRadius = 20
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner] // Sadece üst köşeler
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.08
        v.layer.shadowOffset = CGSize(width: 0, height: -2)
        v.layer.shadowRadius = 8
        return v
    }()
    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Kaydet", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemGreen
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        button.layer.cornerRadius = 14
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.08
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private var productCounts: [Int] = [1, 1, 1]
    
    // Spacer view (scrollView'in sonunda)
    private let bottomSpacer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .clear
        return v
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.tintColor = .white
        view.backgroundColor = UIColor(named: "MainColor")
        self.title = "Yeni Sevkiyat Ekle"
        self.navigationController?.navigationBar.topItem?.backButtonTitle = ""
        
        setupUI()
        setupTableView()
        setupBindings()
        
        // Klavyeyi kapatmak için tap gesture ekle
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    private func setupBindings() {
        // TextField değişikliklerini dinle
        titleTextField.addTarget(self, action: #selector(titleTextFieldChanged), for: .editingChanged)
        numberTextField.addTarget(self, action: #selector(numberTextFieldChanged), for: .editingChanged)
    }
    
    @objc private func titleTextFieldChanged() {
        viewModel.updateTitle(titleTextField.text ?? "")
    }
    
    @objc private func numberTextFieldChanged() {
        viewModel.updateInvoiceNumber(numberTextField.text ?? "")
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        // Safe area'yı dolduran açık gri backgroundView
        view.addSubview(backgroundView)
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        // ScrollView ve contentView
        backgroundView.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: backgroundView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor)
        ])
        scrollView.addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        // Form Card (üstteki kart)
        contentView.addSubview(formCard)
        NSLayoutConstraint.activate([
            formCard.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 32),
            formCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            formCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
        // Form Card içeriği
        formCard.addSubview(titleLabel)
        formCard.addSubview(titleTextField)
        formCard.addSubview(numberLabel)
        formCard.addSubview(numberTextField)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: formCard.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: formCard.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: formCard.trailingAnchor, constant: -16),
            
            titleTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            titleTextField.leadingAnchor.constraint(equalTo: formCard.leadingAnchor, constant: 12),
            titleTextField.trailingAnchor.constraint(equalTo: formCard.trailingAnchor, constant: -12),
            titleTextField.heightAnchor.constraint(equalToConstant: 52),
            
            numberLabel.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 20),
            numberLabel.leadingAnchor.constraint(equalTo: formCard.leadingAnchor, constant: 16),
            numberLabel.trailingAnchor.constraint(equalTo: formCard.trailingAnchor, constant: -16),
            
            numberTextField.topAnchor.constraint(equalTo: numberLabel.bottomAnchor, constant: 8),
            numberTextField.leadingAnchor.constraint(equalTo: formCard.leadingAnchor, constant: 12),
            numberTextField.trailingAnchor.constraint(equalTo: formCard.trailingAnchor, constant: -12),
            numberTextField.heightAnchor.constraint(equalToConstant: 52),
            numberTextField.bottomAnchor.constraint(equalTo: formCard.bottomAnchor, constant: -20)
        ])
        // Ürünler başlığı ve ürün ekleme butonu için container
        let headerContainer = UIView()
        headerContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(headerContainer)
        
        headerContainer.addSubview(productsLabel)
        headerContainer.addSubview(addProductButtonContainer)
        addProductButtonContainer.addSubview(addProductButton)
        
        NSLayoutConstraint.activate([
            headerContainer.topAnchor.constraint(equalTo: formCard.bottomAnchor, constant: 32),
            headerContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            headerContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            headerContainer.heightAnchor.constraint(equalToConstant: 40),
            
            productsLabel.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),
            productsLabel.centerYAnchor.constraint(equalTo: headerContainer.centerYAnchor),
            
            addProductButtonContainer.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor),
            addProductButtonContainer.centerYAnchor.constraint(equalTo: headerContainer.centerYAnchor),
            addProductButtonContainer.widthAnchor.constraint(equalToConstant: 40), // Genişlik 40
            addProductButtonContainer.heightAnchor.constraint(equalToConstant: 40), // Yükseklik 40
            
            addProductButton.topAnchor.constraint(equalTo: addProductButtonContainer.topAnchor),
            addProductButton.leadingAnchor.constraint(equalTo: addProductButtonContainer.leadingAnchor),
            addProductButton.trailingAnchor.constraint(equalTo: addProductButtonContainer.trailingAnchor),
            addProductButton.bottomAnchor.constraint(equalTo: addProductButtonContainer.bottomAnchor)
        ])
        
        // TableView Card'ı headerContainer'ın altına taşı
        contentView.addSubview(tableCard)
        NSLayoutConstraint.activate([
            tableCard.topAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: 8),
            tableCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            tableCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
        
        // TableView
        tableCard.addSubview(productsTableView)
        NSLayoutConstraint.activate([
            productsTableView.topAnchor.constraint(equalTo: tableCard.topAnchor, constant: 8),
            productsTableView.leadingAnchor.constraint(equalTo: tableCard.leadingAnchor, constant: 8),
            productsTableView.trailingAnchor.constraint(equalTo: tableCard.trailingAnchor, constant: -8),
            productsTableView.bottomAnchor.constraint(equalTo: tableCard.bottomAnchor, constant: -8)
        ])
        // TableView yüksekliğini dinamik ayarla
        tableViewHeightConstraint = productsTableView.heightAnchor.constraint(equalToConstant: CGFloat(productCounts.count) * tableRowHeight + 16)
        tableViewHeightConstraint?.isActive = true
        // Save button container ve buton
        view.addSubview(saveButtonContainer)
        NSLayoutConstraint.activate([
            saveButtonContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            saveButtonContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            saveButtonContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            saveButtonContainer.heightAnchor.constraint(equalToConstant: 120)
        ])
        saveButtonContainer.addSubview(saveButton)
        NSLayoutConstraint.activate([
            saveButton.leadingAnchor.constraint(equalTo: saveButtonContainer.leadingAnchor, constant: 32),
            saveButton.trailingAnchor.constraint(equalTo: saveButtonContainer.trailingAnchor, constant: -32),
            saveButton.heightAnchor.constraint(equalToConstant: 56),
            saveButton.topAnchor.constraint(equalTo: saveButtonContainer.topAnchor, constant: 25)
        ])
        // TableView delegate/dataSource
        productsTableView.delegate = self
        productsTableView.dataSource = self
        productsTableView.register(ProductCell.self, forCellReuseIdentifier: "ProductCell")
        productsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "EmptyProductCell")
        productsTableView.separatorStyle = .none
        productsTableView.isScrollEnabled = false
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        
        contentView.addSubview(bottomSpacer)
        NSLayoutConstraint.activate([
            bottomSpacer.topAnchor.constraint(equalTo: tableCard.bottomAnchor, constant: 24),
            bottomSpacer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bottomSpacer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bottomSpacer.heightAnchor.constraint(equalToConstant: 120),
            bottomSpacer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        // Ürün ekleme butonu için action ekle
        addProductButton.addTarget(self, action: #selector(addProductButtonTapped), for: .touchUpInside)
    }
    
    private func setupTableView() {
        productsTableView.delegate = self
        productsTableView.dataSource = self
        productsTableView.register(ProductCell.self, forCellReuseIdentifier: "ProductCell")
        productsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "EmptyProductCell")
        productsTableView.separatorStyle = .none
        productsTableView.isScrollEnabled = false
    }
    
    // MARK: - TableView DataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return max(1, viewModel.getProductCount())
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if viewModel.getProductCount() == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "EmptyProductCell") ?? UITableViewCell(style: .default, reuseIdentifier: "EmptyProductCell")
            
            // Ana mesaj
            let mainLabel = UILabel()
            mainLabel.text = "Henüz ürün bulunmuyor"
            mainLabel.textAlignment = .center
            mainLabel.textColor = .systemGray
            mainLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
            mainLabel.translatesAutoresizingMaskIntoConstraints = false
            
            // Alt mesaj
            let subLabel = UILabel()
            subLabel.text = "Ürün eklemek için + butonuna tıklayın"
            subLabel.textAlignment = .center
            subLabel.textColor = .systemGray2
            subLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
            subLabel.translatesAutoresizingMaskIntoConstraints = false
            
            cell.contentView.addSubview(mainLabel)
            cell.contentView.addSubview(subLabel)
            
            NSLayoutConstraint.activate([
                mainLabel.centerXAnchor.constraint(equalTo: cell.contentView.centerXAnchor),
                mainLabel.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor, constant: -15),
                
                subLabel.centerXAnchor.constraint(equalTo: cell.contentView.centerXAnchor),
                subLabel.topAnchor.constraint(equalTo: mainLabel.bottomAnchor, constant: 8)
            ])
            
            cell.selectionStyle = .none
            cell.backgroundColor = .clear
            return cell
        }
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ProductCell", for: indexPath) as? ProductCell,
              let product = viewModel.getProduct(at: indexPath.section) else {
            return UITableViewCell()
        }
        cell.configure(name: product.name, count: product.serialNumbers.count)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if viewModel.getProductCount() == 0 {
            return tableView.bounds.height
        }
        return tableRowHeight
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return viewModel.getProductCount() > 0
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Önce tableView'ı güncellemeyi durdur
            tableView.beginUpdates()
            
            // Ürünü sil
            viewModel.removeProduct(at: indexPath.section)
            
            // Eğer son ürün silindiyse
            if viewModel.getProductCount() == 0 {
                // Önce silme işlemini iptal et
                tableView.endUpdates()
                // Sonra tüm tableView'ı yenile
                DispatchQueue.main.async {
                    tableView.reloadData()
                    self.updateTableViewHeight()
                }
            } else {
                // Değilse sadece silinen satırı kaldır
                tableView.deleteSections(IndexSet(integer: indexPath.section), with: .fade)
                tableView.endUpdates()
                updateTableViewHeight()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Sil"
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let product = viewModel.getProduct(at: indexPath.section) else {
            return
        }
        
        let addDespatchLineVC = AddDespatchLineViewController()
        addDespatchLineVC.editingProduct = product
        addDespatchLineVC.editingProductIndex = indexPath.section
        
        addDespatchLineVC.onProductSaved = { [weak self] (name, serialNumbers, index: Int?) in
            guard let self = self else { return }
            self.viewModel.saveProduct(name: name, serialNumbers: serialNumbers, at: index)
            self.productsTableView.reloadData()
            self.updateTableViewHeight()
        }
        
        navigationController?.pushViewController(addDespatchLineVC, animated: true)
    }
    
    // MARK: - Actions
    @objc private func addProductButtonTapped() {
        // Buton ve container animasyonu
        UIView.animate(withDuration: 0.15, animations: {
            self.addProductButton.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
            self.addProductButtonContainer.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        }) { _ in
            UIView.animate(withDuration: 0.15, delay: 0.05, options: .curveEaseOut) {
                self.addProductButton.transform = CGAffineTransform.identity
                self.addProductButtonContainer.transform = CGAffineTransform.identity
            } completion: { [weak self] _ in
                // Yeni ürün ekleme ekranını aç
                let addDespatchLineVC = AddDespatchLineViewController()
                addDespatchLineVC.onProductSaved = { [weak self] (name, serialNumbers, index: Int?) in
                    self?.viewModel.saveProduct(name: name, serialNumbers: serialNumbers, at: index)
                    self?.productsTableView.reloadData()
                    self?.updateTableViewHeight()
                }
                self?.navigationController?.pushViewController(addDespatchLineVC, animated: true)
            }
        }
    }
    
    @objc private func saveButtonTapped() {
        // Başlık kontrolü
        guard !viewModel.title.isEmpty else {
            showAlert(title: "Hata", message: "Lütfen sevkiyat başlığını giriniz.")
            return
        }
        
        // Ürün kontrolü
        guard viewModel.getProductCount() > 0 else {
            showAlert(title: "Hata", message: "Lütfen en az bir ürün ekleyiniz.")
            return
        }
        
        if viewModel.saveDespatch() {
            // Ana ekranı güncelle
            if let mainScreenVC = navigationController?.viewControllers.first as? MainScreenViewController {
                mainScreenVC.viewModel.loadDespatches()
                mainScreenVC.DespatchTableView.reloadData()
            }
            navigationController?.popViewController(animated: true)
        } else {
            showAlert(title: "Hata", message: "Sevkiyat kaydedilemedi. Lütfen tekrar deneyin.")
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Helper Methods
    private func updateTableViewHeight() {
        let extraPadding: CGFloat = 16
        tableViewHeightConstraint?.constant = viewModel.getProductCount() == 0 ? 
            tableRowHeight : 
            (CGFloat(viewModel.getProductCount()) * tableRowHeight) + extraPadding
        view.layoutIfNeeded()
    }
    
    // MARK: - Keyboard Handling
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}

// MARK: - UITextField Extension
private extension UITextField {
    func setLeftPaddingPoints(_ amount:CGFloat){
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
}

// MARK: - ProductCell
class ProductCell: UITableViewCell {
    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let countDisplayLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = .darkGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Ayırıcı çizgi
    let separator: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.systemGray5
        return v
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 0 // Yuvarlaklık kaldırıldı
        contentView.layer.masksToBounds = true // Keskin kenarlar için true
        contentView.layer.shadowOpacity = 0 // Gölge kaldırıldı
        
        contentView.addSubview(nameLabel)
        contentView.addSubview(countDisplayLabel)
        contentView.addSubview(separator)

        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            countDisplayLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            countDisplayLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            countDisplayLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            countDisplayLabel.bottomAnchor.constraint(lessThanOrEqualTo: separator.topAnchor, constant: -12), // Separator'a göre ayarlandı
            
            separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0),
            separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0),
            separator.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(name: String, count: Int) {
        nameLabel.text = name
        countDisplayLabel.text = "\(count) adet seri numarası tanımlı"
        
        // Son hücrenin separator'ını gizle
        if let tableView = self.superview as? UITableView,
           let indexPath = tableView.indexPath(for: self),
           indexPath.section == tableView.numberOfSections - 1 {
            separator.isHidden = true
        } else {
            separator.isHidden = false
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Cell'in contentView'ini tam olarak kaplaması için
        contentView.frame = bounds
    }
} 
