import AVFoundation
import Vision
import SwiftUI
import TradeTrackCore
import Synchronization
import os.log

/// A ViewModel managing the end-to-end biometric verification lifecycle.
///
/// ### The "Gatekeeper" Architecture
/// This class is designed to handle hardware-level frame rates (30+ fps) without stalling the user interface.
/// It coordinates between three distinct execution domains:
/// 1. **Hardware Queue:** Where raw camera frames arrive.
/// 2. **Worker Actors:** Where heavy CPU/GPU math (Face Analysis/Collection) occurs.
/// 3. **Main Actor:** Where the UI state and verification tasks are managed.
///
/// ### Key Performance Features
/// * **Atomic Short-Circuiting:** Uses `Atomic<Bool>` to drop frames instantly on the background thread
///   if a verification task is already in progress, avoiding unnecessary thread hops.
/// * **Suspension over Blocking:** By using `await` with external Actors, the Main Actor is never
///   blocked; it simply suspends the specific pipeline task while the UI continues to render smoothly.
@MainActor
final class VerificationViewModel: NSObject, ObservableObject {
    
    private let logger = Logger(subsystem: "Jon.TradeTrack", category: "VerificationVM")
    
    // MARK: - Dependencies
    
    // Abstract protocols allow for easy mocking in Unit/Integration tests.
    let camera: CameraManagerProtocol
    let processor: FaceProcessing
    let verifier: FaceVerificationProtocol
    let errorManager: ErrorHandling
    let collector: FaceCollecting
    let analyzer: FaceAnalyzerProtocol
    let navigator: VerificationNavigator

    // MARK: - Published UI State

    /// The current stage of the verification process (detecting, processing, or matched).
    @Published var state: VerificationState = .detecting
    
    /// A value from 0.0 to 1.0 representing how much biometric data has been gathered.
    @Published var collectionProgress: Double = 0.0

    /// The ID of the employee we are attempting to verify against.
    var targetEmployeeID: String?
    
    /// Exposes the camera's capture session directly to SwiftUI VideoPreview views.
    var session: AVCaptureSession { camera.uiCaptureSession }

    // MARK: - Task & Control Logic

    /// Holds a reference to the active verification network/processing task.
    /// This allows for explicit cancellation if the user leaves the screen or the session stops.
    var task: Task<Void, Never>?
    
    /// **The Gate:** A thread-safe atomic boolean.
    /// We use an atomic here because frames arrive on a background thread. Checking an
    /// atomic is significantly faster than hopping to the MainActor just to see if we are busy.
    let isProcessingFrame = Atomic<Bool>(false)
    
    #if DEBUG
    /// Stores observers for UI Testing bridges to ensure they are cleaned up in deinit.
    var uiTestObservers: [NSObjectProtocol] = []
    #endif

    // MARK: - Capture Delegate
    
    /// Bridges the camera hardware queue to our processing logic.
    /// The closure capture `[weak self]` is critical to prevent retain cycles with the camera manager.
    private lazy var outputDelegate = VerificationOutputDelegate { [weak self] frame in
        self?.processInputFrame(frame)
    }

    // MARK: - Initialization & Cleanup

    init(
        camera: CameraManagerProtocol,
        analyzer: FaceAnalyzerProtocol,
        collector: FaceCollecting,
        processor: FaceProcessing,
        verifier: FaceVerificationProtocol,
        errorManager: ErrorHandling,
        navigator: VerificationNavigator,
        employeeId: String
    ) {
        self.camera = camera
        self.analyzer = analyzer
        self.collector = collector
        self.processor = processor
        self.verifier = verifier
        self.errorManager = errorManager
        self.targetEmployeeID = employeeId
        self.navigator = navigator
        super.init()
    }
    
    /// **Memory Safety:** Deinit ensures that any global observers (like NotificationCenter)
    /// are removed. Since deinit is nonisolated, it can fire on any thread.
    deinit {
        #if DEBUG
        uiTestObservers.forEach { observer in
            NotificationCenter.default.removeObserver(observer)
        }
        #endif
    }

    // MARK: - Lifecycle Management

    /// Prepares hardware and starts the frame stream.
    func start() async {
        #if DEBUG
        installUITestSignalBridge()
        #endif
        do {
            try await camera.requestAuthorization()
            try await camera.start(delegate: outputDelegate)
        } catch {
            errorManager.showError(error)
        }
    }

    /// Stops all hardware and resets the pipeline state.
    /// Explicitly cancels the active verification task to prevent background network calls.
    func stop() async {
        task?.cancel()
        task = nil
        
        isProcessingFrame.store(false, ordering: .relaxed)
        await collector.reset()
        await analyzer.reset()
        collectionProgress = 0.0
        
        await camera.stop()
        state = .detecting
    }
    
