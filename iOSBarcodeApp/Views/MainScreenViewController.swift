//
//  MainScreenViewController.swift
//  iOSBarcodeApp
//
//  Created by Ömer Faruk Küçükahıskalı on 10.06.2025.
//

import UIKit
import CoreData

class MainScreenViewController: UIViewController {

    // MARK: - Outlets
    
    @IBOutlet weak var DespatchTableView: UITableView!
    @IBOutlet weak var AddButtonView: UIView!
    @IBOutlet weak var AddButtonOutlet: UIButton!
    @IBOutlet weak var despatchSearchBar: UISearchBar!
    
    // MARK: - Properties
    
    let viewModel = MainScreenViewModel()
    private var filteredDespatches: [Despatch] = []
    private var isSearching = false
    
    //MARK: - View Funcs
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.loadDespatches()
        DespatchTableView.reloadData()
        
        setupTableView()
        setupSearchBar()
        
        // Navigation bar görünümünü ayarla
        if let navigationBar = navigationController?.navigationBar {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(named: "MainColor")
            appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            
            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
            navigationBar.compactAppearance = appearance
        }
        
        // Navigation bar başlığını ayarla
        self.title = "Sevkiyatlar"
        
        // Klavyeyi kapatmak için tap gesture ekle
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    private func setupUI() {
        viewModel.loadDespatches()
        DespatchTableView.reloadData()
    }
    
    private func setupTableView() {
        DespatchTableView.delegate = self
        DespatchTableView.dataSource = self
        DespatchTableView.register(DespatchTableViewCell.self, forCellReuseIdentifier: "DespatchCell")
        DespatchTableView.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
        DespatchTableView.separatorStyle = .none
    }
    
    private func setupSearchBar() {
        despatchSearchBar.delegate = self
        despatchSearchBar.placeholder = "Başlık veya irsaliye no ile arama yapın"
        despatchSearchBar.searchBarStyle = .minimal
        despatchSearchBar.tintColor = .systemBlue
        
        // Search bar'ın arka plan rengini ayarla
        if let searchBarTextField = despatchSearchBar.value(forKey: "searchField") as? UITextField {
            searchBarTextField.backgroundColor = .white
            searchBarTextField.layer.cornerRadius = 10
            searchBarTextField.layer.masksToBounds = true
        }
        
        // Search bar container'ın arka plan rengini ayarla
        despatchSearchBar.backgroundColor = UIColor(named: "MainColor")
        
        // Search bar'ın kenarlarını kaldır
        despatchSearchBar.backgroundImage = UIImage()
        
        // Search bar'ın alt çizgisini kaldır
        if let textField = despatchSearchBar.value(forKey: "searchField") as? UITextField {
            textField.borderStyle = .none
        }
    }
    
    private func filterDespatches(searchText: String) {
        if searchText.isEmpty {
            isSearching = false
            filteredDespatches = []
        } else {
            isSearching = true
            filteredDespatches = viewModel.getAllDespatches().filter { despatch in
                let titleMatch = (despatch.title ?? "").lowercased().contains(searchText.lowercased())
                let invoiceMatch = (despatch.invoiceNumber ?? "").lowercased().contains(searchText.lowercased())
                return titleMatch || invoiceMatch
            }
        }
        DespatchTableView.reloadData()
    }
    
    private func setupBindings() {
        // ViewModel'den gelen değişiklikleri dinle
        viewModel.onDespatchesUpdated = { [weak self] in
            DispatchQueue.main.async {
                self?.DespatchTableView.reloadData()
            }
        }
    }
        
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        styleButtonView(view: AddButtonView, Button: AddButtonOutlet)
        
        // Buton görselini büyüt
        let config = UIImage.SymbolConfiguration(pointSize: 32, weight: .medium)
        AddButtonOutlet.setImage(UIImage(systemName: "plus", withConfiguration: config), for: .normal)
    }
    
    // MARK: - Funcs
    
    func styleButtonView(view: UIView, Button: UIButton) {
        view.layer.cornerRadius = view.frame.size.width / 2
        Button.layer.cornerRadius = Button.frame.size.width / 2
        view.layer.masksToBounds = false
        Button.layer.masksToBounds = false
        
        view.layer.shadowColor = UIColor.black.cgColor
        Button.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.3
        Button.layer.shadowOpacity = 0.3
        view.layer.shadowOffset = CGSize(width: 4, height: 4)
        Button.layer.shadowOffset = CGSize(width: 4, height: 4)
        view.layer.shadowRadius = 6
        Button.layer.shadowRadius = 6
    }

    func animateButtonPress(on view: UIView) {
        UIView.animate(withDuration: 0.1,
                       animations: {
                           view.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
                       }, completion: { _ in
                           UIView.animate(withDuration: 0.1) {
                               view.transform = CGAffineTransform.identity
                           }
                       })
    }
        
    // MARK: - Actions
        
    @IBAction func AddButtonAction(_ sender: Any) {
        // Buton ve container animasyonu
        UIView.animate(withDuration: 0.15, animations: {
            self.AddButtonOutlet.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
            self.AddButtonView.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        }) { _ in
            UIView.animate(withDuration: 0.15, delay: 0.05, options: .curveEaseOut) {
                self.AddButtonOutlet.transform = CGAffineTransform.identity
                self.AddButtonView.transform = CGAffineTransform.identity
            } completion: { _ in
                // Animasyon tamamlandıktan sonra geçiş yap
                let addDespatchVC = AddDespatchViewController()
                self.navigationController?.pushViewController(addDespatchVC, animated: true)
            }
        }
    }
    
    // MARK: - Keyboard Handling
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource

