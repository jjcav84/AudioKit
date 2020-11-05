// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKit/
@testable import AudioKit
import AVFoundation
import CAudioKit
import XCTest

class NodeTests: XCTestCase {
    let osc = Oscillator()

    func testNodeBasic() {
        let engine = AudioEngine()
        let osc = Oscillator()
        XCTAssertNotNil(osc.avAudioUnit)
        XCTAssertNil(osc.avAudioNode.engine)
        osc.start()
        engine.output = osc
        XCTAssertNotNil(osc.avAudioNode.engine)
        let audio = engine.startTest(totalDuration: 0.1)
        audio.append(engine.render(duration: 0.1))
        testMD5(audio)
    }

    func testNodeConnection() {
        let engine = AudioEngine()
        let osc = Oscillator()
        osc.start()
        let verb = CostelloReverb(osc)
        engine.output = verb
        let audio = engine.startTest(totalDuration: 0.1)
        audio.append(engine.render(duration: 0.1))
        testMD5(audio)
    }

    func testRedundantConnection() {
        let osc = Oscillator()
        let mixer = Mixer()
        mixer.addInput(osc)
        mixer.addInput(osc)
        XCTAssertEqual(mixer.connections.count, 1)
    }

    func testDynamicOutput() {
        let engine = AudioEngine()

        let osc1 = Oscillator()
        osc1.start()
        engine.output = osc1

        let audio = engine.startTest(totalDuration: 2.0)

        let newAudio = engine.render(duration: 1.0)
        audio.append(newAudio)

        let osc2 = Oscillator(frequency: 880)
        osc2.start()
        engine.output = osc2

        let newAudio2 = engine.render(duration: 1.0)
        audio.append(newAudio2)

        testMD5(audio)
        // audition(audio)
    }

    func testDynamicConnection() {
        let engine = AudioEngine()

        let osc = Oscillator()
        let mixer = Mixer(osc)

        XCTAssertNil(osc.avAudioNode.engine)

        engine.output = mixer

        // Osc should be attached.
        XCTAssertNotNil(osc.avAudioNode.engine)

        let audio = engine.startTest(totalDuration: 2.0)

        osc.start()

        audio.append(engine.render(duration: 1.0))

        let osc2 = Oscillator(frequency: 880)
        osc2.start()
        mixer.addInput(osc2)

        audio.append(engine.render(duration: 1.0))

        testMD5(audio)
    }

    func testDynamicConnection2() {
        let engine = AudioEngine()

        let osc = Oscillator()
        let mixer = Mixer(osc)

        engine.output = mixer
        osc.start()

        let audio = engine.startTest(totalDuration: 2.0)

        audio.append(engine.render(duration: 1.0))

        let osc2 = Oscillator(frequency: 880)
        let verb = CostelloReverb(osc2)
        osc2.start()
        mixer.addInput(verb)

        audio.append(engine.render(duration: 1.0))

        testMD5(audio)
        // audition(audio)
    }

    func testDynamicConnection3() {
        let engine = AudioEngine()

        let osc = Oscillator()
        let mixer = Mixer(osc)
        engine.output = mixer

        osc.start()

        let audio = engine.startTest(totalDuration: 3.0)

        audio.append(engine.render(duration: 1.0))

        let osc2 = Oscillator(frequency: 880)
        osc2.start()
        mixer.addInput(osc2)

        audio.append(engine.render(duration: 1.0))

        mixer.removeInput(osc2)

        audio.append(engine.render(duration: 1.0))

        testMD5(audio)
        // audition(audio)
    }

    func testDisconnect() {
        let engine = AudioEngine()

        let osc = Oscillator()
        let mixer = Mixer(osc)
        engine.output = mixer

        let audio = engine.startTest(totalDuration: 2.0)

        osc.start()

        audio.append(engine.render(duration: 1.0))

        mixer.removeInput(osc)

        audio.append(engine.render(duration: 1.0))

        testMD5(audio)
        // audition(audio)
    }

    func testNodeDetach() {
        let engine = AudioEngine()

        let osc = Oscillator()
        let mixer = Mixer(osc)
        engine.output = mixer
        osc.start()

        let audio = engine.startTest(totalDuration: 2.0)

        audio.append(engine.render(duration: 1.0))

        osc.detach()

        audio.append(engine.render(duration: 1.0))

        testMD5(audio)
    }

    func testTwoEngines() {
        let engine = AudioEngine()
        let engine2 = AudioEngine()

        let osc = Oscillator()
        engine2.output = osc
        osc.start()

        let verb = CostelloReverb(osc)
        engine.output = verb

        let audio = engine.startTest(totalDuration: 0.1)
        audio.append(engine.render(duration: 0.1))
        testMD5(audio)
    }

    func testManyMixerConnections() {
        let engine = AudioEngine()

        var oscs: [Oscillator] = []
        for _ in 0 ..< 16 {
            oscs.append(Oscillator())
        }

        let mixer = Mixer(oscs)
        engine.output = mixer

        XCTAssertEqual(mixer.avAudioNode.numberOfInputs, 16)
    }

    func connectionCount(node: AVAudioNode) -> Int {
        var count = 0
        for bus in 0 ..< node.numberOfInputs {
            if let inputConnection = node.engine!.inputConnectionPoint(for: node, inputBus: bus) {
                if inputConnection.node != nil {
                    count += 1
                }
            }
        }
        return count
    }

    func testFanout() {
        let engine = AudioEngine()
        let osc = Oscillator()
        let verb = CostelloReverb(osc)
        let mixer = Mixer(osc, verb)
        engine.output = mixer

        XCTAssertEqual(connectionCount(node: verb.avAudioNode), 1)
        XCTAssertEqual(connectionCount(node: mixer.avAudioNode), 2)
    }