    func retry() {
        self.state = .detecting
        self.collectionProgress = 0.0
        // RE-OPEN the gate to allow processInputFrame to start working again
        self.isProcessingFrame.store(false, ordering: .relaxed)
    }

    // MARK: - High-Frequency Frame Pipeline

    /// **Entry Point:** Called 30-60 times per second.
    /// Being `nonisolated` is key; it allows us to drop frames instantly on the
    /// background thread if the `isProcessingFrame` gate is closed.
    @discardableResult
    nonisolated func processInputFrame(_ frame: CIImage) -> Task<Void, Never>? {
        guard !self.isProcessingFrame.load(ordering: .relaxed) else {
            return nil
        }
        self.isProcessingFrame.store(true, ordering: .relaxed)
        
        return Task { @MainActor in
            await runAnalysisPipeline(for: frame)
        }
    }
    
    /// **Coordination:** Moves the frame through the analysis and collection actors.
    /// Because `analyzer` and `collector` are Actors, calling `await` on them
    /// automatically offloads the work to a background thread.
    private func runAnalysisPipeline(for frame: CIImage) async {
        // Step 1: Geometry Check (Does the frame contain a high-quality face?)
        guard let (face, quality) = await self.analyzer.analyze(in: frame) else {
            await self.handleNoFaceDetected()
            self.isProcessingFrame.store(false, ordering: .relaxed)
            return
        }
        
        self.isProcessingFrame.store(false, ordering: .relaxed)
        
        // Step 2: Collection (Aggregate data until we have enough for verification)
        let result = await self.collector.process(face: face, image: frame, quality: quality)
        
        // Step 3: Result Application (Back on MainActor to update UI)
        self.applyAnalysisResult(winner: result.winner, progress: result.progress)
    }
    
    private func applyAnalysisResult(winner: (VNFaceObservation, CIImage)?, progress: Double) {
        if let winner = winner {
            // Re-check the gate before committing to a heavy network task.
            guard self.task == nil else { return }
            
            self.collectionProgress = 0.0
            self.runVerificationTask(face: winner.0, image: winner.1)
        } else {
            self.collectionProgress = progress
        }
    }
    
    /// **Background Reset:** Logic for handling missing faces.
    /// This remains `nonisolated` so we can reset background actors without
    /// bothering the MainActor unless a UI change (progress reset) is actually needed.
    nonisolated func handleNoFaceDetected() async {
        if await collector.startTime != nil {
            await collector.reset()
            await analyzer.reset()
            
            // Only hop to MainActor when UI work is required.
            await self.resetCollectionUI()
        }
    }
    
    private func resetCollectionUI() {
        self.state = .detecting
        self.collectionProgress = 0.0
    }

    // MARK: - Verification Logic

    /// **Task Management:** Orchestrates the final face-to-ID comparison.
    /// We use a `defer` block to ensure the atomic `isProcessingFrame` is
    /// ALWAYS reset to `false`, even if the task fails or is cancelled.
    func runVerificationTask(face: VNFaceObservation, image: CIImage) {
        self.isProcessingFrame.store(true, ordering: .relaxed)
        
        task = Task { [weak self] in
            guard let self = self else { return }

            do {
                let resultID = try await performVerification(face: face, image: image)
                self.state = .matched(name: resultID)
                self.task = nil
                navigator.goToDashboard(employeeId: resultID)
            } catch is CancellationError {
                self.isProcessingFrame.store(false, ordering: .relaxed)
                self.task = nil
                logger.debug("Verification task cancelled.")
            } catch {
                //self.isProcessingFrame.store(false, ordering: .relaxed)
                self.task = nil
                handleVerificationError(error)
            }
        }
    }

    /// **Execution:** The actual "heavy lifting" of embedding generation and network calls.
    /// We check for cancellation twice to ensure we don't start a network
    /// call if the user has already moved on.
    private func performVerification(face: VNFaceObservation, image: CIImage) async throws -> String {
        try Task.checkCancellation()

        // Extraction (Actor-based processing)
        self.state = .processing
        let embedding = try await processor.process(image: image, face: face)
        
        try Task.checkCancellation()

        guard let employeeID = self.targetEmployeeID else {
            throw AppError(code: .employeeNotFound)
        }
        
        // Network Call
        try await verifier.verifyFace(employeeId: employeeID, embedding: embedding)
        return employeeID
    }

    private func handleVerificationError(_ error: Error) {
        guard !Task.isCancelled else { return }
        
        logger.error("Verification error: \(error.localizedDescription)")
        errorManager.showError(error)
        state = .detecting
    }
}
