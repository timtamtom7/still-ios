import Foundation
import Vision
import AVFoundation
import CoreImage
import Combine

/// Breath phase during the breathing cycle
enum BreathPhase: String, CaseIterable {
    case inhale = "Inhale"
    case hold = "Hold"
    case exhale = "Exhale"
    case rest = "Rest"

    var instruction: String {
        switch self {
        case .inhale: return "Breathe in..."
        case .hold: return "Hold..."
        case .exhale: return "Breathe out..."
        case .rest: return "Pause..."
        }
    }
}

/// Detected breath state from camera analysis
struct BreathState {
    let phase: BreathPhase
    let confidence: Float
    let breathRate: Double // breaths per minute
    let chestVertical位移: CGFloat // vertical movement magnitude

    static let empty = BreathState(
        phase: .rest,
        confidence: 0,
        breathRate: 0,
        chestVertical位移: 0
    )
}

/// Service for detecting breathing patterns using Vision framework body pose detection
/// Tracks chest/shoulder rise and fall from camera to pace breathing exercises
final class BreathDetectionService: NSObject, ObservableObject {
    static let shared = BreathDetectionService()

    // MARK: - Published State

    @Published private(set) var breathState: BreathState = .empty
    @Published private(set) var isDetecting = false
    @Published private(set) var cameraAuthorized = false
    @Published private(set) var errorMessage: String?

    // MARK: - Private Properties

    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private let sessionQueue = DispatchQueue(label: "BreathDetectionService.video", qos: .userInteractive)
    private let processingQueue = DispatchQueue(label: "BreathDetectionService.processing", qos: .userInteractive)

    // Pose detection
    private var bodyPoseRequest: VNDetectHumanBodyPoseRequest?

    // Breathing analysis state
    private var chestPositions: [CGFloat] = []
    private var shoulderPositions: [CGFloat] = []
    private var positionTimestamps: [Date] = []

    private let historyWindowSize = 60 // ~2 seconds at 30fps
    private let breathRateWindowSize = 180 // ~6 seconds for breath rate calculation

    // Phase detection thresholds
    private var baselineChestPosition: CGFloat = 0
    private var breathCyclePhase: BreathPhase = .rest
    private var lastPhaseChange: Date = Date()

    // Breath rate calculation
    private var breathTimestamps: [Date] = []

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    private override init() {
        super.init()
        setupVision()
    }

    // MARK: - Public API

    /// Request camera access for breath detection
    func requestCameraAccess() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            cameraAuthorized = true
            return true

        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            await MainActor.run {
                cameraAuthorized = granted
            }
            return granted

        case .denied, .restricted:
            cameraAuthorized = false
            return false

