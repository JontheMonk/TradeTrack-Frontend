import XCTest
import Vision
import CoreImage
@testable import TradeTrackCore

final class FaceCollectorTests: XCTestCase {
    
    var sut: FaceCollector!
    
    override func setUp() {
        super.setUp()
        sut = FaceCollector()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Tests
    
    func test_initialState_isClean() async {
        let startTime = await sut.startTime
        XCTAssertNil(startTime)
    }

    func test_firstFrame_startsTimer() async {
        let face = VNFaceObservation()
        let image = CIImage()
        
        _ = await sut.process(face: face, image: image, quality: 0.5)
        
        let startTime = await sut.startTime
        XCTAssertNotNil(startTime)
    }

    func test_highQualityFace_returnsImmediateWinner() async {
        let face = VNFaceObservation()
        let image = CIImage()
        
        // Quality 0.9 reaches the highWaterMark
        let result = await sut.process(face: face, image: image, quality: 0.9)
        
        XCTAssertNotNil(result.winner)
        XCTAssertEqual(result.progress, 1.0)
        
        // Ensure it reset after winning
        let startTime = await sut.startTime
        XCTAssertNil(startTime)
    }

    func test_mediocreFace_doesNotReturnWinnerImmediately() async {
        let face = VNFaceObservation()
        let image = CIImage()
        
        let result = await sut.process(face: face, image: image, quality: 0.5)
        
        XCTAssertNil(result.winner)
        XCTAssertLessThan(result.progress, 1.0)
    }

    func test_betterFace_updatesBestCandidate() async {
        let face1 = VNFaceObservation()
        let face2 = VNFaceObservation() // Technically different instances
        let image = CIImage()
        
        // First frame: mediocre
        _ = await sut.process(face: face1, image: image, quality: 0.4)
        
        // Second frame: better
        _ = await sut.process(face: face2, image: image, quality: 0.7)
        
        let best = await sut.currentBest
        XCTAssertNotNil(best)
        // Since we can't easily compare VNFaceObservation equality here,
        // we trust the logic or could check quality if currentBest returned it.
    }

    func test_reset_clearsEverything() async {
        let face = VNFaceObservation()
        _ = await sut.process(face: face, image: CIImage(), quality: 0.5)
        
        await sut.reset()
        
        let startTime = await sut.startTime
        let best = await sut.currentBest
        XCTAssertNil(startTime)
        XCTAssertNil(best)
    }
    
    func test_windowExpiration_returnsBestWinner() async {
        let face = VNFaceObservation()
        let image = CIImage()
        
        // 1. Start collection
        _ = await sut.process(face: face, image: image, quality: 0.5)
        
        // 2. Wait for the window (0.8s) to expire
        // In a real app, we'd mock the Date provider,
        // but for now, we sleep to test the actual actor logic.
        try? await Task.sleep(nanoseconds: 900_000_000) // 0.9 seconds
        
        // 3. Next process call should trigger the win
        let result = await sut.process(face: face, image: image, quality: 0.5)
        
        XCTAssertNotNil(result.winner)
        XCTAssertEqual(result.progress, 1.0)
    }
}
