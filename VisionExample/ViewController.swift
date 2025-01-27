import UIKit
import AVFoundation
import Speech
import MLKitTextRecognition
import MLKitVision

class ViewController: UIViewController {
    
    // MARK: - UI Elements
    
    private let zoomBarImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "zoombar"))
        iv.contentMode = .scaleToFill
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let zoomSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 1.0
        slider.maximumValue = 5.0
        slider.value = 1.0
        
        let thumbImage = UIImage(named: "zoomslider")
        slider.setThumbImage(thumbImage, for: .normal)
        slider.setThumbImage(thumbImage, for: .highlighted)
        
        slider.minimumTrackTintColor = .clear
        slider.maximumTrackTintColor = .clear
        
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()
    
    // MARK: - Properties
    
    private var dingPlayer: AVAudioPlayer?
    private var dongPlayer: AVAudioPlayer?
    private var audioPlayer: AVAudioPlayer?
    private var beepPlayer: AVAudioPlayer?
    
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var textRecognizer: TextRecognizer!
    private var photoOutput = AVCapturePhotoOutput()
    
    private var searchText: String = ""
    private var isSearching: Bool = false
    private var hasSpoken: Bool = false
    
    private let overlayView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.layer.borderColor = UIColor.green.cgColor
        v.layer.borderWidth = 3
        v.isHidden = true
        return v
    }()
    
    private let textField: UITextField = {
        let tf = UITextField()
        tf.placeholder = NSLocalizedString("search", comment: "Placeholder for text entry")
        tf.borderStyle = .roundedRect
        tf.returnKeyType = .done
        tf.backgroundColor = .white // Explicitly set the background color
        tf.textColor = .black       // Explicitly set the text color
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let micButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "microphone"), for: .normal)
        btn.contentMode = .scaleAspectFit
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.accessibilityLabel = NSLocalizedString("microphone_button", comment: "Accessibility label for microphone button")
        return btn
    }()
    
    private let scanButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "scan"), for: .normal)
        btn.contentMode = .scaleAspectFit
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let cameraButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "camera"), for: .normal)
        btn.contentMode = .scaleAspectFit
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let snapshotImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = .black
        iv.isHidden = true
        iv.isUserInteractionEnabled = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let backButton: UIButton = {
        let btn = UIButton(type: .system)
        let image = UIImage(named: "return")
        btn.setImage(image, for: .normal)
        btn.imageView?.contentMode = .scaleAspectFit
        btn.tintColor = .white
        btn.isHidden = true
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let torchButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "torch"), for: .normal)
        btn.contentMode = .scaleAspectFit
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.accessibilityLabel = NSLocalizedString("torch_button", comment: "Accessibility label for torch button")
        return btn
    }()
    
    private let settingsButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "setting"), for: .normal)
        btn.contentMode = .scaleAspectFit
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.accessibilityLabel = NSLocalizedString("settings_button", comment: "Accessibility label for settings button")
        return btn
    }()
    
    private let speechSynthesizer = AVSpeechSynthesizer()
    private let speechRecognizer: SFSpeechRecognizer? = {
        let locale = Locale.current
        return SFSpeechRecognizer(locale: locale)
    }()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // Debounce Timer to Prevent Multiple Beeps
    private var beepDebounceTimer: Timer?
    
    // MARK: - Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("View will appear - resetting speech recognition")
        recognitionTask?.cancel()
        recognitionTask = nil
        audioEngine.stop()
        audioEngine.reset()
        
        micButton.setImage(UIImage(named: "microphone"), for: .normal)
        micButton.backgroundColor = .clear
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        setupCamera()
        setupTextRecognizer()
        setupUI()
        addGesturesToSnapshot()
        
        textField.delegate = self
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(notification:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(notification:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleSnapshotViewDismissed),
                                               name: NSNotification.Name("SnapshotViewDismissed"),
                                               object: nil)
        
        setupAudioPlayers() // Setup sonar and beep players
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Audio Players Setup
    private func setupAudioPlayers() {
        
        if let dingURL = Bundle.main.url(forResource: "ding", withExtension: "mp3") {
                do {
                    dingPlayer = try AVAudioPlayer(contentsOf: dingURL)
                    dingPlayer?.prepareToPlay()
                } catch {
                    print("Error initializing ding audio: \(error)")
                }
            }
            
            if let dongURL = Bundle.main.url(forResource: "dong", withExtension: "mp3") {
                do {
                    dongPlayer = try AVAudioPlayer(contentsOf: dongURL)
                    dongPlayer?.prepareToPlay()
                } catch {
                    print("Error initializing dong audio: \(error)")
                }
            }
        
        if let sonarURL = Bundle.main.url(forResource: "sonar", withExtension: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: sonarURL)
                audioPlayer?.numberOfLoops = -1
                audioPlayer?.prepareToPlay()
            } catch {
                print("Error initializing sonar audio: \(error)")
            }
        }
        
        if let beepURL = Bundle.main.url(forResource: "beep", withExtension: "mp3") {
            do {
                beepPlayer = try AVAudioPlayer(contentsOf: beepURL)
                beepPlayer?.prepareToPlay()
            } catch {
                print("Error initializing beep audio: \(error)")
            }
        }
    }
    
    @objc private func handleSnapshotViewDismissed() {
        DispatchQueue.global(qos: .userInitiated).async {
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
        }
    }
    
    // MARK: - Keyboard Handling
    @objc private func keyboardWillShow(notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let keyboardTop = view.frame.height - keyboardFrame.height
        let textFieldBottom = textField.convert(textField.bounds, to: view).maxY
        if textFieldBottom > keyboardTop {
            let overlap = textFieldBottom - keyboardTop + 30
            self.view.frame.origin.y = -overlap
        }
    }
    
    @objc private func keyboardWillHide(notification: Notification) {
        self.view.frame.origin.y = 0
    }
    
    // MARK: - Query Validation
    private func showToast(message: String, duration: TimeInterval = 2.0) {
        let toastLabel = UILabel()
        toastLabel.text = message
        toastLabel.textColor = .white
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textAlignment = .center
        toastLabel.font = UIFont.systemFont(ofSize: 14)
        toastLabel.alpha = 0.0
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds  = true
        
        let textSize = toastLabel.intrinsicContentSize
        let labelWidth = min(view.frame.width - 40, textSize.width + 20)
        let labelHeight = textSize.height + 10
        toastLabel.frame = CGRect(x: (view.frame.width - labelWidth) / 2,
                                  y: view.frame.height - labelHeight - 80,
                                  width: labelWidth,
                                  height: labelHeight)
        
        view.addSubview(toastLabel)
        
        UIView.animate(withDuration: 0.5, animations: {
            toastLabel.alpha = 1.0
        }) { _ in
            UIView.animate(withDuration: 0.5, delay: duration, options: .curveEaseOut, animations: {
                toastLabel.alpha = 0.0
            }, completion: { _ in
                toastLabel.removeFromSuperview()
            })
        }
    }
    
    // MARK: - Camera Setup
    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high
        guard let device = AVCaptureDevice.default(for: .video) else { fatalError("No camera device found.") }
        guard let videoInput = try? AVCaptureDeviceInput(device: device) else { fatalError("Can't create camera input.") }
        if captureSession.canAddInput(videoInput) { captureSession.addInput(videoInput) }
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = [ kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA ]
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "cameraQueue"))
        if captureSession.canAddOutput(videoOutput) { captureSession.addOutput(videoOutput) }
        
        if captureSession.canAddOutput(photoOutput) { captureSession.addOutput(photoOutput) }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        
        view.addSubview(overlayView)
        DispatchQueue.global(qos: .userInitiated).async { self.captureSession.startRunning() }
    }
    
    private func setupTextRecognizer() {
        let options = TextRecognizerOptions()
        textRecognizer = TextRecognizer.textRecognizer(options: options)
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.addSubview(cameraButton)
        view.addSubview(scanButton)
        view.addSubview(textField)
        view.addSubview(micButton)
        view.addSubview(snapshotImageView)
        view.addSubview(backButton)
        view.addSubview(zoomSlider)
        view.addSubview(torchButton)
        view.addSubview(settingsButton)
        view.addSubview(zoomBarImageView)
        view.bringSubviewToFront(zoomSlider)
        
        // Revised scanButton targets for press-and-hold
        scanButton.addTarget(self, action: #selector(scanTouchDown), for: .touchDown)
        scanButton.addTarget(self, action: #selector(scanTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        
        cameraButton.addTarget(self, action: #selector(cameraButtonTapped), for: .touchUpInside)
        backButton.addTarget(self, action: #selector(resetSearch), for: .touchUpInside)
        zoomSlider.addTarget(self, action: #selector(handleZoomSliderChanged), for: .valueChanged)
        torchButton.addTarget(self, action: #selector(toggleTorch), for: .touchUpInside)
        micButton.addTarget(self, action: #selector(handleMicTapped), for: .touchUpInside)
        settingsButton.addTarget(self, action: #selector(openInfoScreen), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            scanButton.bottomAnchor.constraint(equalTo: textField.topAnchor, constant: -10),
            scanButton.trailingAnchor.constraint(equalTo: cameraButton.leadingAnchor, constant: -16),
            scanButton.widthAnchor.constraint(equalToConstant: 60),
            scanButton.heightAnchor.constraint(equalToConstant: 60),
            
            cameraButton.bottomAnchor.constraint(equalTo: textField.topAnchor, constant: -10),
            cameraButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 32),
            cameraButton.widthAnchor.constraint(equalToConstant: 60),
            cameraButton.heightAnchor.constraint(equalToConstant: 60),
            
            textField.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            textField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textField.trailingAnchor.constraint(equalTo: micButton.leadingAnchor, constant: -8),
            textField.heightAnchor.constraint(equalToConstant: 44),
            
            micButton.centerYAnchor.constraint(equalTo: textField.centerYAnchor),
            micButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            micButton.widthAnchor.constraint(equalToConstant: 44),
            micButton.heightAnchor.constraint(equalToConstant: 44),
            
            snapshotImageView.topAnchor.constraint(equalTo: view.topAnchor),
            snapshotImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            snapshotImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            snapshotImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            backButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            backButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 100),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            zoomBarImageView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -8),
            zoomBarImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            zoomBarImageView.widthAnchor.constraint(equalToConstant: 44),
            zoomBarImageView.heightAnchor.constraint(equalToConstant: 200),
            
            zoomSlider.centerXAnchor.constraint(equalTo: zoomBarImageView.centerXAnchor),
            zoomSlider.centerYAnchor.constraint(equalTo: zoomBarImageView.centerYAnchor),
            zoomSlider.widthAnchor.constraint(equalTo: zoomBarImageView.heightAnchor),
            zoomSlider.heightAnchor.constraint(equalToConstant: 22),
            
            settingsButton.topAnchor.constraint(equalTo: torchButton.bottomAnchor, constant: 16),
            settingsButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            settingsButton.widthAnchor.constraint(equalToConstant: 60),
            settingsButton.heightAnchor.constraint(equalToConstant: 60),
            
            torchButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            torchButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            torchButton.widthAnchor.constraint(equalToConstant: 60),
            torchButton.heightAnchor.constraint(equalToConstant: 60),
        ])
        zoomSlider.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
    }
    
    @objc private func openInfoScreen() {
        let infoVC = InfoViewController()
        infoVC.view.backgroundColor = .white
        infoVC.modalPresentationStyle = .fullScreen
        present(infoVC, animated: true, completion: nil)
    }
    
    // MARK: - Revised Scan Button Actions
    
    @objc private func scanTouchDown() {
        // Validate input text
        guard let inputText = textField.text, !inputText.trimmingCharacters(in: .whitespaces).isEmpty else {
            let utterance = AVSpeechUtterance(string: NSLocalizedString("please_enter_query", comment: "Prompt to enter a query"))
            if let voice = AVSpeechSynthesisVoice(language: currentLanguageCode()) {
                utterance.voice = voice
            }
            speechSynthesizer.speak(utterance)
            showToast(message: NSLocalizedString("please_enter_query", comment: "Prompt to enter a query"))
            return
        }
        
        searchText = inputText
        isSearching = true
        hasSpoken = false
        overlayView.isHidden = true
        snapshotImageView.isHidden = true
        textField.resignFirstResponder()
        
        audioPlayer?.play()  // Start sonar sound
        
        print("Started scanning for: \(searchText)")
    }
    
    @objc private func scanTouchUp() {
        // Stop sonar sound and scanning
        audioPlayer?.stop()
        isSearching = false  // Stop scanning to prevent further beeps
        
        // Take snapshot on release
        cameraButtonTapped()
    }
    
    @objc private func cameraButtonTapped() {
        // Validate input text before capturing photo
        guard let currentText = textField.text, !currentText.trimmingCharacters(in: .whitespaces).isEmpty else {
            let utterance = AVSpeechUtterance(string: NSLocalizedString("please_enter_query", comment: "Prompt to enter a query"))
            if let voice = AVSpeechSynthesisVoice(language: currentLanguageCode()) {
                utterance.voice = voice
            }
            speechSynthesizer.speak(utterance)
            showToast(message: NSLocalizedString("please_enter_query", comment: "Prompt to enter a query"))
            return
        }
        
        searchText = currentText
        hasSpoken = false
        
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    @objc private func resetSearch() {
        audioPlayer?.stop()
        
        snapshotImageView.isHidden = true
        backButton.isHidden = true
        textField.isHidden = false
        scanButton.isHidden = false
        cameraButton.isHidden = false
        zoomSlider.isHidden = false
        torchButton.isHidden = false
        micButton.isHidden = false
        settingsButton.isHidden = false
        overlayView.isHidden = true
        
        isSearching = false
        hasSpoken = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
            }
        }
    }
    
    @objc private func handleZoomSliderChanged() {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = CGFloat(zoomSlider.value)
            device.unlockForConfiguration()
        } catch {
            print("Zoom error: \(error)")
        }
    }
    
    @objc private func toggleTorch() {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else {
            print("Torch not available.")
            return
        }
        do {
            try device.lockForConfiguration()
            if device.torchMode == .on {
                device.torchMode = .off
                torchButton.setImage(UIImage(named: "torch"), for: .normal)
            } else {
                try device.setTorchModeOn(level: 1.0)
                torchButton.setImage(UIImage(named: "torchOn"), for: .normal)
            }
            device.unlockForConfiguration()
        } catch {
            print("Torch error: \(error)")
        }
    }
    
    // MARK: - Helper Function for Current Language Code
    private func currentLanguageCode() -> String {
        let locale = Locale.current
        // Prefer language code and region code if available
        if let languageCode = locale.languageCode, let regionCode = locale.regionCode {
            return "\(languageCode)-\(regionCode)"
        }
        return locale.identifier
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension ViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error)")
            return
        }
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            return
        }
        
        DispatchQueue.main.async {
            let snapshotVC = SnapshotViewController(image: image, searchTerm: self.searchText)
            snapshotVC.modalPresentationStyle = .fullScreen
            self.present(snapshotVC, animated: true, completion: nil)
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard isSearching else { return }
        
        let visionImage = VisionImage(buffer: sampleBuffer)
        visionImage.orientation = .right
        
        textRecognizer.process(visionImage) { [weak self] result, error in
            guard let self = self, self.isSearching else { return }
            if let err = error {
                print("Live feed text recognition error: \(err)")
                return
            }
            guard let result = result else { return }
            
            for block in result.blocks {
                for line in block.lines {
                    // Check if the entire line contains the searchText
                    if line.text.range(of: self.searchText, options: .caseInsensitive) != nil {
                        DispatchQueue.main.async {
                            self.highlightLiveBox(line.frame)
                            
                            // Play beep like a metal detector with debounce
                            if self.beepDebounceTimer == nil {
                                self.beepPlayer?.play()
                                self.beepDebounceTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
                                    self.beepDebounceTimer = nil
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func highlightLiveBox(_ frame: CGRect) {
        let convertedFrame = previewLayer.layerRectConverted(fromMetadataOutputRect: frame)
        overlayView.frame = convertedFrame
        overlayView.isHidden = false
    }
    
    private func uiImageFromSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> UIImage? {
        guard let pxBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: pxBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage, scale: 1.0, orientation: .right)
    }
}

// MARK: - Gestures for Snapshot
extension ViewController {
    private func addGesturesToSnapshot() {
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
        let pan   = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        snapshotImageView.addGestureRecognizer(pinch)
        snapshotImageView.addGestureRecognizer(pan)
    }
    
    @objc private func handlePinchGesture(_ gesture: UIPinchGestureRecognizer) {
        guard let viewToTransform = gesture.view else { return }
        if gesture.state == .began || gesture.state == .changed {
            viewToTransform.transform = viewToTransform.transform.scaledBy(x: gesture.scale, y: gesture.scale)
            gesture.scale = 1
        }
    }
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        if let viewToMove = gesture.view {
            viewToMove.center = CGPoint(x: viewToMove.center.x + translation.x, y: viewToMove.center.y + translation.y)
        }
        gesture.setTranslation(.zero, in: view)
    }
}

// MARK: - UITextFieldDelegate
extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ tf: UITextField) -> Bool {
        tf.resignFirstResponder()
        
        if let query = tf.text, !query.trimmingCharacters(in: .whitespaces).isEmpty {
            let announcementFormat = NSLocalizedString("searching_for", comment: "Announce search term")
            let announcement = String(format: announcementFormat, query)
            let utterance = AVSpeechUtterance(string: announcement)
            if let voice = AVSpeechSynthesisVoice(language: currentLanguageCode()) {
                utterance.voice = voice
            } else {
                utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            }
            speechSynthesizer.speak(utterance)
        }
        
        return true
    }
}

// MARK: - Speech Recognition
extension ViewController {
    
    @objc private func handleMicTapped() {
        if audioEngine.isRunning {
            stopSpeechRecording()
        } else {
            requestSpeechPermissionAndStartRecording()
        }
    }
    
    private func requestSpeechPermissionAndStartRecording() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            switch authStatus {
            case .authorized:
                DispatchQueue.main.async {
                    self.startSpeechRecording()
                    self.presentTemporaryAlert()
                }
            case .denied, .restricted, .notDetermined:
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: NSLocalizedString("speech_recognition_unavailable_title", comment: "Title for speech recognition alert"),
                                                  message: NSLocalizedString("speech_recognition_unavailable_message", comment: "Message for speech recognition alert"),
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: NSLocalizedString("ok_button", comment: "OK button title"), style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            @unknown default:
                break
            }
        }
    }
    
    private func startSpeechRecording() {
        recognitionTask?.cancel()
        recognitionTask = nil

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .mixWithOthers])
            try audioSession.setActive(true)
            print("Audio session configured for speaker playback.")
        } catch {
            print("Audio session error: \(error)")
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let req = recognitionRequest else { return }

        req.shouldReportPartialResults = true
        let inputNode = audioEngine.inputNode

        recognitionTask = speechRecognizer?.recognitionTask(with: req) { [weak self] result, error in
            guard let self = self else { return }
            if let r = result {
                let bestString = r.bestTranscription.formattedString
                print("Recognized: \(bestString)")
                DispatchQueue.main.async { self.textField.text = bestString }
                
                if r.isFinal {
                    DispatchQueue.main.async {
                        let announcementFormat = NSLocalizedString("searching_for", comment: "Announce search term")
                        let announcement = String(format: announcementFormat, bestString)
                        let utterance = AVSpeechUtterance(string: announcement)
                        if let voice = AVSpeechSynthesisVoice(language: self.currentLanguageCode()) {
                            utterance.voice = voice
                        } else {
                            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                        }
                        self.speechSynthesizer.speak(utterance)
                    }
                    self.stopSpeechRecording()
                }
            }
            if error != nil {
                self.stopSpeechRecording()
            }
        }

        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
            micButton.setImage(UIImage(named: "microphone_active"), for: .normal)
            micButton.backgroundColor = UIColor.red.withAlphaComponent(0.5)
            print("Started recording speech...")
            
            // Play "ding" sound to indicate mic activation
            dingPlayer?.play()
        } catch {
            print("audioEngine start error: \(error)")
        }
    }

    
    private func stopSpeechRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask = nil
        
        // Play "dong" sound to indicate mic deactivation
        dongPlayer?.play()
        
        DispatchQueue.main.async {
            self.micButton.setImage(UIImage(named: "microphone"), for: .normal)
            self.micButton.backgroundColor = .clear
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session reset error: \(error)")
        }
    }

    
    private func presentTemporaryAlert() {
        let listeningMessage = NSLocalizedString("listening", comment: "Listening indicator")
        let alert = UIAlertController(title: nil, message: listeningMessage, preferredStyle: .alert)
        self.present(alert, animated: true, completion: nil)
        
        let listeningDuration: TimeInterval = 5.0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + listeningDuration) {
            self.stopSpeechRecording()
            alert.dismiss(animated: true, completion: nil)
        }
    }
}
