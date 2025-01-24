//
//  SpeechHelper.swift
//  VisionExample
//
//  Created by Luo Lab on 1/13/25.
//  Copyright © 2025 Google Inc. All rights reserved.
//


import Foundation
import AVFoundation
import Speech
import UIKit

protocol SpeechHelperDelegate: AnyObject {
    /// Called when recognized partial or final speech result
    func speechHelperDidRecognizeText(_ text: String)
}

/// Manages both Speech-to-Text (recognition) and Text-to-Speech.
class SpeechHelper: NSObject, AVSpeechSynthesizerDelegate {
    
    weak var delegate: SpeechHelperDelegate?
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    private let speechSynth = AVSpeechSynthesizer()
    
    override init() {
        super.init()
        speechSynth.delegate = self
        configureAudioSessionForSpeaker()
    }
    
    // MARK: - Public TTS
    
    func speak(_ text: String) {
        print("TTS speak: \(text)")
        configureAudioSessionForSpeaker() // ensure speaker output
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        // utterance.rate = 0.5 if it's too fast
        speechSynth.speak(utterance)
    }
    
    // MARK: - Public STT
    
    func requestSpeechAuthorization(_ completion: @escaping (Bool)->Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                completion(status == .authorized)
            }
        }
    }
    
    func startRecording() {
        stopRecording() // cancel existing
        configureAudioSessionForSpeaker()
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            // .playAndRecord + .defaultToSpeaker to force speaker
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let req = recognitionRequest else { return }
        
        req.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: req) { [weak self] result, err in
            guard let self = self else { return }
            
            if let r = result {
                let bestString = r.bestTranscription.formattedString
                // Notify delegate
                self.delegate?.speechHelperDidRecognizeText(bestString)
                
                if r.isFinal {
                    self.stopRecording()
                }
            }
            if err != nil {
                self.stopRecording()
            }
        }
        
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
            print("Speech recognition started")
        } catch {
            print("AudioEngine couldn't start: \(error)")
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask = nil
    }
    
    // MARK: - Private
    
    private func configureAudioSessionForSpeaker() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord,
                                         mode: .default,
                                         options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            print("Audio session config error: \(error)")
        }
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) { }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) { }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) { }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) { }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) { }
}
