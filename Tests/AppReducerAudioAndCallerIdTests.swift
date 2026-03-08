import XCTest
@testable import habla_ios

final class AppReducerAudioAndCallerIdTests: LogicTestCase {
    func testInputAudioLevelAboveThresholdSetsListeningPhaseWhenConnected() {
        var state = AppState()
        state.callStatus = .connected

        appReducer(state: &state, action: .inputAudioLevelUpdated(0.2))

        XCTAssertEqual(state.liveCallPhase, .listening)
    }

    func testReceivingAudioTrueSetsSpeakingPhaseWhenConnected() {
        var state = AppState()
        state.callStatus = .connected

        appReducer(state: &state, action: .receivingAudioChanged(true))

        XCTAssertEqual(state.liveCallPhase, .speaking)
    }

    func testReceivingAudioFalseTransitionsToTranslatingAfterSpeaking() {
        var state = AppState()
        state.callStatus = .connected
        state.liveCallPhase = .speaking
        state.inputAudioLevel = 0.0

        appReducer(state: &state, action: .receivingAudioChanged(false))

        XCTAssertEqual(state.liveCallPhase, .translating)
    }

    func testCallEndedResetsAgentStateAndReturnsToDialerWhenNotInSummary() {
        var state = AppState()
        state.callStatus = .connected
        state.callSid = "CA123"
        state.activeScreen = .activeCall
        state.agentStatus = .speaking
        state.agentTranscript = [TranscriptEntry(role: .agent, textOriginal: "Hola")]
        state.agentMidCallInput = "extra"

        appReducer(state: &state, action: .callEnded)

        XCTAssertEqual(state.callStatus, .idle)
        XCTAssertNil(state.callSid)
        XCTAssertEqual(state.activeScreen, .dialer)
        XCTAssertEqual(state.agentStatus, .idle)
        XCTAssertTrue(state.agentTranscript.isEmpty)
        XCTAssertEqual(state.agentMidCallInput, "")
    }

    func testVerifiedCallerIdsLoadedSelectsFirstWhenNoSelectionExists() {
        var state = AppState()
        state.callerId.selectedNumberSid = nil

        let ids = [
            VerifiedCallerId(id: "SID1", phoneNumber: "+14155550123", friendlyName: "One"),
            VerifiedCallerId(id: "SID2", phoneNumber: "+14155550124", friendlyName: "Two"),
        ]

        appReducer(state: &state, action: .verifiedCallerIdsLoaded(ids))

        XCTAssertEqual(state.callerId.selectedNumberSid, "SID1")
        XCTAssertEqual(state.callerId.verifiedNumbers, ids)
    }

    func testVerifiedCallerIdsLoadedReplacesInvalidSelectionWithFirst() {
        var state = AppState()
        state.callerId.selectedNumberSid = "MISSING"

        let ids = [
            VerifiedCallerId(id: "SID1", phoneNumber: "+14155550123", friendlyName: "One"),
            VerifiedCallerId(id: "SID2", phoneNumber: "+14155550124", friendlyName: "Two"),
        ]

        appReducer(state: &state, action: .verifiedCallerIdsLoaded(ids))

        XCTAssertEqual(state.callerId.selectedNumberSid, "SID1")
    }

    func testCallerIdDeletedRemovesEntryAndSelectsNext() {
        var state = AppState()
        state.callerId.verifiedNumbers = [
            VerifiedCallerId(id: "SID1", phoneNumber: "+14155550123", friendlyName: "One"),
            VerifiedCallerId(id: "SID2", phoneNumber: "+14155550124", friendlyName: "Two"),
        ]
        state.callerId.selectedNumberSid = "SID1"

        appReducer(state: &state, action: .callerIdDeleted("SID1"))

        XCTAssertEqual(state.callerId.verifiedNumbers.map(\.id), ["SID2"])
        XCTAssertEqual(state.callerId.selectedNumberSid, "SID2")
    }

    func testOpenCallSummarySortsVerifiedFactsByVerifiedConfidenceAndOccurrences() {
        var state = AppState()
        state.activeScreen = .dialer

        let facts = [
            VerifiedFact(type: "name", value: "B", confidence: 0.4, verified: false, occurrences: 10),
            VerifiedFact(type: "name", value: "C", confidence: 0.8, verified: true, occurrences: 1),
            VerifiedFact(type: "name", value: "A", confidence: 0.7, verified: true, occurrences: 3),
        ]
        let record = CallRecord(phoneNumber: "+14155550123", verifiedFacts: facts)

        appReducer(state: &state, action: .openCallSummary(record))

        XCTAssertEqual(state.verifiedFactsSummary.map(\.value), ["C", "A", "B"])
    }
}