extension MainScreenViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        if isSearching {
            return filteredDespatches.count == 0 ? 1 : filteredDespatches.count
        }
        return viewModel.getDespatchCount() == 0 ? 1 : viewModel.getDespatchCount()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (isSearching && filteredDespatches.count == 0) || (!isSearching && viewModel.getDespatchCount() == 0) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "EmptyCell") ?? UITableViewCell(style: .default, reuseIdentifier: "EmptyCell")
            
            // Ana mesaj
            let mainLabel = UILabel()
            mainLabel.text = isSearching ? "Sonuç bulunamadı" : "Henüz sevkiyat bulunmuyor"
            mainLabel.textAlignment = .center
            mainLabel.textColor = .systemGray
            mainLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
            mainLabel.translatesAutoresizingMaskIntoConstraints = false
            
            // Alt mesaj
            let subLabel = UILabel()
            subLabel.text = isSearching ? "Farklı bir arama terimi deneyin" : "Yeni sevkiyat eklemek için + butonuna tıklayın"
            subLabel.textAlignment = .center
            subLabel.textColor = .systemGray2
            subLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
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
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "DespatchCell", for: indexPath) as? DespatchTableViewCell else {
            return UITableViewCell()
        }
        
        let despatch = isSearching ? filteredDespatches[indexPath.section] : viewModel.getDespatch(at: indexPath.section)
        cell.configure(title: despatch?.title ?? "", invoiceNumber: despatch?.invoiceNumber)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        
        // Özel seçim animasyonu
        UIView.animate(withDuration: 0.1, animations: {
            cell.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
            cell.contentView.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                cell.transform = CGAffineTransform.identity
                cell.contentView.backgroundColor = .white
            } completion: { _ in
                tableView.deselectRow(at: indexPath, animated: false)
                
                let despatch = self.isSearching ? self.filteredDespatches[indexPath.section] : self.viewModel.getDespatch(at: indexPath.section)
                guard let selectedDespatch = despatch else { return }
                
                // SendDespatchViewController'ı aç
                let sendDespatchVC = SendDespatchViewController()
                sendDespatchVC.despatch = selectedDespatch
                self.navigationController?.pushViewController(sendDespatchVC, animated: true)
            }
        }
    }
    
    // Sağa kaydır — Sil
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Sil") { [weak self] (action, view, completionHandler) in
            if self?.isSearching == true {
                if let despatch = self?.filteredDespatches[indexPath.section] {
                    self?.viewModel.deleteDespatch(despatch)
                    self?.filteredDespatches.remove(at: indexPath.section)
                }
            } else {
                self?.viewModel.deleteDespatch(at: indexPath.section)
            }
            tableView.deleteSections(IndexSet(integer: indexPath.section), with: .automatic)
            completionHandler(true)
        }
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        return configuration
    }
    
    // Sola kaydır — Düzenle
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let editAction = UIContextualAction(style: .normal, title: "Düzenle") { [weak self] (action, view, completionHandler) in
            guard let self = self else {
                completionHandler(false)
                return
            }
            
            let despatch = self.isSearching ? self.filteredDespatches[indexPath.section] : self.viewModel.getDespatch(at: indexPath.section)
            guard let selectedDespatch = despatch else {
                completionHandler(false)
                return
            }
            
            // Düzenleme işlemi için AddDespatchViewController'ı aç
            let addDespatchVC = AddDespatchViewController()
            addDespatchVC.editingDespatch = selectedDespatch
            self.navigationController?.pushViewController(addDespatchVC, animated: true)
            completionHandler(true)
        }
        
        editAction.backgroundColor = .systemBlue
        
        let configuration = UISwipeActionsConfiguration(actions: [editAction])
        return configuration
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if viewModel.getDespatchCount() == 0 {
            return tableView.bounds.height
        }
        return 80
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 10
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }
}

// MARK: - Class

class DespatchTableViewCell: UITableViewCell {
    
    let TitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .black
        return label
    }()
    
    let DespatchNumberLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = .gray
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCell() {
        backgroundColor = .clear
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 6
        contentView.layer.masksToBounds = true
        contentView.layer.borderWidth = 0.5
        contentView.layer.borderColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0).cgColor
        
        // Seçim stilini kaldır
        selectionStyle = .none
        
        contentView.addSubview(TitleLabel)
        contentView.addSubview(DespatchNumberLabel)
        
        NSLayoutConstraint.activate([
            TitleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            TitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            TitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            DespatchNumberLabel.topAnchor.constraint(equalTo: TitleLabel.bottomAnchor, constant: 4),
            DespatchNumberLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            DespatchNumberLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            DespatchNumberLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        if animated {
            UIView.animate(withDuration: 0.1) {
                self.contentView.backgroundColor = highlighted ? UIColor(white: 0.95, alpha: 1.0) : .white
                self.transform = highlighted ? CGAffineTransform(scaleX: 0.98, y: 0.98) : .identity
            }
        } else {
            contentView.backgroundColor = highlighted ? UIColor(white: 0.95, alpha: 1.0) : .white
            transform = highlighted ? CGAffineTransform(scaleX: 0.98, y: 0.98) : .identity
        }
    }
    
    func configure(title: String, invoiceNumber: String?) {
        TitleLabel.text = "Başlık: \(title)"
        DespatchNumberLabel.text = "İrsaliye Numarası: \(invoiceNumber ?? "Yok")"
    }
}
// MARK: - UISearchBarDelegate
extension MainScreenViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterDespatches(searchText: searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        isSearching = false
        filteredDespatches = []
        DespatchTableView.reloadData()
    }
}