    func testMixerRedundantUpstreamConnection() {
        let engine = AudioEngine()

        let osc = Oscillator()
        let mixer1 = Mixer(osc)
        let mixer2 = Mixer(mixer1)

        engine.output = mixer2

        XCTAssertEqual(connectionCount(node: mixer1.avAudioNode), 1)

        mixer2.addInput(osc)

        XCTAssertEqual(connectionCount(node: mixer1.avAudioNode), 1)
    }

    func testTransientNodes() {
        let engine = AudioEngine()
        let osc = Oscillator()
        func exampleStart() {
            let env = AmplitudeEnvelope(osc)
            osc.amplitude = 1
            engine.output = env
            osc.start()
            try! engine.start()
            sleep(1)
        }
        func exampleStop() {
            osc.stop()
            engine.stop()
            sleep(1)
        }
        exampleStart()
        exampleStop()
        exampleStart()
        exampleStop()
        exampleStart()
        exampleStop()
    }

    // This provides a baseline for measuring the overhead
    // of mixers in testMixerPerformance.
    func testChainPerformance() {
        let engine = AudioEngine()
        let osc = Oscillator()
        let rev = CostelloReverb(osc)

        XCTAssertNotNil(osc.avAudioUnit)
        XCTAssertNil(osc.avAudioNode.engine)
        osc.start()
        engine.output = rev
        XCTAssertNotNil(osc.avAudioNode.engine)

        measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            let audio = engine.startTest(totalDuration: 10.0)

            startMeasuring()
            let buf = engine.render(duration: 10.0)
            stopMeasuring()

            audio.append(buf)
        }
    }

    // Measure the overhead of mixers.
    func testMixerPerformance() {
        let engine = AudioEngine()
        let osc = Oscillator()
        let mix1 = Mixer(osc)
        let rev = CostelloReverb(mix1)
        let mix2 = Mixer(rev)

        XCTAssertNotNil(osc.avAudioUnit)
        XCTAssertNil(osc.avAudioNode.engine)
        osc.start()
        engine.output = mix2
        XCTAssertNotNil(osc.avAudioNode.engine)

        measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            let audio = engine.startTest(totalDuration: 10.0)

            startMeasuring()
            let buf = engine.render(duration: 10.0)
            stopMeasuring()

            audio.append(buf)
        }
    }

    // Setting Settings.audioFormat will change subsequent node connections
    // from 44_100 which the MD5's were created with
    func testNodeSampleRateIsSet() {
        let previousFormat = Settings.audioFormat

        let chosenRate: Double = 48_000
        guard let audioFormat = AVAudioFormat(standardFormatWithSampleRate: chosenRate, channels: 2) else {
            Log("Failed to create format")
            return
        }

        if audioFormat != Settings.audioFormat {
            Log("Changing audioFormat to", audioFormat)
        }
        Settings.audioFormat = audioFormat

        let engine = AudioEngine()
        let oscillator = Oscillator()
        let mixer = Mixer(oscillator)

        // assign input and engine references
        engine.output = mixer

        let mixerSampleRate = mixer.avAudioUnitOrNode.outputFormat(forBus: 0).sampleRate
        let engineSampleRate = engine.avEngine.outputNode.outputFormat(forBus: 0).sampleRate
        let engineDynamicMixerSampleRate = engine.mainMixerNode?.avAudioUnitOrNode.outputFormat(forBus: 0).sampleRate
        let oscSampleRate = oscillator.avAudioUnitOrNode.outputFormat(forBus: 0).sampleRate

        XCTAssertTrue(mixerSampleRate == chosenRate,
                      "mixerSampleRate \(mixerSampleRate), actual rate \(chosenRate)")

        // the mixer should be the mainMixerNode in this test
        XCTAssertTrue(engineDynamicMixerSampleRate == chosenRate && mixer === engine.mainMixerNode,
                      "engineDynamicMixerSampleRate \(mixerSampleRate), actual rate \(chosenRate)")

        XCTAssertTrue(oscSampleRate == chosenRate,
                      "oscSampleRate \(oscSampleRate), actual rate \(chosenRate)")
        XCTAssertTrue(engineSampleRate == chosenRate,
                      "engineSampleRate \(engineSampleRate), actual rate \(chosenRate)")

        Log(engine.avEngine.description)

        // restore
        Settings.audioFormat = previousFormat
    }

    func testEngineMainMixerOverride() {
        let engine = AudioEngine()
        let oscillator = Oscillator()
        let mixer = Mixer(oscillator)
        engine.output = mixer
        XCTAssertTrue(engine.mainMixerNode === mixer, "created mixer should be adopted as the engine's main mixer")
    }

    func testEngineMainMixerCreated() {
        let engine = AudioEngine()
        let oscillator = Oscillator()
        engine.output = oscillator
        XCTAssertNotNil(engine.mainMixerNode, "created mixer is nil")
    }

    func testChangeEngineOutputWhileRunning() {
        let engine = AudioEngine()
        let oscillator = Oscillator()
        oscillator.frequency = 220
        oscillator.amplitude = 0.1
        let oscillator2 = Oscillator()
        oscillator2.frequency = 440
        oscillator2.amplitude = 0.1
        engine.output = oscillator

        do {
            try engine.start()
        } catch let error as NSError {
            Log(error, type: .error)
            XCTFail("Failed to start engine")
        }

        XCTAssertTrue(engine.avEngine.isRunning, "engine isn't running")
        oscillator.start()

        // sleep(1) // for simple realtime check

        // change the output - will stop the engine
        engine.output = oscillator2

        // is it started again
        XCTAssertTrue(engine.avEngine.isRunning)

        oscillator2.start()

        // sleep(1) // for simple realtime check

        engine.stop()
    }
}