        @unknown default:
            cameraAuthorized = false
            return false
        }
    }

    /// Start breath detection using the default camera
    func startDetection() {
        guard !isDetecting else { return }

        sessionQueue.async { [weak self] in
            self?.setupCaptureSession()
        }
    }

    /// Stop breath detection
    func stopDetection() {
        guard isDetecting else { return }

        sessionQueue.async { [weak self] in
            self?.captureSession?.stopRunning()
            DispatchQueue.main.async {
                self?.isDetecting = false
                self?.resetState()
            }
        }
    }

    // MARK: - Private Setup

    private func setupVision() {
        bodyPoseRequest = VNDetectHumanBodyPoseRequest { [weak self] request, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = error.localizedDescription
                }
                return
            }

            guard let observations = request.results as? [VNHumanBodyPoseObservation],
                  let observation = observations.first else {
                return
            }

            self?.processBodyPose(observation)
        }
    }

    private func setupCaptureSession() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .medium

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
                ?? AVCaptureDevice.default(for: .video) else {
            DispatchQueue.main.async {
                self.errorMessage = "No camera available"
            }
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)

            if captureSession?.canAddInput(input) == true {
                captureSession?.addInput(input)
            }

            videoOutput = AVCaptureVideoDataOutput()
            videoOutput?.setSampleBufferDelegate(self, queue: processingQueue)
            videoOutput?.alwaysDiscardsLateVideoFrames = true

            if captureSession?.canAddOutput(videoOutput!) == true {
                captureSession?.addOutput(videoOutput!)
            }

            captureSession?.startRunning()

            DispatchQueue.main.async {
                self.isDetecting = true
                self.errorMessage = nil
            }

        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to setup camera: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Pose Processing

    private func processBodyPose(_ observation: VNHumanBodyPoseObservation) {
        do {
            // Get key points we need for breathing detection
            let chestPoint = try observation.recognizedPoint(.center)
            let leftShoulder = try observation.recognizedPoint(.leftShoulder)
            let rightShoulder = try observation.recognizedPoint(.rightShoulder)

            // Calculate chest center Y position (lower Y = higher on screen = inhale)
            let chestY = chestPoint.location.y

            // Calculate shoulder average
            let shoulderAvgY = (leftShoulder.location.y + rightShoulder.location.y) / 2

            // Only process if confidence is high enough
            let minConfidence: Float = 0.3
            guard chestPoint.confidence > minConfidence,
                  leftShoulder.confidence > minConfidence,
                  rightShoulder.confidence > minConfidence else {
                return
            }

            // Record positions
            recordPosition(chestY: chestY, shoulderY: shoulderAvgY)

            // Detect breathing phase
            let phase = detectBreathPhase(chestY: chestY)

            // Calculate breath rate
            let breathRate = calculateBreathRate()

            // Calculate confidence based on position stability
            let confidence = calculateConfidence()

            let newState = BreathState(
                phase: phase,
                confidence: confidence,
                breathRate: breathRate,
                chestVertical位移: calculateMovementMagnitude()
            )

            DispatchQueue.main.async {
                self.breathState = newState
            }

        } catch {
            // Silently handle - pose detection can fail momentarily
        }
    }

    private func recordPosition(chestY: CGFloat, shoulderY: CGFloat) {
        let now = Date()

        chestPositions.append(chestY)
        shoulderPositions.append(shoulderY)
        positionTimestamps.append(now)

        // Trim to window size
        if chestPositions.count > historyWindowSize {
            chestPositions.removeFirst()
            shoulderPositions.removeFirst()
            positionTimestamps.removeFirst()
        }

        // Initialize baseline on first readings
        if baselineChestPosition == 0 && !chestPositions.isEmpty {
            baselineChestPosition = chestPositions.reduce(0, +) / CGFloat(chestPositions.count)
        }
    }

    private func detectBreathPhase(chestY: CGFloat) -> BreathPhase {
        guard chestPositions.count > 10 else { return .rest }

        let recentPositions = Array(chestPositions.suffix(15))
        let avgRecent = recentPositions.reduce(0, +) / CGFloat(recentPositions.count)

        // Calculate trend
        let trend = chestY - avgRecent

        // Threshold for phase detection
        let threshold: CGFloat = 0.015

        let now = Date()
        let timeSinceLastChange = now.timeIntervalSince(lastPhaseChange)

        // Minimum time in each phase to avoid rapid switching
        let minPhaseTime: TimeInterval = 1.5

        if timeSinceLastChange < minPhaseTime {
            return breathCyclePhase
        }

        var newPhase = breathCyclePhase

        switch breathCyclePhase {
        case .rest, .exhale, .hold:
            // Transition to inhale when chest rises significantly
            if trend > threshold {
                newPhase = .inhale
            }

        case .inhale:
            // Check if we've reached peak (position starts dropping or leveling)
            if trend < -threshold {
                newPhase = .hold
            } else if trend < threshold && timeSinceLastChange > 3.0 {
                // Extended inhale, move to hold
                newPhase = .hold
            }

        case .hold:
            // Transition to exhale when chest drops
            if trend < -threshold {
                newPhase = .exhale
            } else if timeSinceLastChange > 2.0 {
                // Natural transition
                newPhase = .exhale
            }
        }

        if newPhase != breathCyclePhase {
            breathCyclePhase = newPhase
            lastPhaseChange = now

            if newPhase == .inhale || (newPhase == .exhale && breathCyclePhase == .hold) {
                breathTimestamps.append(now)
            }
        }

        return breathCyclePhase
    }

    private func calculateBreathRate() -> Double {
        // Keep breath timestamps trimmed
        let cutoff = Date().addingTimeInterval(-60)
        breathTimestamps = breathTimestamps.filter { $0 > cutoff }

        guard breathTimestamps.count >= 2 else { return 0 }

        // Count complete breaths (inhale-exhale pairs)
        let interval = breathTimestamps.last!.timeIntervalSince(breathTimestamps.first!)

        if interval < 10 {
            return 0
        }

        // We track inhale starts, so half the count gives approximate breaths
        let breaths = breathTimestamps.count / 2
        let minutes = interval / 60

        return Double(breaths) / minutes
    }

    private func calculateConfidence() -> Float {
        guard chestPositions.count > 20 else { return 0 }

        // Calculate variance in recent positions
        let recentPositions = Array(chestPositions.suffix(30))
        let mean = recentPositions.reduce(0, +) / CGFloat(recentPositions.count)
        let variance = recentPositions.reduce(0) { $0 + pow(Double($1 - mean), 2) } / Double(recentPositions.count)

        // Normal breathing should have some variance but not too much
        let normalizedVariance = min(variance * 100, 1.0)

        return Float(normalizedVariance)
    }

    private func calculateMovementMagnitude() -> CGFloat {
        guard chestPositions.count > 5 else { return 0 }

        let recentPositions = Array(chestPositions.suffix(10))
        guard let max = recentPositions.max(),
              let min = recentPositions.min() else {
            return 0
        }

        return max - min
    }

    private func resetState() {
        chestPositions.removeAll()
        shoulderPositions.removeAll()
        positionTimestamps.removeAll()
        breathTimestamps.removeAll()
        breathCyclePhase = .rest
        baselineChestPosition = 0
        breathState = .empty
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension BreathDetectionService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              let request = bodyPoseRequest else {
            return
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])

        do {
            try handler.perform([request])
        } catch {
            // Silently handle - this is called very frequently
        }
    }
}

// MARK: - Guided Breathing Session Support

extension BreathDetectionService {
    /// Provides timing for a guided breathing session
    func guidedBreathTiming(duration: Int, pattern: BreathPattern) -> [(phase: BreathPhase, duration: TimeInterval)] {
        return pattern.cycles(for: duration)
    }
}

/// Different breathing patterns for guided sessions
enum BreathPattern: String, CaseIterable, Identifiable {
    case box = "Box Breathing"
    case relaxing = "4-7-8 Relaxing"
    case energizing = "Energizing"
    case calm = "Calm Breath"

    var id: String { rawValue }

    func cycles(for totalDuration: Int) -> [(phase: BreathPhase, duration: TimeInterval)] {
        switch self {
        case .box:
            // 4-4-4-4 pattern
            return [
                (.inhale, 4), (.hold, 4), (.exhale, 4), (.hold, 4)
            ]

        case .relaxing:
            // 4-7-8 pattern
            return [
                (.inhale, 4), (.hold, 7), (.exhale, 8)
            ]

        case .energizing:
            // Quick 2-2 pattern
            return [
                (.inhale, 2), (.exhale, 2)
            ]

        case .calm:
            // Gentle 4-6 pattern
            return [
                (.inhale, 4), (.exhale, 6)
            ]
        }
    }
}
