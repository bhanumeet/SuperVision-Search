import UIKit
import MLKitTextRecognition
import MLKitVision
import AVFoundation
import Speech

class SnapshotViewController: UIViewController {
    
    // MARK: - Properties
    
    private let originalImage: UIImage
    private var searchTerm: String
    private var individualSearchTerms: [String] = []
    
    // Frames (bounding boxes) of lines that match
    private var frames: [CGRect] = []
    private var currentIndex: Int = 0
    
    private var textRecognizer: TextRecognizer!
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    private var foundSoundPlayer: AVAudioPlayer?  // Property for the "found" sound
    
    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    
    // Navigation Buttons
    private let nextButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "next"), for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let prevButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "pre"), for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let backButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "return"), for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let zoomInButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "zoomIn"), for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    // Search Bar with Mic Button
    private let searchContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let searchTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter or say text"
        tf.borderStyle = .roundedRect
        tf.returnKeyType = .done
        tf.backgroundColor = .white
        tf.textColor = .black
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let micButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "microphone"), for: .normal)
        btn.contentMode = .scaleAspectFit
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    // Audio Players for "ding" and "dong" sounds
    private var dingPlayer: AVAudioPlayer?
    private var dongPlayer: AVAudioPlayer?
    
    // Speech Recognition Properties
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    private var detectedAngle: CGFloat = 0.0
    private var rotatedImage: UIImage?
    
    // Constraint for adjusting searchContainerView when keyboard appears
    private var searchContainerBottomConstraint: NSLayoutConstraint?
    
    // Temporary Alert for Listening Status
    private var listeningAlert: UIAlertController?
    
    // MARK: - Initializer
    
    init(image: UIImage, searchTerm: String) {
        self.originalImage = image
        self.searchTerm = searchTerm
        self.individualSearchTerms = searchTerm.lowercased().split(separator: " ").map { String($0) }
        super.init(nibName: nil, bundle: nil)
        
        let options = TextRecognizerOptions()
        self.textRecognizer = TextRecognizer.textRecognizer(options: options)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        setupScrollView()
        setupSearchBar()    // **Ensure search bar is set up before buttons**
        setupButtons()
        setupAudioPlayers()
        
        // Load "found" sound resource (optional)
        if let foundURL = Bundle.main.url(forResource: "found", withExtension: "mp3") {
            do {
                foundSoundPlayer = try AVAudioPlayer(contentsOf: foundURL)
                foundSoundPlayer?.prepareToPlay()
            } catch {
                print("Error loading found sound: \(error)")
            }
        }
        
        processInitialAngleDetection()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Observe keyboard notifications
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(notification:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(notification:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Remove keyboard notifications
        NotificationCenter.default.removeObserver(self,
                                                  name: UIResponder.keyboardWillShowNotification,
                                                  object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: UIResponder.keyboardWillHideNotification,
                                                  object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Automatically start speech recognition
        // Commented out to prevent automatic mic activation on view load
        // startSpeechRecording()
    }
    
    
    // MARK: - UI Setup
    
    private func setupScrollView() {
        scrollView.frame = view.bounds
        scrollView.backgroundColor = .black
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 10.0
        scrollView.delegate = self
        view.addSubview(scrollView)
        
        imageView.contentMode = .scaleAspectFit
        imageView.frame = scrollView.bounds
        imageView.isUserInteractionEnabled = true
        scrollView.addSubview(imageView)
    }
    
    private func setupButtons() {
        // Add buttons to the view
        view.addSubview(prevButton)
        view.addSubview(nextButton)
        view.addSubview(backButton)
        view.addSubview(zoomInButton)
        
        // Assign actions to buttons
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        prevButton.addTarget(self, action: #selector(prevTapped), for: .touchUpInside)
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        zoomInButton.addTarget(self, action: #selector(zoomInTapped), for: .touchUpInside)
        
        // Set constraints for buttons
        NSLayoutConstraint.activate([
            // Previous Button
            prevButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            prevButton.bottomAnchor.constraint(equalTo: searchContainerView.topAnchor, constant: -20),
            prevButton.widthAnchor.constraint(equalToConstant: 50),
            prevButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Zoom In Button
            zoomInButton.centerXAnchor.constraint(equalTo: prevButton.centerXAnchor),
            zoomInButton.bottomAnchor.constraint(equalTo: prevButton.topAnchor, constant: -30),
            zoomInButton.widthAnchor.constraint(equalToConstant: 70),
            zoomInButton.heightAnchor.constraint(equalToConstant: 70),
            
            // Back Button
            backButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            backButton.bottomAnchor.constraint(equalTo: searchContainerView.topAnchor, constant: -20),
            backButton.widthAnchor.constraint(equalToConstant: 50),
            backButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Next Button
            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            nextButton.bottomAnchor.constraint(equalTo: searchContainerView.topAnchor, constant: -20),
            nextButton.widthAnchor.constraint(equalToConstant: 50),
            nextButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupSearchBar() {
        // Add container view for search bar and mic button
        view.addSubview(searchContainerView)
        
        // Add searchTextField and micButton to the container
        searchContainerView.addSubview(searchTextField)
        searchContainerView.addSubview(micButton)
        
        // Assign delegate and actions
        searchTextField.delegate = self
        micButton.addTarget(self, action: #selector(handleMicTapped), for: .touchUpInside)
        
        // Create and store the bottom constraint
        searchContainerBottomConstraint = searchContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        
        // Activate all constraints
        NSLayoutConstraint.activate([
            // Search Container View Constraints
            searchContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            searchContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            searchContainerBottomConstraint!, // Use the stored constraint
            searchContainerView.heightAnchor.constraint(equalToConstant: 44),
            
            // Search TextField Constraints
            searchTextField.leadingAnchor.constraint(equalTo: searchContainerView.leadingAnchor),
            searchTextField.topAnchor.constraint(equalTo: searchContainerView.topAnchor),
            searchTextField.bottomAnchor.constraint(equalTo: searchContainerView.bottomAnchor),
            searchTextField.trailingAnchor.constraint(equalTo: micButton.leadingAnchor, constant: -8),
            
            // Mic Button Constraints
            micButton.trailingAnchor.constraint(equalTo: searchContainerView.trailingAnchor),
            micButton.centerYAnchor.constraint(equalTo: searchContainerView.centerYAnchor),
            micButton.widthAnchor.constraint(equalToConstant: 44),
            micButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    // MARK: - Audio Players Setup
    private func setupAudioPlayers() {
        // Initialize "ding" player
        if let dingURL = Bundle.main.url(forResource: "ding", withExtension: "mp3") {
            do {
                dingPlayer = try AVAudioPlayer(contentsOf: dingURL)
                dingPlayer?.prepareToPlay()
                print("Ding player initialized.")
            } catch {
                print("Error initializing ding audio: \(error)")
            }
        } else {
            print("ding.mp3 not found in bundle.")
        }
        
        // Initialize "dong" player
        if let dongURL = Bundle.main.url(forResource: "dong", withExtension: "mp3") {
            do {
                dongPlayer = try AVAudioPlayer(contentsOf: dongURL)
                dongPlayer?.prepareToPlay()
                print("Dong player initialized.")
            } catch {
                print("Error initializing dong audio: \(error)")
            }
        } else {
            print("dong.mp3 not found in bundle.")
        }
    }
    
    
    // MARK: - OCR & Angle Detection
    
    func levenshtein(a: String, b: String) -> Int {
        let aCount = a.count
        let bCount = b.count

        if aCount == 0 { return bCount }
        if bCount == 0 { return aCount }

        var matrix = Array(repeating: Array(repeating: 0, count: bCount + 1), count: aCount + 1)

        for i in 0...aCount { matrix[i][0] = i }
        for j in 0...bCount { matrix[0][j] = j }

        for i in 1...aCount {
            for j in 1...bCount {
                let aIndex = a.index(a.startIndex, offsetBy: i - 1)
                let bIndex = b.index(b.startIndex, offsetBy: j - 1)

                if a[aIndex] == b[bIndex] {
                    matrix[i][j] = matrix[i - 1][j - 1]
                } else {
                    let deletion = matrix[i - 1][j] + 1
                    let insertion = matrix[i][j - 1] + 1
                    let substitution = matrix[i - 1][j - 1] + 1
                    matrix[i][j] = min(deletion, insertion, substitution)
                }
            }
        }
        return matrix[aCount][bCount]
    }

    func isPotentialMatch(for text: String, keyword: String) -> Bool {
        let lowercasedText = text.lowercased()
        let lowercasedKeyword = keyword.lowercased()

        // Check for exact match
        if lowercasedText == lowercasedKeyword {
            return true
        }

        // Check for word boundaries for single words
        let pattern = "\\b\(NSRegularExpression.escapedPattern(for: lowercasedKeyword))\\b"
        if lowercasedText.range(of: pattern, options: .regularExpression) != nil {
            return true
        }

        // Use fuzzy matching as fallback
        let distance = levenshtein(a: lowercasedText, b: lowercasedKeyword)
        let ratio = Double(distance) / Double(min(lowercasedText.count, lowercasedKeyword.count))
        return ratio < 0.3
    }


    /// 1) First pass: scan original image, detect angle based on all text elements, rotate the image accordingly.
    private func processInitialAngleDetection() {
        let visionImage = VisionImage(image: originalImage)
        visionImage.orientation = originalImage.imageOrientation

        textRecognizer.process(visionImage) { [weak self] result, error in
            guard let self = self else { return }
            if let error = error {
                print("Initial OCR error: \(error)")
                self.speak("Error in text recognition.")
                return
            }
            guard let result = result else { return }

            print("Initial OCR Result:")
            for block in result.blocks {
                print("Block text: \(block.text)")
                for line in block.lines {
                    print("  Line text: \(line.text)")
                    for element in line.elements {
                        print("    Element text: \(element.text)")
                    }
                }
            }

            // Collect angles from all text elements
            var angles: [CGFloat] = []
            for block in result.blocks {
                for line in block.lines {
                    for element in line.elements {
                        if element.cornerPoints.count >= 2 {
                            let angle = self.getAverageAngle(cornerPoints: element.cornerPoints.map { $0.cgPointValue })
                            angles.append(angle)
                        }
                    }
                }
            }

            if !angles.isEmpty {
                let sum = angles.reduce(0, +)
                self.detectedAngle = sum / CGFloat(angles.count)
                let adjustedAngle = self.detectedAngle + 90

                self.rotatedImage = self.rotateImage(self.originalImage, by: -adjustedAngle)
                guard let rotated = self.rotatedImage else {
                    self.speak("Error rotating image.")
                    return
                }
                DispatchQueue.main.async {
                    self.imageView.image = rotated
                }
                self.processRecognitionOnRotatedImage(rotated)
            } else {
                print("No text found in image.")
                self.speak("No text found in image.")
                // Restore original image if no text is found
                DispatchQueue.main.async {
                    self.imageView.image = self.originalImage
                    self.rotatedImage = nil
                }
            }
        }
    }
    
    /// 2) Second pass: re-run OCR on the rotated image and highlight matches
    private func processRecognitionOnRotatedImage(_ image: UIImage) {
        frames.removeAll()

        let visionImage = VisionImage(image: image)
        visionImage.orientation = .up

        textRecognizer.process(visionImage) { [weak self] result, error in
            guard let self = self else { return }
            if let error = error {
                print("OCR on rotated image error: \(error)")
                self.speak("Error in text recognition after rotation.")
                return
            }
            guard let result = result else { return }

            print("Rotated OCR Result:")
            for block in result.blocks {
                print("Block text: \(block.text)")
                for line in block.lines {
                    print("  Line text: \(line.text)")
                    for element in line.elements {
                        print("    Element text: \(element.text)")
                    }
                }
            }

            self.highlightMatches(on: image, result: result)
        }
    }
    
    private func highlightMatches(on image: UIImage, result: Text) {
        // Remove existing highlight layers
        imageView.layer.sublayers?.forEach { layer in
            if layer is CAShapeLayer { layer.removeFromSuperlayer() }
        }
        frames.removeAll()

        // If searching for multiple words, we need to find adjacent matches
        if individualSearchTerms.count > 1 {
            for block in result.blocks {
                for line in block.lines {
                    // Get all elements in the line
                    let elements = line.elements
                    
                    // Slide through elements looking for consecutive matches
                    var i = 0
                    while i < elements.count - (individualSearchTerms.count - 1) {
                        var matchFound = true
                        var matchingElements = [TextElement]()
                        
                        // Try to match all search terms consecutively
                        for (index, searchTerm) in individualSearchTerms.enumerated() {
                            if i + index >= elements.count ||
                               !isPotentialMatch(for: elements[i + index].text, keyword: searchTerm) {
                                matchFound = false
                                break
                            }
                            matchingElements.append(elements[i + index])
                        }
                        
                        if matchFound && !matchingElements.isEmpty {
                            // Calculate combined bounding box for all matching elements
                            var allPoints: [CGPoint] = []
                            for element in matchingElements {
                                allPoints.append(contentsOf: element.cornerPoints.map { $0.cgPointValue })
                            }
                            
                            let xs = allPoints.map { $0.x }
                            let ys = allPoints.map { $0.y }
                            
                            let minX = xs.min() ?? 0
                            let maxX = xs.max() ?? 0
                            let minY = ys.min() ?? 0
                            let maxY = ys.max() ?? 0
                            
                            let frame = CGRect(x: minX,
                                             y: minY,
                                             width: maxX - minX,
                                             height: maxY - minY)
                            frames.append(frame)
                            
                            // Draw highlight for the combined phrase
                            let scaleWidth = imageView.bounds.width / image.size.width
                            let scaleHeight = imageView.bounds.height / image.size.height
                            let scale = min(scaleWidth, scaleHeight)
                            
                            let imageWidth = image.size.width * scale
                            let imageHeight = image.size.height * scale
                            let imageX = (imageView.bounds.width - imageWidth) / 2.0
                            let imageY = (imageView.bounds.height - imageHeight) / 2.0
                            
                            let underlinePath = UIBezierPath()
                            underlinePath.move(to: CGPoint(x: minX, y: maxY))
                            underlinePath.addLine(to: CGPoint(x: maxX, y: maxY))
                            
                            let blinkLayer = CAShapeLayer()
                            blinkLayer.path = underlinePath.cgPath
                            blinkLayer.strokeColor = UIColor.green.cgColor
                            blinkLayer.lineWidth = 5.0
                            blinkLayer.position = CGPoint(x: imageX, y: imageY)
                            blinkLayer.transform = CATransform3DMakeScale(scale, scale, 1)
                            imageView.layer.addSublayer(blinkLayer)
                            
                            let blinkAnimation = CABasicAnimation(keyPath: "opacity")
                            blinkAnimation.fromValue = 1.0
                            blinkAnimation.toValue = 0.0
                            blinkAnimation.duration = 0.5
                            blinkAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                            blinkAnimation.autoreverses = true
                            blinkAnimation.repeatCount = .infinity
                            blinkLayer.add(blinkAnimation, forKey: "blink")
                            
                            i += individualSearchTerms.count // Skip past all matched words
                        } else {
                            i += 1
                        }
                    }
                }
            }
        } else {
            // Original single-word search logic
            for block in result.blocks {
                for line in block.lines {
                    for element in line.elements {
                        let elementText = element.text.lowercased()
                        for word in individualSearchTerms {
                            if self.isPotentialMatch(for: elementText, keyword: word),
                               element.cornerPoints.count == 4 {
                                let points = element.cornerPoints.map { $0.cgPointValue }
                                let xs = points.map { $0.x }
                                let ys = points.map { $0.y }
                                let minX = xs.min() ?? 0
                                let maxX = xs.max() ?? 0
                                let minY = ys.min() ?? 0
                                let maxY = ys.max() ?? 0
                                
                                let frame = CGRect(x: minX,
                                                 y: minY,
                                                 width: maxX - minX,
                                                 height: maxY - minY)
                                frames.append(frame)
                                
                                // Draw highlight
                                let scaleWidth = imageView.bounds.width / image.size.width
                                let scaleHeight = imageView.bounds.height / image.size.height
                                let scale = min(scaleWidth, scaleHeight)
                                
                                let imageWidth = image.size.width * scale
                                let imageHeight = image.size.height * scale
                                let imageX = (imageView.bounds.width - imageWidth) / 2.0
                                let imageY = (imageView.bounds.height - imageHeight) / 2.0
                                
                                let underlinePath = UIBezierPath()
                                underlinePath.move(to: CGPoint(x: minX, y: maxY))
                                underlinePath.addLine(to: CGPoint(x: maxX, y: maxY))
                                
                                let blinkLayer = CAShapeLayer()
                                blinkLayer.path = underlinePath.cgPath
                                blinkLayer.strokeColor = UIColor.green.cgColor
                                blinkLayer.lineWidth = 5.0
                                blinkLayer.position = CGPoint(x: imageX, y: imageY)
                                blinkLayer.transform = CATransform3DMakeScale(scale, scale, 1)
                                imageView.layer.addSublayer(blinkLayer)
                                
                                let blinkAnimation = CABasicAnimation(keyPath: "opacity")
                                blinkAnimation.fromValue = 1.0
                                blinkAnimation.toValue = 0.0
                                blinkAnimation.duration = 0.5
                                blinkAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                                blinkAnimation.autoreverses = true
                                blinkAnimation.repeatCount = .infinity
                                blinkLayer.add(blinkAnimation, forKey: "blink")
                            }
                        }
                    }
                }
            }
        }

        DispatchQueue.main.async {
            self.imageView.image = image
            self.scrollView.zoomScale = 1.0
            
            if !self.frames.isEmpty {
                self.currentIndex = 0
                let count = self.frames.count
                let message = count == 1 ? "Found one instance of \(self.searchTerm)" :
                                         "Found \(count) instances of \(self.searchTerm)"
                self.foundSoundPlayer?.play()
                self.speak(message)
            } else {
                print("No instances of \(self.searchTerm) found.")
                self.speak("No instances of \(self.searchTerm) found.")
            }
        }
    }
    // Helper function to directly check for substring presence
    private func containsSearchTerm(_ text: String, searchTerm: String) -> Bool {
        let text = text.lowercased().trimmingCharacters(in: .whitespaces)
        let searchTerm = searchTerm.lowercased().trimmingCharacters(in: .whitespaces)
        
        // Direct contains check
        if text.contains(searchTerm) {
            return true
        }
        
        // Check with spaces around for whole word matching
        if text.contains(" \(searchTerm) ") {
            return true
        }
        
        // Levenshtein distance check for fuzzy matching
        return levenshtein(a: text, b: searchTerm) <= 2
    }
    
    //handle mic
    
    @objc private func handleMicTapped() {
        if audioEngine.isRunning {
            stopSpeechRecording() // Stop speech recognition if it's running
        } else {
            requestSpeechPermissionAndStartRecording() // Start speech recognition
        }
    }


    // MARK: - Fuzzy Matching
    
    /// Main fuzzy check for each line or element's text
    /// Adjust `fuzzyThreshold` as needed.
    /// The smaller the threshold, the stricter the match.
    private func isFuzzyMatch(for text: String, searchTerm: String) -> Bool {
        let fuzzyThreshold = 0.2  // e.g., <=20% of min(text.count, searchTerm.count) can differ
        
        let distance = levenshteinDistance(text.lowercased(), searchTerm.lowercased())
        // Compare ratio of distance to the min length
        let ratio = Double(distance) / Double(min(text.count, searchTerm.count))
        return ratio <= fuzzyThreshold
    }
    
    /// Standard Levenshtein distance computation
    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let a = Array(s1), b = Array(s2)
        let m = a.count, n = b.count
        
        // Create a 2D array for dynamic programming
        var dp = [[Int]](repeating: [Int](repeating: 0, count: n + 1), count: m + 1)
        
        for i in 0...m { dp[i][0] = i }
        for j in 0...n { dp[0][j] = j }
        
        for i in 1...m {
            for j in 1...n {
                if a[i - 1] == b[j - 1] {
                    dp[i][j] = dp[i - 1][j - 1]
                } else {
                    dp[i][j] = 1 + min(dp[i - 1][j],     // deletion
                                       dp[i][j - 1],     // insertion
                                       dp[i - 1][j - 1]) // substitution
                }
            }
        }
        return dp[m][n]
    }
    
    
    // MARK: - Angle & Rotation Helpers
    
    private func getAverageAngle(cornerPoints: [CGPoint]) -> CGFloat {
        guard cornerPoints.count >= 2 else { return 0 }
        let p0 = cornerPoints[0]
        let p1 = cornerPoints[1]
        let dx = p1.x - p0.x
        let dy = p1.y - p0.y
        let angleInRadians = atan2(dy, dx)
        return angleInRadians * 180 / .pi
    }
    
    private func rotateImage(_ image: UIImage, by degrees: CGFloat) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        let radians = degrees * (.pi / 180)
        var newSize = CGRect(origin: .zero, size: image.size)
            .applying(CGAffineTransform(rotationAngle: radians)).integral.size
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, image.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // Move origin to middle
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        context.rotate(by: radians)
        
        // Draw the original image at the center
        image.draw(in: CGRect(
            x: -image.size.width/2,
            y: -image.size.height/2,
            width: image.size.width,
            height: image.size.height
        ))
        
        let rotatedImg = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return rotatedImg
    }
    
    
    // MARK: - Zoom Logic
    
    private func zoomToFrame(_ frame: CGRect) {
        guard let image = imageView.image else { return }
        
        let scaleWidth = imageView.bounds.width / image.size.width
        let scaleHeight = imageView.bounds.height / image.size.height
        let scale = min(scaleWidth, scaleHeight)
        
        let imageWidth = image.size.width * scale
        let imageHeight = image.size.height * scale
        let imageX = (imageView.bounds.width - imageWidth) / 2.0
        let imageY = (imageView.bounds.height - imageHeight) / 2.0
        
        let imageFrameInView = CGRect(x: imageX, y: imageY, width: imageWidth, height: imageHeight)
        
        let normalizedX = frame.origin.x * scale + imageFrameInView.origin.x
        let normalizedY = frame.origin.y * scale + imageFrameInView.origin.y
        let normalizedWidth = frame.size.width * scale
        let normalizedHeight = frame.size.height * scale
        let targetRect = CGRect(x: normalizedX, y: normalizedY, width: normalizedWidth, height: normalizedHeight)
        
        let widthScale = scrollView.bounds.width / targetRect.width
        let heightScale = scrollView.bounds.height / targetRect.height
        let zoomScale = min(widthScale, heightScale, scrollView.maximumZoomScale)
        
        scrollView.setZoomScale(zoomScale, animated: true)
        
        let offsetX = targetRect.midX * zoomScale - scrollView.bounds.width / 2
        let offsetY = targetRect.midY * zoomScale - scrollView.bounds.height / 2
        
        let maxOffsetX = scrollView.contentSize.width - scrollView.bounds.width
        let maxOffsetY = scrollView.contentSize.height - scrollView.bounds.height
        
        let finalOffsetX = max(0, min(offsetX, maxOffsetX))
        let finalOffsetY = max(0, min(offsetY, maxOffsetY))
        
        scrollView.setContentOffset(CGPoint(x: finalOffsetX, y: finalOffsetY), animated: true)
    }
    
    
    // MARK: - Button Actions
    
    @objc private func nextTapped() {
        guard !frames.isEmpty else { return }
        currentIndex = (currentIndex + 1) % frames.count
        zoomToFrame(frames[currentIndex])
    }
    
    @objc private func prevTapped() {
        guard !frames.isEmpty else { return }
        currentIndex = (currentIndex - 1 + frames.count) % frames.count
        zoomToFrame(frames[currentIndex])
    }
    
    @objc private func backTapped() {
        dismiss(animated: true) {
            NotificationCenter.default.post(name: NSNotification.Name("SnapshotViewDismissed"), object: nil)
        }
    }
    
    @objc private func zoomInTapped() {
        guard !frames.isEmpty else {
            // If we don't have any frames, just do a general zoom-in on the current scale
            let newZoomScale = min(scrollView.zoomScale * 1.2, scrollView.maximumZoomScale)
            scrollView.setZoomScale(newZoomScale, animated: true)
            return
        }
        
        currentIndex = 0
        zoomToFrame(frames[currentIndex])
    }
    
    
    // MARK: - Speech Feedback
    
    private func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        speechSynthesizer.speak(utterance)
    }
    
    
    // MARK: - Keyboard Handling
    
    @objc private func keyboardWillShow(notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let keyboardFrameValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
            let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
            let animationCurveRawNSN = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber
        else { return }
        
        let keyboardFrame = keyboardFrameValue.cgRectValue
        let animationCurveRaw = animationCurveRawNSN.uintValue
        let animationOptions = UIView.AnimationOptions(rawValue: animationCurveRaw << 16)
        
        // Adjust the bottom constraint of searchContainerView
        let keyboardHeight = keyboardFrame.height
        searchContainerBottomConstraint?.constant = -keyboardHeight - 10
        
        UIView.animate(withDuration: animationDuration,
                       delay: 0,
                       options: animationOptions,
                       animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    @objc private func keyboardWillHide(notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
            let animationCurveRawNSN = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber
        else { return }
        
        let animationCurveRaw = animationCurveRawNSN.uintValue
        let animationOptions = UIView.AnimationOptions(rawValue: animationCurveRaw << 16)
        
        // Reset the bottom constraint of searchContainerView
        searchContainerBottomConstraint?.constant = -20
        
        UIView.animate(withDuration: animationDuration,
                       delay: 0,
                       options: animationOptions,
                       animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    
    // MARK: - Speech Recognition
    
    private func startSpeechRecording() {
        // Check if already running
        if audioEngine.isRunning {
            return
        }
        
        // Request speech recognition authorization
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            guard let self = self else { return }
            switch authStatus {
            case .authorized:
                DispatchQueue.main.async {
                    self.setupAndStartRecognition()
                }
            case .denied, .restricted, .notDetermined:
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Speech Recognition Unavailable",
                                                  message: "Please enable speech recognition in settings.",
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            @unknown default:
                break
            }
        }
    }
    
    private func setupAndStartRecognition() {
        // Initialize the recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            print("Unable to create recognition request")
            return
        }
        recognitionRequest.shouldReportPartialResults = true
        
        // Configure the audio session for playback and recording
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session error: \(error)")
            return
        }
        
        // Start the recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            if let result = result {
                let recognizedText = result.bestTranscription.formattedString
                self.searchTextField.text = recognizedText
                
                if result.isFinal {
                    let announcement = "Searching for \(recognizedText)"
                    let utterance = AVSpeechUtterance(string: announcement)
                    utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                    self.speechSynthesizer.speak(utterance)
                    
                    self.updateSearchTerm(recognizedText)
                    self.stopSpeechRecording()
                }
            }
            
            if let error = error {
                print("Recognition error: \(error)")
                self.stopSpeechRecording()
            }
        }
        
        // Configure the microphone input
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0,
                             bufferSize: 1024,
                             format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        // Start the audio engine
        do {
            try audioEngine.start()
            micButton.setImage(UIImage(named: "microphone_active"), for: .normal)
            micButton.backgroundColor = UIColor.red.withAlphaComponent(0.3) // Less intrusive red
            
            // Play "ding" sound to indicate mic activation
            dingPlayer?.play()
            
            print("Started recording speech...")
        } catch {
            print("audioEngine couldn't start because of an error: \(error)")
        }
    }


    private func stopSpeechRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            audioEngine.inputNode.removeTap(onBus: 0)
            
            recognitionRequest = nil
            recognitionTask = nil
            
            micButton.setImage(UIImage(named: "microphone"), for: .normal)
            micButton.backgroundColor = .clear
            
            // Play "dong" sound to indicate mic deactivation
            dongPlayer?.play()
            
            print("Stopped recording speech.")
            
            // Dismiss the listening alert if it's presented
            listeningAlert?.dismiss(animated: true, completion: nil)
            listeningAlert = nil
            
            // Reset audio session to playback
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            } catch {
                print("Audio session reset error: \(error)")
            }
        }
    }
    
    private func presentTemporaryAlert() {
        // Prevent multiple alerts
        if listeningAlert != nil {
            return
        }
        
        listeningAlert = UIAlertController(title: nil, message: "Listening...", preferredStyle: .alert)
        self.present(listeningAlert!, animated: true, completion: nil)
        
        let listeningDuration: TimeInterval = 10.0  // Adjust as needed
        
        DispatchQueue.main.asyncAfter(deadline: .now() + listeningDuration) { [weak self] in
            guard let self = self else { return }
            self.stopSpeechRecording()
            self.listeningAlert?.dismiss(animated: true, completion: nil)
            self.listeningAlert = nil
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
                    let alert = UIAlertController(title: "Speech Recognition Unavailable",
                                                  message: "Please enable speech recognition in settings.",
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            @unknown default:
                break
            }
        }
    }
    
    // MARK: - OCR Processing
    
    private func updateSearchTerm(_ newTerm: String) {
        self.searchTerm = newTerm
        self.individualSearchTerms = newTerm.lowercased().split(separator: " ").map { String($0) }
        self.processRecognitionOnRotatedImage(rotatedImage ?? originalImage)
    }
}


// MARK: - UIScrollViewDelegate

extension SnapshotViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}


// MARK: - UITextFieldDelegate

extension SnapshotViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        // Check if there is text to announce
        if let query = textField.text, !query.trimmingCharacters(in: .whitespaces).isEmpty {
            let announcement = "Searching for \(query)"
            let utterance = AVSpeechUtterance(string: announcement)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            speechSynthesizer.speak(utterance)
            
            // Update search term and reprocess the image
            updateSearchTerm(query)
        }
        
        return true
    }
}
