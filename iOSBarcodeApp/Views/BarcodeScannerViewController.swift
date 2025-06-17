import UIKit
import AVFoundation
import SnapKit

enum ScannerPurpose {
    case productName
    case serialNumber
}

class BarcodeScannerViewController: UIViewController {
    
    // MARK: - Properties
    private var viewModel: BarcodeScannerViewModel
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var barcodeOverlayViews: [UIView] = []
    private var notificationTimer: Timer?
    private var parsedQRStrings: [String] = []
    private var isQRSelectionVisible = false
    private var isVibrationEnabled = true
    private var isQRCodeParsingEnabled = true
    private var overlayContainer: UIView?
    var scannerPurpose: ScannerPurpose = .productName
    private var onProductNameScanned: ((String) -> Void)?
    
    // UserDefaults anahtarları
    private let vibrationEnabledKey = "vibrationEnabled"
    private let qrCodeParsingEnabledKey = "qrCodeParsingEnabled"
    
    // QR Parsing modu için enum
    enum QRParsingMode: String {
        case automatic = "automatic"
        case manual = "manual"
    }
    
    // AVCaptureSession işlemlerini yönetmek için özel bir kuyruk
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    
    private var _existingSerialNumbers: [String] = []
    var existingSerialNumbers: [String] {
        get { return _existingSerialNumbers }
        set {
            _existingSerialNumbers = newValue
            viewModel.existingSerialNumbers = newValue
        }
    }
    
    private var _onSerialNumbersScanned: (([String]) -> Void)?
    var onSerialNumbersScanned: (([String]) -> Void)? {
        get { return _onSerialNumbersScanned }
        set {
            _onSerialNumbersScanned = newValue
            viewModel.onSerialNumbersScanned = newValue
        }
    }
    
    // Barkod değerlerini geri döndürmek için closure'lar
    var onProductBarcodeScanned: ((String) -> Void)?
    
