import UIKit
import CoreData
import AVFoundation

class SendDespatchViewController: UIViewController {
    // MARK: - Properties
    var despatch: Despatch? {
        didSet {
            viewModel = SendDespatchViewModel(despatch: despatch)
            setupBindings()
        }
    }
    private var viewModel: SendDespatchViewModel!
    
    // MARK: - UI Elements
    private let backgroundView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .systemGroupedBackground
        return v
    }()
    
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
    
    // Başlık ve İrsaliye Numarası Container
    private let infoCard: UIView = {
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
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = .systemGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let titleValueLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .black
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let numberLabel: UILabel = {
        let label = UILabel()
        label.text = "İrsaliye No"
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = .systemGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let numberValueLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Ürünler Container
    private let productsCard: UIView = {
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
    
    private let productsStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 16
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    // Gönder Butonu Container
    private let sendButtonContainer: UIView = {
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
    
    private let sendButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 32, weight: .medium)
        let image = UIImage(systemName: "qrcode.viewfinder", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = .white
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
    
    private let blurView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .dark)
        let view = UIVisualEffectView(effect: blurEffect)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alpha = 0
        return view
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.color = .white
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var qrCodeFrameView: UIView?
    
    private let qrGuideView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()
    
    private let qrGuideLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Lütfen QR Kodunu Okutunuz"
        label.textColor = .white
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textAlignment = .center
        return label
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureWithDespatch()
        setupSendButton()
        setupNavigationBar()
        
        // Blur view ve loading indicator'ı ekle
        view.addSubview(blurView)
        view.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: view.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - Setup
    private func setupNavigationBar() {
        // Geri butonunu özelleştir
        let backButton = UIBarButtonItem(image: UIImage(systemName: "chevron.left"),
                                       style: .plain,
                                       target: self,
                                       action: #selector(backButtonTapped))
        backButton.tintColor = .white
        navigationItem.leftBarButtonItem = backButton
        
        // Geri butonu yazısını kaldır
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(named: "MainColor")
        title = "İrsaliye Gönder"
        
        // Background View
        view.addSubview(backgroundView)
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // ScrollView
        backgroundView.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: backgroundView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor)
        ])
        
        // ContentView
        scrollView.addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // Info Card
        contentView.addSubview(infoCard)
        NSLayoutConstraint.activate([
            infoCard.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 32),
            infoCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            infoCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            infoCard.heightAnchor.constraint(greaterThanOrEqualToConstant: 120)
        ])
        
        // Info Card içeriği
        infoCard.addSubview(titleLabel)
        infoCard.addSubview(titleValueLabel)
        infoCard.addSubview(numberLabel)
        infoCard.addSubview(numberValueLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: infoCard.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor, constant: -16),
            
            titleValueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            titleValueLabel.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: 16),
            titleValueLabel.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor, constant: -16),
            
            numberLabel.topAnchor.constraint(equalTo: titleValueLabel.bottomAnchor, constant: 12),
            numberLabel.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: 16),
            numberLabel.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor, constant: -16),
            
            numberValueLabel.topAnchor.constraint(equalTo: numberLabel.bottomAnchor, constant: 2),
            numberValueLabel.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: 16),
            numberValueLabel.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor, constant: -16),
            numberValueLabel.bottomAnchor.constraint(equalTo: infoCard.bottomAnchor, constant: -16)
        ])
        
        // Products Card
        contentView.addSubview(productsStackView)
        NSLayoutConstraint.activate([
            productsStackView.topAnchor.constraint(equalTo: infoCard.bottomAnchor, constant: 32),
            productsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            productsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
        
        // Send Button Container
        view.addSubview(sendButtonContainer)
        NSLayoutConstraint.activate([
            sendButtonContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sendButtonContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sendButtonContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sendButtonContainer.heightAnchor.constraint(equalToConstant: 120)
        ])
        
        sendButtonContainer.addSubview(sendButton)
        NSLayoutConstraint.activate([
            sendButton.leadingAnchor.constraint(equalTo: sendButtonContainer.leadingAnchor, constant: 32),
            sendButton.trailingAnchor.constraint(equalTo: sendButtonContainer.trailingAnchor, constant: -32),
            sendButton.heightAnchor.constraint(equalToConstant: 56),
            sendButton.topAnchor.constraint(equalTo: sendButtonContainer.topAnchor, constant: 25)
        ])
        
        // Bottom Spacer
        let bottomSpacer = UIView()
        bottomSpacer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bottomSpacer)
        
        NSLayoutConstraint.activate([
            bottomSpacer.topAnchor.constraint(equalTo: productsStackView.bottomAnchor, constant: 24),
            bottomSpacer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bottomSpacer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bottomSpacer.heightAnchor.constraint(equalToConstant: 120),
            bottomSpacer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    private func setupBindings() {
        viewModel.onSendingStateChanged = { [weak self] isSending in
            DispatchQueue.main.async {
                self?.sendButton.isEnabled = !isSending
                if isSending {
                    self?.showLoading()
                } else {
                    self?.hideLoading()
                }
            }
        }
        
        viewModel.onError = { [weak self] errorMessage in
            DispatchQueue.main.async {
                self?.showErrorAlert(message: errorMessage)
            }
        }
        
        viewModel.onSuccess = { [weak self] in
            DispatchQueue.main.async {
                self?.showSuccessAlert()
            }
        }
    }
    
    private func setupSendButton() {
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Camera Setup
    private func setupCamera() {
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if (captureSession?.canAddInput(videoInput) == true) {
            captureSession?.addInput(videoInput)
        } else {
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (captureSession?.canAddOutput(metadataOutput) == true) {
            captureSession?.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        previewLayer?.frame = view.layer.bounds
        previewLayer?.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer!)
        
        // QR kod kılavuz görünümü
        view.addSubview(qrGuideView)
        qrGuideView.addSubview(qrGuideLabel)
        
        // QR kod çerçevesi
        qrCodeFrameView = UIView()
        if let qrCodeFrameView = qrCodeFrameView {
            qrCodeFrameView.translatesAutoresizingMaskIntoConstraints = false
            qrCodeFrameView.backgroundColor = .clear
            qrGuideView.addSubview(qrCodeFrameView)
            
            // Köşe işaretleri
            let cornerSize: CGFloat = 35
            let cornerThickness: CGFloat = 6
            
            // Sol üst köşe
            let topLeftCorner = createCornerView(size: cornerSize, thickness: cornerThickness, position: .topLeft)
            topLeftCorner.translatesAutoresizingMaskIntoConstraints = false
            qrCodeFrameView.addSubview(topLeftCorner)
            
            // Sağ üst köşe
            let topRightCorner = createCornerView(size: cornerSize, thickness: cornerThickness, position: .topRight)
            topRightCorner.translatesAutoresizingMaskIntoConstraints = false
            qrCodeFrameView.addSubview(topRightCorner)
            
            // Sol alt köşe
            let bottomLeftCorner = createCornerView(size: cornerSize, thickness: cornerThickness, position: .bottomLeft)
            bottomLeftCorner.translatesAutoresizingMaskIntoConstraints = false
            qrCodeFrameView.addSubview(bottomLeftCorner)
            
            // Sağ alt köşe
            let bottomRightCorner = createCornerView(size: cornerSize, thickness: cornerThickness, position: .bottomRight)
            bottomRightCorner.translatesAutoresizingMaskIntoConstraints = false
            qrCodeFrameView.addSubview(bottomRightCorner)
            
            // Kılavuz görünümü için constraint'ler
            NSLayoutConstraint.activate([
                qrGuideView.topAnchor.constraint(equalTo: view.topAnchor),
                qrGuideView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                qrGuideView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                qrGuideView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                
                qrGuideLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
                qrGuideLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                qrGuideLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                
                qrCodeFrameView.centerXAnchor.constraint(equalTo: qrGuideView.centerXAnchor),
                qrCodeFrameView.centerYAnchor.constraint(equalTo: qrGuideView.centerYAnchor),
                qrCodeFrameView.widthAnchor.constraint(equalTo: qrGuideView.widthAnchor, multiplier: 0.5),
                qrCodeFrameView.heightAnchor.constraint(equalTo: qrCodeFrameView.widthAnchor),
                
                // Köşe işaretleri için constraint'ler
                topLeftCorner.topAnchor.constraint(equalTo: qrCodeFrameView.topAnchor, constant: -cornerThickness),
                topLeftCorner.leadingAnchor.constraint(equalTo: qrCodeFrameView.leadingAnchor, constant: -cornerThickness),
                topLeftCorner.widthAnchor.constraint(equalToConstant: cornerSize),
                topLeftCorner.heightAnchor.constraint(equalToConstant: cornerSize),
                
                topRightCorner.topAnchor.constraint(equalTo: qrCodeFrameView.topAnchor, constant: -cornerThickness),
                topRightCorner.trailingAnchor.constraint(equalTo: qrCodeFrameView.trailingAnchor, constant: cornerThickness),
                topRightCorner.widthAnchor.constraint(equalToConstant: cornerSize),
                topRightCorner.heightAnchor.constraint(equalToConstant: cornerSize),
                
                bottomLeftCorner.bottomAnchor.constraint(equalTo: qrCodeFrameView.bottomAnchor, constant: cornerThickness),
                bottomLeftCorner.leadingAnchor.constraint(equalTo: qrCodeFrameView.leadingAnchor, constant: -cornerThickness),
                bottomLeftCorner.widthAnchor.constraint(equalToConstant: cornerSize),
                bottomLeftCorner.heightAnchor.constraint(equalToConstant: cornerSize),
                
                bottomRightCorner.bottomAnchor.constraint(equalTo: qrCodeFrameView.bottomAnchor, constant: cornerThickness),
                bottomRightCorner.trailingAnchor.constraint(equalTo: qrCodeFrameView.trailingAnchor, constant: cornerThickness),
                bottomRightCorner.widthAnchor.constraint(equalToConstant: cornerSize),
                bottomRightCorner.heightAnchor.constraint(equalToConstant: cornerSize)
            ])
        }
        
        // AVCaptureSession'ı background thread'de başlat
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }
    
    private func createCornerView(size: CGFloat, thickness: CGFloat, position: CornerPosition) -> UIView {
        let cornerView = UIView()
        cornerView.backgroundColor = .clear
        
        // Yatay çizgi
        let horizontalLine = UIView()
        horizontalLine.backgroundColor = .white
        horizontalLine.translatesAutoresizingMaskIntoConstraints = false
        cornerView.addSubview(horizontalLine)
        
        // Dikey çizgi
        let verticalLine = UIView()
        verticalLine.backgroundColor = .white
        verticalLine.translatesAutoresizingMaskIntoConstraints = false
        cornerView.addSubview(verticalLine)
        
        switch position {
        case .topLeft:
            NSLayoutConstraint.activate([
                horizontalLine.topAnchor.constraint(equalTo: cornerView.topAnchor),
                horizontalLine.leadingAnchor.constraint(equalTo: cornerView.leadingAnchor),
                horizontalLine.trailingAnchor.constraint(equalTo: cornerView.trailingAnchor),
                horizontalLine.heightAnchor.constraint(equalToConstant: thickness),
                
                verticalLine.topAnchor.constraint(equalTo: cornerView.topAnchor),
                verticalLine.leadingAnchor.constraint(equalTo: cornerView.leadingAnchor),
                verticalLine.bottomAnchor.constraint(equalTo: cornerView.bottomAnchor),
                verticalLine.widthAnchor.constraint(equalToConstant: thickness)
            ])
        case .topRight:
            NSLayoutConstraint.activate([
                horizontalLine.topAnchor.constraint(equalTo: cornerView.topAnchor),
                horizontalLine.leadingAnchor.constraint(equalTo: cornerView.leadingAnchor),
                horizontalLine.trailingAnchor.constraint(equalTo: cornerView.trailingAnchor),
                horizontalLine.heightAnchor.constraint(equalToConstant: thickness),
                
                verticalLine.topAnchor.constraint(equalTo: cornerView.topAnchor),
                verticalLine.trailingAnchor.constraint(equalTo: cornerView.trailingAnchor),
                verticalLine.bottomAnchor.constraint(equalTo: cornerView.bottomAnchor),
                verticalLine.widthAnchor.constraint(equalToConstant: thickness)
            ])
        case .bottomLeft:
            NSLayoutConstraint.activate([
                horizontalLine.bottomAnchor.constraint(equalTo: cornerView.bottomAnchor),
                horizontalLine.leadingAnchor.constraint(equalTo: cornerView.leadingAnchor),
                horizontalLine.trailingAnchor.constraint(equalTo: cornerView.trailingAnchor),
                horizontalLine.heightAnchor.constraint(equalToConstant: thickness),
                
                verticalLine.topAnchor.constraint(equalTo: cornerView.topAnchor),
                verticalLine.leadingAnchor.constraint(equalTo: cornerView.leadingAnchor),
                verticalLine.bottomAnchor.constraint(equalTo: cornerView.bottomAnchor),
                verticalLine.widthAnchor.constraint(equalToConstant: thickness)
            ])
        case .bottomRight:
            NSLayoutConstraint.activate([
                horizontalLine.bottomAnchor.constraint(equalTo: cornerView.bottomAnchor),
                horizontalLine.leadingAnchor.constraint(equalTo: cornerView.leadingAnchor),
                horizontalLine.trailingAnchor.constraint(equalTo: cornerView.trailingAnchor),
                horizontalLine.heightAnchor.constraint(equalToConstant: thickness),
                
                verticalLine.topAnchor.constraint(equalTo: cornerView.topAnchor),
                verticalLine.trailingAnchor.constraint(equalTo: cornerView.trailingAnchor),
                verticalLine.bottomAnchor.constraint(equalTo: cornerView.bottomAnchor),
                verticalLine.widthAnchor.constraint(equalToConstant: thickness)
            ])
        }
        
        return cornerView
    }
    
    private enum CornerPosition {
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
    }
    
    private func showLoading() {
        UIView.animate(withDuration: 0.3) {
            self.blurView.alpha = 1
        }
        loadingIndicator.startAnimating()
    }
    
    private func hideLoading() {
        UIView.animate(withDuration: 0.3) {
            self.blurView.alpha = 0
        }
        loadingIndicator.stopAnimating()
    }
    
    // MARK: - Actions
    @objc private func sendButtonTapped() {
        setupCamera()
    }
    
    private func handleQRCode(_ code: String) {
        // QR kod formatını kontrol et (ip:port)
        let components = code.components(separatedBy: ":")
        guard components.count == 2,
              let port = Int(components[1]),
              port > 0 && port < 65536 else {
            showErrorAlert(message: "Geçersiz QR kod formatı. Lütfen doğru formatta bir QR kod okutun.")
            return
        }
        
        let ip = components[0]
        showLoading()
        
        // TCP bağlantısı kur ve veriyi gönder
        viewModel.sendDespatch(to: ip, port: port) { [weak self] result in
            DispatchQueue.main.async {
                self?.hideLoading()
                
                switch result {
                case .success:
                    self?.showSuccessAlert()
                case .failure(let error):
                    self?.showErrorAlert(message: error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Configuration
    private func configureWithDespatch() {
        let info = viewModel.getDespatchInfo()
        titleValueLabel.text = info.title
        numberValueLabel.text = info.invoiceNumber
        
        // Ürünleri temizle
        productsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Ürünleri ekle
        let products = viewModel.getProducts()
        for product in products {
            let productView = createProductView(name: product.name, serialNumbers: product.serialNumbers)
            productsStackView.addArrangedSubview(productView)
        }
    }
    
    private func createProductView(name: String, serialNumbers: [String]) -> UIView {
        let container = UIView()
        container.backgroundColor = .white
        container.layer.cornerRadius = 10
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.08
        container.layer.shadowOffset = CGSize(width: 0, height: 2)
        container.layer.shadowRadius = 8
        
        let nameLabel = UILabel()
        nameLabel.text = name
        nameLabel.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let countLabel = UILabel()
        countLabel.text = "\(serialNumbers.count) adet seri numarası tanımlı"
        countLabel.font = UIFont.systemFont(ofSize: 13)
        countLabel.textColor = .systemGray
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let serialNumbersLabel = UILabel()
        serialNumbersLabel.text = serialNumbers.joined(separator: "\n")
        serialNumbersLabel.font = UIFont.systemFont(ofSize: 15)
        serialNumbersLabel.textColor = .darkGray
        serialNumbersLabel.numberOfLines = 0
        serialNumbersLabel.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(nameLabel)
        container.addSubview(countLabel)
        container.addSubview(serialNumbersLabel)
        
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            
            countLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            countLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            countLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            
            serialNumbersLabel.topAnchor.constraint(equalTo: countLabel.bottomAnchor, constant: 12),
            serialNumbersLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 32),
            serialNumbersLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            serialNumbersLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
        ])
        
        return container
    }
    
    // MARK: - Alerts
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "Hata",
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Tamam", style: .default))
        present(alert, animated: true)
    }
    
    private func showSuccessAlert() {
        let alert = UIAlertController(
            title: "Başarılı",
            message: "İrsaliye başarıyla gönderildi.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Tamam", style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        
        present(alert, animated: true)
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate
extension SendDespatchViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            // QR kodu bulunduğunda kamerayı durdur
            captureSession?.stopRunning()
            previewLayer?.removeFromSuperlayer()
            qrCodeFrameView?.removeFromSuperview()
            
            // QR kod verisini işle
            handleQRCode(stringValue)
        }
    }
} 