    // MARK: - UI Elements
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        let image = UIImage(systemName: "xmark.circle.fill", withConfiguration: config) ?? UIImage()
        button.setImage(image, for: .normal)
        button.tintColor = .white
        return button
    }()
    
    private let settingsButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        let image = UIImage(systemName: "gearshape.fill", withConfiguration: config) ?? UIImage()
        button.setImage(image, for: .normal)
        button.tintColor = .white
        return button
    }()
    
    private let settingsContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.layer.cornerRadius = 20
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.2
        view.layer.shadowOffset = CGSize(width: 0, height: -2)
        view.layer.shadowRadius = 8
        view.isHidden = true
        return view
    }()
    
    private let settingsHandle: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemGray4
        view.layer.cornerRadius = 2.5
        return view
    }()
    
    private let settingsTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Ayarlar"
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .black
        return label
    }()
    
    private let vibrationSwitch: UISwitch = {
        let switchControl = UISwitch()
        switchControl.translatesAutoresizingMaskIntoConstraints = false
        switchControl.onTintColor = .systemBlue
        return switchControl
    }()
    
    private let vibrationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Barkod Okunduğunda Titreşim"
        label.font = .systemFont(ofSize: 16)
        label.textColor = .black
        return label
    }()
    
    private let qrParsingSegmentedControl: UISegmentedControl = {
        let items = ["Otomatik", "Manuel"]
        let control = UISegmentedControl(items: items)
        control.translatesAutoresizingMaskIntoConstraints = false
        control.selectedSegmentIndex = 0
        return control
    }()
    
    private let qrParsingLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "QR Kod Parselleme Modu"
        label.font = .systemFont(ofSize: 16)
        label.textColor = .black
        return label
    }()
    
    private let qrParsingDescriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Otomatik mod Mitsubishi ürünleri için önerilir"
        label.font = .systemFont(ofSize: 12)
        label.textColor = .systemGray
        label.numberOfLines = 0
        return label
    }()
    
    private let scanLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Barkodları görmek için kamerayı yönlendirin"
        label.textColor = .white
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let modeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    private let serialNumberNotificationLabelContainer: UIView = {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        containerView.layer.cornerRadius = 8
        containerView.alpha = 0 // Başlangıçta görünmez
        containerView.isHidden = true // Başlangıçta gizli
        return containerView
    }()
    
    // Notification Label'ı doğrudan erişilebilir hale getirdim
    private let notificationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .black
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textAlignment = .center
        return label
    }()
    
    private let doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Bitti", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .white
        button.layer.cornerRadius = 8
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        return button
    }()
    
    private var settingsContainerHeightConstraint: NSLayoutConstraint?
    private var settingsContainerBottomConstraint: NSLayoutConstraint?
    private var isSettingsOpen = false
    
    private let qrSelectionContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.isHidden = true
        return view
    }()
    
    private let qrSelectionBlurView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .dark)
        let view = UIVisualEffectView(effect: blurEffect)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alpha = 0
        return view
    }()
    
    private let qrSelectionContentContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(named: "MainColor")
        view.layer.cornerRadius = 20
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.2
        view.layer.shadowOffset = CGSize(width: 0, height: -2)
        view.layer.shadowRadius = 8
        return view
    }()
    
    private let qrSelectionCloseButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        let image = UIImage(systemName: "xmark.circle.fill", withConfiguration: config) ?? UIImage()
        button.setImage(image, for: .normal)
        button.tintColor = .white
        return button
    }()
    
    private let qrSelectionTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Okunan QR Verileri"
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .white
        return label
    }()
    
    private let qrSelectionTableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.register(QRSelectionCell.self, forCellReuseIdentifier: "QRSelectionCell")
        return tableView
    }()
    
    // MARK: - Initialization
    init() {
        self.viewModel = BarcodeScannerViewModel()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.viewModel = BarcodeScannerViewModel()
        super.init(coder: coder)
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ViewModel ayarlarını yap
        viewModel.scannerPurpose = scannerPurpose
        viewModel.existingSerialNumbers = existingSerialNumbers
        viewModel.onSerialNumbersScanned = onSerialNumbersScanned
        
        // UI'ı ayarla
        setupUI()
        
        // QR Selection UI'ı ekle
        setupQRSelectionUI()
        
        // Kamera ayarlarını yap
        setupCamera()
        
        // Ana view'a tıklama jesti ekle
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBarcodeTap(_:)))
        view.addGestureRecognizer(tapGesture)
        
        // Kayıtlı ayarları yükle
        loadSettings()
        
        // Mod etiketini güncelle
        updateModeLabel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // ViewModel'e scannerPurpose'i aktar
        viewModel.scannerPurpose = scannerPurpose
        viewModel.existingSerialNumbers = existingSerialNumbers
        
        // Mod etiketini güncelle
        updateModeLabel()
        
        sessionQueue.async {
            if let session = self.viewModel.captureSession, !session.isRunning {
                session.startRunning()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sessionQueue.async {
            if let session = self.viewModel.captureSession, session.isRunning {
                session.stopRunning()
            }
        }
        previewLayer?.removeFromSuperlayer()
        viewModel.stopScanning()
        notificationTimer?.invalidate()
        notificationTimer = nil
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // PreviewLayer'ın çerçevesini güncelle
        if let previewLayer = previewLayer {
            previewLayer.frame = view.layer.bounds
        }
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .black
        
        // UI elemanlarını view'a ekle
        view.addSubview(closeButton)
        view.addSubview(scanLabel)
        view.addSubview(modeLabel)
        view.addSubview(serialNumberNotificationLabelContainer)
        serialNumberNotificationLabelContainer.addSubview(notificationLabel)
        view.addSubview(doneButton)
        
        // Settings container'ı en üstte olacak şekilde ekle
        view.addSubview(settingsContainer)
        settingsContainer.addSubview(settingsHandle)
        settingsContainer.addSubview(settingsTitleLabel)
        settingsContainer.addSubview(vibrationLabel)
        settingsContainer.addSubview(vibrationSwitch)
        settingsContainer.addSubview(qrParsingLabel)
        settingsContainer.addSubview(qrParsingSegmentedControl)
        settingsContainer.addSubview(qrParsingDescriptionLabel)
        view.addSubview(settingsButton)
        
        // Overlay container'ı ekle
        let overlayContainer = UIView()
        overlayContainer.translatesAutoresizingMaskIntoConstraints = false
        overlayContainer.backgroundColor = .clear
        view.addSubview(overlayContainer)
        
        // Overlay container'ı previewLayer'ın üzerine yerleştir
        NSLayoutConstraint.activate([
            overlayContainer.topAnchor.constraint(equalTo: view.topAnchor),
            overlayContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Overlay container'ı diğer UI elemanlarının altına gönder
        view.sendSubviewToBack(overlayContainer)
        
        // Overlay container'ı sakla
        self.overlayContainer = overlayContainer
        
        // Constraint'leri ayarla
        NSLayoutConstraint.activate([
            // Close Button
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),

            // Mode Label
            modeLabel.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            modeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Settings Button
            settingsButton.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            settingsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            settingsButton.widthAnchor.constraint(equalToConstant: 44),
            settingsButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Settings Container
            settingsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            settingsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // Settings Handle
            settingsHandle.topAnchor.constraint(equalTo: settingsContainer.topAnchor, constant: 8),
            settingsHandle.centerXAnchor.constraint(equalTo: settingsContainer.centerXAnchor),
            settingsHandle.widthAnchor.constraint(equalToConstant: 40),
            settingsHandle.heightAnchor.constraint(equalToConstant: 5),
            
            // Settings Title
            settingsTitleLabel.topAnchor.constraint(equalTo: settingsHandle.bottomAnchor, constant: 16),
            settingsTitleLabel.leadingAnchor.constraint(equalTo: settingsContainer.leadingAnchor, constant: 20),
            
            // Vibration Label
            vibrationLabel.topAnchor.constraint(equalTo: settingsTitleLabel.bottomAnchor, constant: 24),
            vibrationLabel.leadingAnchor.constraint(equalTo: settingsContainer.leadingAnchor, constant: 20),
            
            // Vibration Switch
            vibrationSwitch.centerYAnchor.constraint(equalTo: vibrationLabel.centerYAnchor),
            vibrationSwitch.trailingAnchor.constraint(equalTo: settingsContainer.trailingAnchor, constant: -20),
            
            // QR Parsing Label
            qrParsingLabel.topAnchor.constraint(equalTo: vibrationLabel.bottomAnchor, constant: 24),
            qrParsingLabel.leadingAnchor.constraint(equalTo: settingsContainer.leadingAnchor, constant: 20),
            
            // QR Parsing Segmented Control
            qrParsingSegmentedControl.topAnchor.constraint(equalTo: qrParsingLabel.bottomAnchor, constant: 8),
            qrParsingSegmentedControl.leadingAnchor.constraint(equalTo: settingsContainer.leadingAnchor, constant: 20),
            qrParsingSegmentedControl.trailingAnchor.constraint(equalTo: settingsContainer.trailingAnchor, constant: -20),
            
            // QR Parsing Description
            qrParsingDescriptionLabel.topAnchor.constraint(equalTo: qrParsingSegmentedControl.bottomAnchor, constant: 8),
            qrParsingDescriptionLabel.leadingAnchor.constraint(equalTo: settingsContainer.leadingAnchor, constant: 20),
            qrParsingDescriptionLabel.trailingAnchor.constraint(equalTo: settingsContainer.trailingAnchor, constant: -20),
            
            // Scan Label
            scanLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scanLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32),
            scanLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            scanLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            
            // Serial Number Notification Container
            serialNumberNotificationLabelContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            serialNumberNotificationLabelContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
            serialNumberNotificationLabelContainer.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            serialNumberNotificationLabelContainer.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32),
            
            // Notification Label
            notificationLabel.topAnchor.constraint(equalTo: serialNumberNotificationLabelContainer.topAnchor, constant: 8),
            notificationLabel.bottomAnchor.constraint(equalTo: serialNumberNotificationLabelContainer.bottomAnchor, constant: -8),
            notificationLabel.leadingAnchor.constraint(equalTo: serialNumberNotificationLabelContainer.leadingAnchor, constant: 16),
            notificationLabel.trailingAnchor.constraint(equalTo: serialNumberNotificationLabelContainer.trailingAnchor, constant: -16),
            
            // Done Button
            doneButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            doneButton.bottomAnchor.constraint(equalTo: scanLabel.topAnchor, constant: -16),
            doneButton.widthAnchor.constraint(equalToConstant: 250),
            doneButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // Settings Container için dinamik constraint'ler
        settingsContainerHeightConstraint = settingsContainer.heightAnchor.constraint(equalToConstant: 300)
        settingsContainerBottomConstraint = settingsContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 300)
        
        settingsContainerHeightConstraint?.isActive = true
        settingsContainerBottomConstraint?.isActive = true
        
        // Settings container'ı en üstte göster
        view.bringSubviewToFront(settingsContainer)
        
        // Butonlara action'ları ekle
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        doneButton.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        settingsButton.addTarget(self, action: #selector(settingsButtonTapped), for: .touchUpInside)
        
        // Switch ve Segmented Control için action'ları ekle
        vibrationSwitch.addTarget(self, action: #selector(vibrationSwitchChanged), for: .valueChanged)
        qrParsingSegmentedControl.addTarget(self, action: #selector(qrParsingModeChanged), for: .valueChanged)
        
        // Pan gesture ekle
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        settingsContainer.addGestureRecognizer(panGesture)
    }
    
    private func updateModeLabel() {
        switch viewModel.scannerPurpose {
        case .productName:
            modeLabel.text = "Tekli Okuma Modu"
            doneButton.isHidden = true
        case .serialNumber:
            modeLabel.text = "Seri Okuma Modu"
            doneButton.isHidden = false
        }
    }

    private func setupCamera() {
        let authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)

        switch authorizationStatus {
        case .authorized:
            sessionQueue.async {
                self.continueCameraSetup()
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard let self = self else { return }
                guard granted else {
                    DispatchQueue.main.async {
                        self.failedCameraSetup(message: "Kamera erişimi reddedildi. Lütfen ayarlardan izin verin.")
                    }
                    return
                }
                self.sessionQueue.async {
                    self.continueCameraSetup()
                }
            }
        case .denied:
            DispatchQueue.main.async {
                self.failedCameraSetup(message: "Kamera erişimi reddedildi. Lütfen ayarlardan izin verin.")
            }
        case .restricted:
            DispatchQueue.main.async {
                self.failedCameraSetup(message: "Kamera erişimi kısıtlandı. Cihaz kısıtlamalarını kontrol edin.")
            }
        @unknown default:
            DispatchQueue.main.async {
                self.failedCameraSetup(message: "Kamera yetkilendirme durumu bilinmiyor. Lütfen ayarlardan izin verin.")
            }
        }
    }

    private func continueCameraSetup() {
        guard let session = viewModel.setupCaptureSession() else {
            DispatchQueue.main.async {
                self.failedCameraSetup(message: "Kamera kurulumu başarısız oldu.")
            }
            return
        }
        
        // PreviewLayer'ı oluştur ve ayarla
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.layer.bounds
        
        // PreviewLayer'ı view'ın layer'ına ekle
        DispatchQueue.main.async {
            self.view.layer.insertSublayer(previewLayer, at: 0)
            self.previewLayer = previewLayer
        }
        
        // Kamera oturumunu başlat
        sessionQueue.async {
            session.beginConfiguration()
            
            // Metadata output'u ayarla
            if let metadataOutput = session.outputs.first as? AVCaptureMetadataOutput {
                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [
                    .qr,
                    .ean8,
                    .ean13,
                    .pdf417,
                    .code128,
                    .code39,
                    .code93,
                    .upce,
                    .interleaved2of5,
                    .itf14,
                    .aztec,
                    .dataMatrix
                ]
            }
            
            session.commitConfiguration()
            session.startRunning()
            
            // Kamera başlatıldıktan sonra UI güncellemelerini main thread'de yap
            DispatchQueue.main.async {
                if session.isRunning {
                    print("DEBUG: Kamera başarıyla başlatıldı")
                    // PreviewLayer'ın çerçevesini güncelle
                    previewLayer.frame = self.view.layer.bounds
                } else {
                    print("DEBUG: Kamera başlatılamadı")
                    self.failedCameraSetup(message: "Kamera başlatılamadı.")
                }
            }
        }
    }
    
    private func failedCameraSetup(message: String) {
        print("DEBUG: Kamera kurulumu başarısız oldu: \(message)")
        let alert = UIAlertController(title: "Kamera Hatası", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
    
    // MARK: - Actions
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func doneButtonTapped() {
        onSerialNumbersScanned?(viewModel.getScannedSerialNumbers())
        dismiss(animated: true)
    }
    
    @objc private func settingsButtonTapped() {
        toggleSettings()
    }
    
    private func toggleSettings() {
        isSettingsOpen.toggle()
        
        let targetBottom: CGFloat = isSettingsOpen ? 0 : 300
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            self.settingsContainerBottomConstraint?.constant = targetBottom
            self.view.layoutIfNeeded()
        }
        
        settingsContainer.isHidden = false
    }
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        
        switch gesture.state {
        case .changed:
            let newConstant = min(max(translation.y, 0), 300)
            settingsContainerBottomConstraint?.constant = newConstant
            view.layoutIfNeeded()
            
        case .ended:
            let shouldOpen = velocity.y < -500 || (settingsContainerBottomConstraint?.constant ?? 0) < 150
            
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
                self.settingsContainerBottomConstraint?.constant = shouldOpen ? 0 : 300
                self.view.layoutIfNeeded()
            }
            
            isSettingsOpen = shouldOpen
            
        default:
            break
        }
    }
    
    // MARK: - Barcode Detection
    private func handleDetectedBarcodes(_ barcodes: [AVMetadataMachineReadableCodeObject]) {
        // Önceki overlay'leri temizle
        barcodeOverlayViews.forEach { $0.removeFromSuperview() }
        barcodeOverlayViews.removeAll()

        // Yeni barkodları işle
        viewModel.updateDetectedBarcodes(barcodes)

        guard let previewLayer = previewLayer else { return }

        for barcode in barcodes {
            if let transformedObject = previewLayer.transformedMetadataObject(for: barcode) {
                let overlayView = createOverlayView(for: transformedObject.bounds)
                overlayContainer?.addSubview(overlayView)
                barcodeOverlayViews.append(overlayView)
            }
        }
    }
    
    private func createOverlayView(for bounds: CGRect) -> UIView {
        let overlayView = UIView(frame: bounds)
        overlayView.layer.borderColor = UIColor.blue.cgColor
        overlayView.layer.borderWidth = 3 
        overlayView.backgroundColor = UIColor.clear
        overlayView.isUserInteractionEnabled = true
        return overlayView
    }
    
    @objc private func handleBarcodeTap(_ gesture: UITapGestureRecognizer) {
        let tapLocation = gesture.location(in: view)
        let tapPadding: CGFloat = 80 
        
        var selectedBarcode: AVMetadataMachineReadableCodeObject? = nil
        var transformedSelectedObject: AVMetadataObject? = nil
        
        var minDistance: CGFloat = .greatestFiniteMagnitude

        // Yeni bir tane çizmek için mevcut tüm overlay'leri temizle
        barcodeOverlayViews.forEach { $0.removeFromSuperview() }
        barcodeOverlayViews.removeAll()

        for barcode in viewModel.detectedBarcodes {
            if let transformedObject = previewLayer?.transformedMetadataObject(for: barcode) {
                let expandedRect = transformedObject.bounds.insetBy(dx: -tapPadding, dy: -tapPadding)
                
                if expandedRect.contains(tapLocation) {
                    let center = CGPoint(x: transformedObject.bounds.midX, y: transformedObject.bounds.midY)
                    let distance = hypot(tapLocation.x - center.x, tapLocation.y - center.y)
                    
                    if distance < minDistance {
                        minDistance = distance
                        selectedBarcode = barcode
                        transformedSelectedObject = transformedObject
                    }
                }
            }
        }
        
        guard let finalSelectedBarcode = selectedBarcode, 
              let finalTransformedObject = transformedSelectedObject,
              let stringValue = finalSelectedBarcode.stringValue else { 
            return 
        }
        
        // Seçilen barkod için overlay oluştur ve yapılandır
        let selectedOverlayView = createOverlayView(for: finalTransformedObject.bounds)
        view.addSubview(selectedOverlayView)
        barcodeOverlayViews.append(selectedOverlayView)

        // Seçilen çerçeveyi yeşil yap
        selectedOverlayView.layer.borderColor = UIColor.systemGreen.cgColor
        selectedOverlayView.layer.borderWidth = 3
        
        // Seçilen barkodu işle
        handleBarcodeScanned(stringValue, type: finalSelectedBarcode.type)
    }
    
    private func handleBarcodeScanned(_ barcodeValue: String, type: AVMetadataObject.ObjectType) {
        // Barkod değerini kontrol et
        if barcodeValue.isEmpty {
            return
        }
        
        // Titreşim ayarı aktifse titreşim ver
        if UserDefaults.standard.bool(forKey: vibrationEnabledKey) {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        }
        
        // QR kod parselleme modu kontrolü
        if let savedMode = UserDefaults.standard.string(forKey: qrCodeParsingEnabledKey),
           let mode = QRParsingMode(rawValue: savedMode) {
            
            if type == .qr {
                let parsedStrings = parseQRString(barcodeValue)
                
                if mode == .automatic {
                    // Otomatik modda ortadaki stringi al
                    if let middleString = getMiddleString(from: parsedStrings) {
                        if viewModel.scannerPurpose == .serialNumber {
                            if viewModel.isSerialNumberExists(middleString) {
                                showSerialNumberNotification(middleString, isDuplicate: true)
                            } else if viewModel.addSerialNumber(middleString) {
                                showSerialNumberNotification(middleString, isDuplicate: false)
                            }
                        } else {
                            onProductBarcodeScanned?(middleString)
                            dismiss(animated: true)
                        }
                    }
                    return
                } else if mode == .manual && !parsedStrings.isEmpty {
                    // Manuel modda QR kod seçim ekranını göster
                    showQRSelection(with: parsedStrings)
                    return
                }
            }
        }
        
        // Eğer seri numarası tarama modundaysa
        if viewModel.scannerPurpose == .serialNumber {
            if viewModel.isSerialNumberExists(barcodeValue) {
                showSerialNumberNotification(barcodeValue, isDuplicate: true)
            } else if viewModel.addSerialNumber(barcodeValue) {
                showSerialNumberNotification(barcodeValue, isDuplicate: false)
            }
        } else {
            // Ürün barkodu tarama modu
            onProductBarcodeScanned?(barcodeValue)
            dismiss(animated: true)
        }
    }
    
    // Ortadaki stringi bulan yardımcı fonksiyon
    private func getMiddleString(from strings: [String]) -> String? {
        guard !strings.isEmpty else { return nil }
        
        let middleIndex = strings.count / 2
        return strings[middleIndex]
    }
    
    private func showSerialNumberNotification(_ serialNumber: String, isDuplicate: Bool) {
        // Önceki bildirimleri temizle
        notificationTimer?.invalidate()
        serialNumberNotificationLabelContainer.layer.removeAllAnimations()
        serialNumberNotificationLabelContainer.alpha = 0

        if isDuplicate {
            notificationLabel.text = "\(serialNumber) zaten kayıtlı!"
            notificationLabel.textColor = .systemRed
        } else {
            notificationLabel.text = "\(serialNumber) kaydedildi"
            notificationLabel.textColor = .black
        }

        serialNumberNotificationLabelContainer.isHidden = false

        UIView.animate(withDuration: 0.3, animations: {
            self.serialNumberNotificationLabelContainer.alpha = 1
        }) { _ in
            // 2 saniye sonra kaybolması için zamanlayıcıyı başlat
            self.notificationTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
                UIView.animate(withDuration: 0.5, animations: {
                    self?.serialNumberNotificationLabelContainer.alpha = 0
                }) { _ in
                    self?.serialNumberNotificationLabelContainer.isHidden = true
                }
            }
        }
    }
    
    private func loadSettings() {
        // UserDefaults'dan ayarları yükle
        let defaults = UserDefaults.standard
        
        // Eğer ayarlar daha önce kaydedilmemişse varsayılan değerleri ayarla
        if !defaults.bool(forKey: "settingsInitialized") {
            defaults.set(true, forKey: vibrationEnabledKey) // Titreşim varsayılan olarak açık
            defaults.set(QRParsingMode.manual.rawValue, forKey: qrCodeParsingEnabledKey) // QR parselleme varsayılan olarak manuel
            defaults.set(true, forKey: "settingsInitialized")
        }
        
        // Ayarları UI'a yansıt
        vibrationSwitch.isOn = defaults.bool(forKey: vibrationEnabledKey)
        
        if let savedMode = defaults.string(forKey: qrCodeParsingEnabledKey),
           let mode = QRParsingMode(rawValue: savedMode) {
            qrParsingSegmentedControl.selectedSegmentIndex = mode == .automatic ? 0 : 1
        }
    }
    
    @objc private func vibrationSwitchChanged(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: vibrationEnabledKey)
    }
    
    @objc private func qrParsingModeChanged(_ sender: UISegmentedControl) {
        let mode: QRParsingMode = sender.selectedSegmentIndex == 0 ? .automatic : .manual
        UserDefaults.standard.set(mode.rawValue, forKey: qrCodeParsingEnabledKey)
    }
    
    private func parseQRString(_ qrString: String) -> [String] {
        // Boşluk, dolar işareti ve diğer yaygın ayırıcıları kullanarak string'i parçala
        let separators = CharacterSet(charactersIn: " $,;|")
        let components = qrString.components(separatedBy: separators)
        
        // Boş string'leri filtrele ve trim et
        return components
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    private func setupQRSelectionUI() {
        // Container
        view.addSubview(qrSelectionContainer)
        qrSelectionContainer.addSubview(qrSelectionBlurView)
        qrSelectionContainer.addSubview(qrSelectionContentContainer)
        
        // Header view
        let headerView = UIView()
        headerView.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.7)
        qrSelectionContentContainer.addSubview(headerView)
        
        // Close button ve title label
        qrSelectionContainer.addSubview(qrSelectionCloseButton)
        qrSelectionContainer.addSubview(qrSelectionTitleLabel)
        
        // Table view
        qrSelectionContentContainer.addSubview(qrSelectionTableView)
        
        // Constraints
        NSLayoutConstraint.activate([
            // Container
            qrSelectionContainer.topAnchor.constraint(equalTo: view.topAnchor),
            qrSelectionContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            qrSelectionContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            qrSelectionContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Blur View
            qrSelectionBlurView.topAnchor.constraint(equalTo: qrSelectionContainer.topAnchor),
            qrSelectionBlurView.leadingAnchor.constraint(equalTo: qrSelectionContainer.leadingAnchor),
            qrSelectionBlurView.trailingAnchor.constraint(equalTo: qrSelectionContainer.trailingAnchor),
            qrSelectionBlurView.bottomAnchor.constraint(equalTo: qrSelectionContainer.bottomAnchor),
            
            // Content Container
            qrSelectionContentContainer.leadingAnchor.constraint(equalTo: qrSelectionContainer.leadingAnchor),
            qrSelectionContentContainer.trailingAnchor.constraint(equalTo: qrSelectionContainer.trailingAnchor),
            qrSelectionContentContainer.bottomAnchor.constraint(equalTo: qrSelectionContainer.bottomAnchor),
            qrSelectionContentContainer.heightAnchor.constraint(equalTo: qrSelectionContainer.heightAnchor, multiplier: 0.6),
            
            // Header View
            headerView.topAnchor.constraint(equalTo: qrSelectionContentContainer.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: qrSelectionContentContainer.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: qrSelectionContentContainer.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 44),
            
            // Close Button
            qrSelectionCloseButton.topAnchor.constraint(equalTo: qrSelectionContentContainer.topAnchor, constant: -44),
            qrSelectionCloseButton.leadingAnchor.constraint(equalTo: qrSelectionContentContainer.leadingAnchor, constant: 16),
            qrSelectionCloseButton.widthAnchor.constraint(equalToConstant: 44),
            qrSelectionCloseButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Title Label
            qrSelectionTitleLabel.centerYAnchor.constraint(equalTo: qrSelectionCloseButton.centerYAnchor),
            qrSelectionTitleLabel.leadingAnchor.constraint(equalTo: qrSelectionCloseButton.trailingAnchor, constant: 16),
            
            // Table View
            qrSelectionTableView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
            qrSelectionTableView.leadingAnchor.constraint(equalTo: qrSelectionContentContainer.leadingAnchor, constant: 16),
            qrSelectionTableView.trailingAnchor.constraint(equalTo: qrSelectionContentContainer.trailingAnchor, constant: -16),
            qrSelectionTableView.bottomAnchor.constraint(equalTo: qrSelectionContentContainer.bottomAnchor, constant: -16)
        ])
        
        // QR Selection close button action'ı ekle
        qrSelectionCloseButton.addTarget(self, action: #selector(closeQRSelection), for: .touchUpInside)
        
        // QR Selection için delegate ve data source'u ayarla
        qrSelectionTableView.delegate = self
        qrSelectionTableView.dataSource = self
        
        // Initial state
        qrSelectionContainer.isHidden = true
        qrSelectionBlurView.alpha = 0
        
        // İptal butonunun en üstte olmasını sağla
        qrSelectionContainer.bringSubviewToFront(qrSelectionCloseButton)
    }

    private func showQRSelection(with strings: [String]) {
        // Taramayı durdur
        viewModel.stopScanning()
        
        // AVCaptureSession'ı durdur
        sessionQueue.async {
            if let session = self.viewModel.captureSession, session.isRunning {
                session.stopRunning()
            }
        }
        
        // Overlay'leri temizle
        DispatchQueue.main.async {
            self.barcodeOverlayViews.forEach { $0.removeFromSuperview() }
            self.barcodeOverlayViews.removeAll()
        }
        
        // Tıklama kontrolünü devre dışı bırak
        view.gestureRecognizers?.forEach { gesture in
            if gesture is UITapGestureRecognizer {
                gesture.isEnabled = false
            }
        }
        
        parsedQRStrings = strings
        qrSelectionTableView.reloadData()
        
        qrSelectionContainer.isHidden = false
        qrSelectionContentContainer.transform = CGAffineTransform(translationX: 0, y: qrSelectionContentContainer.frame.height)
        qrSelectionCloseButton.transform = CGAffineTransform(translationX: 0, y: qrSelectionContentContainer.frame.height)
        qrSelectionTitleLabel.transform = CGAffineTransform(translationX: 0, y: qrSelectionContentContainer.frame.height)
        
        UIView.animate(withDuration: 0.2) {
            self.qrSelectionBlurView.alpha = 1
            self.qrSelectionContentContainer.transform = .identity
            self.qrSelectionCloseButton.transform = .identity
            self.qrSelectionTitleLabel.transform = .identity
        }
    }
    
    @objc private func closeQRSelection() {
        UIView.animate(withDuration: 0.2, animations: {
            self.qrSelectionBlurView.alpha = 0
            self.qrSelectionContentContainer.transform = CGAffineTransform(translationX: 0, y: self.qrSelectionContentContainer.frame.height)
            self.qrSelectionCloseButton.transform = CGAffineTransform(translationX: 0, y: self.qrSelectionContentContainer.frame.height)
            self.qrSelectionTitleLabel.transform = CGAffineTransform(translationX: 0, y: self.qrSelectionContentContainer.frame.height)
        }) { _ in
            self.qrSelectionContainer.isHidden = true
            self.qrSelectionContentContainer.transform = .identity
            self.qrSelectionCloseButton.transform = .identity
            self.qrSelectionTitleLabel.transform = .identity
            
            // Taramayı tekrar başlat
            self.viewModel.startScanning()
            
            // AVCaptureSession'ı tekrar başlat
            self.sessionQueue.async {
                if let session = self.viewModel.captureSession, !session.isRunning {
                    session.startRunning()
                }
            }
            
            // Tıklama kontrolünü tekrar aktif et
            self.view.gestureRecognizers?.forEach { gesture in
                if gesture is UITapGestureRecognizer {
                    gesture.isEnabled = true
                }
            }
        }
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate
extension BarcodeScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        let barcodes = metadataObjects.compactMap { $0 as? AVMetadataMachineReadableCodeObject }
        
        // UI güncellemelerini main thread'de yap
        DispatchQueue.main.async {
            // Eğer ürün barkodu modundaysak ve bir barkod seçildiyseniz, yeni çerçeveleri çizme
            if self.viewModel.scannerPurpose == .productName && self.viewModel.isScanning {
                self.barcodeOverlayViews.forEach { $0.removeFromSuperview() }
                self.barcodeOverlayViews.removeAll()
                return 
            }

            // Her zaman eski overlay'leri temizle ve yenilerini çiz
            self.barcodeOverlayViews.forEach { $0.removeFromSuperview() }
            self.barcodeOverlayViews.removeAll()

            if !barcodes.isEmpty {
                self.handleDetectedBarcodes(barcodes)
            }
        }
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension BarcodeScannerViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return parsedQRStrings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "QRSelectionCell", for: indexPath) as! QRSelectionCell
        cell.configure(with: parsedQRStrings[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedString = parsedQRStrings[indexPath.row]
        
        // Seçilen string'i işle
        if viewModel.scannerPurpose == .serialNumber {
            if viewModel.isSerialNumberExists(selectedString) {
                showSerialNumberNotification(selectedString, isDuplicate: true)
            } else if viewModel.addSerialNumber(selectedString) {
                showSerialNumberNotification(selectedString, isDuplicate: false)
            }
        } else {
            onProductNameScanned?(selectedString)
            dismiss(animated: true)
        }
        
        closeQRSelection()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

// MARK: - QRSelectionCell
class QRSelectionCell: UITableViewCell {
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        return view
    }()
    
    private let stringLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16)
        label.textColor = .black
        label.numberOfLines = 0
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        isUserInteractionEnabled = true
        
        contentView.addSubview(containerView)
        containerView.addSubview(stringLabel)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            
            stringLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            stringLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            stringLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            stringLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with string: String) {
        stringLabel.text = string
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        UIView.animate(withDuration: 0.2) {
            self.containerView.transform = highlighted ? CGAffineTransform(scaleX: 0.95, y: 0.95) : .identity
            self.containerView.backgroundColor = highlighted ? .systemGray6 : .white
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        setHighlighted(true, animated: true)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        setHighlighted(false, animated: true)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        setHighlighted(false, animated: true)
    }
} 
