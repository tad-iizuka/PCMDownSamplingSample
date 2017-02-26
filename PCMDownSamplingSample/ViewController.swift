//
//  ViewController.swift
//  PCMDownSamplingSample
//
//  Created by Tadashi on 2017/02/26.
//  Copyright © 2017 T@d. All rights reserved.
//

import UIKit

import UIKit
import AVFoundation
import MediaPlayer

class ViewController: UIViewController {

	var audioEngine : AVAudioEngine!
	var audioFile : AVAudioFile!
	var audioPlayer : AVAudioPlayerNode!
	var outref: ExtAudioFileRef?
	var audioFilePlayer: AVAudioPlayerNode!
	var filePath : String? = nil
	var isRec = false
	var isPlay = false

	@IBOutlet var indicator: UIActivityIndicatorView!

	@IBAction func rec(_ sender: Any) {
	
		if audioEngine != nil && audioEngine.isRunning {
			self.stopRecord()
		} else {
			self.startRecord()
		}
	}
	@IBOutlet var rec: UIButton!

	override func viewDidLoad() {
		super.viewDidLoad()

		if AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeAudio) != .authorized {
			AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeAudio, completionHandler: { (granted: Bool) in
			})
		}
		self.update()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}

	func startRecord() {
	
		self.isRec = true
		self.update()
		self.filePath = nil

		try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord)
		try! AVAudioSession.sharedInstance().setActive(true)

		if audioEngine == nil {
			audioEngine = AVAudioEngine()
		}

		let format = AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatInt16,
													 sampleRate: 44100.0,
													 channels: 1,
													 interleaved: true)

		let downFormat = AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatInt16,
													 sampleRate: 16000.0,
													 channels: 1,
													 interleaved: true)

		audioEngine.connect(audioEngine.inputNode!, to: audioEngine.mainMixerNode, format: format)

		let dir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as String
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyyMMdd_HHmmss"
		let filePath =  dir.appending(String(format: "/%@.wav", formatter.string(from: Date())))
		let outurl = URL(fileURLWithPath: filePath)
		self.filePath = filePath
		_ = ExtAudioFileCreateWithURL(outurl as CFURL,
			kAudioFileWAVEType,
			downFormat.streamDescription,
			nil,
			AudioFileFlags.eraseFile.rawValue,
			&outref)

		audioEngine.inputNode!.installTap(onBus: 0, bufferSize: AVAudioFrameCount(format.sampleRate * 0.4), format: format, block: { (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in

			let converter = AVAudioConverter.init(from: format, to: downFormat)
			let newbuffer = AVAudioPCMBuffer(pcmFormat: downFormat,
				frameCapacity: AVAudioFrameCount(downFormat.sampleRate * 0.4))
			let inputBlock : AVAudioConverterInputBlock = { (inNumPackets, outStatus) -> AVAudioBuffer? in
				outStatus.pointee = AVAudioConverterInputStatus.haveData
				let audioBuffer : AVAudioBuffer = buffer
				return audioBuffer
			}
			var error : NSError?
			converter.convert(to: newbuffer, error: &error, withInputFrom: inputBlock)
			_ = ExtAudioFileWrite(self.outref!, newbuffer.frameLength, newbuffer.audioBufferList)
		})

		try! audioEngine.start()
	}

	func stopRecord() {

		if audioEngine != nil && audioEngine.isRunning {
			audioEngine.stop()
			audioEngine.inputNode!.removeTap(onBus: 0)
			ExtAudioFileDispose(self.outref!)
			try! AVAudioSession.sharedInstance().setActive(false)
			self.isRec = false
			self.update()
		}
	}

	func playerPlay() {

		self.isPlay = true
		self.update()

		try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
		try! AVAudioSession.sharedInstance().setActive(true)

		if audioEngine == nil {
			audioEngine = AVAudioEngine()
		}

		if audioFilePlayer == nil {
			audioFilePlayer = AVAudioPlayerNode()
			audioEngine.attach(audioFilePlayer)
		}

		audioFile = try! AVAudioFile(forReading: URL(fileURLWithPath: self.filePath!))
		audioEngine.connect(audioFilePlayer, to: audioEngine.mainMixerNode, format: audioFile.processingFormat)
		audioFilePlayer.scheduleSegment(audioFile, startingFrame: AVAudioFramePosition(0), frameCount: AVAudioFrameCount(audioFile.length) - UInt32(0), at: nil, completionHandler: self.completion)

		if !audioEngine.isRunning {
			try! audioEngine.start()
		}

		audioFilePlayer.installTap(onBus: 0, bufferSize: AVAudioFrameCount(audioFile.processingFormat.sampleRate * 0.4), format: audioFile.processingFormat, block: {
			(buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in

			// ...

		})
		audioFilePlayer.play()
	}
	
	func completion() {
		if audioFilePlayer != nil && audioFilePlayer.isPlaying {
			audioEngine.stop()
			audioFilePlayer.removeTap(onBus: 0)
			try! AVAudioSession.sharedInstance().setActive(false)
			self.isPlay = false
			self.update()
		}
	}

	func stopPlay() {
		if audioFilePlayer != nil && audioFilePlayer.isPlaying {
			audioFilePlayer.stop()
		}
		if audioEngine.isRunning {
			audioEngine.stop()
			audioFilePlayer.removeTap(onBus: 0)
		}
		try! AVAudioSession.sharedInstance().setActive(false)
		self.isPlay = false
		self.update()
	}

	func update() {
		if isPlay || isRec {
			self.indicator.startAnimating()
			self.indicator.isHidden = false
			self.rec.setTitle("STOP", for: .normal)
		} else {
			self.indicator.stopAnimating()
			self.indicator.isHidden = true
			self.rec.setTitle("RECORDING", for: .normal)
		}
	}

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		let vc = segue.destination as! ListView
		vc.delegate = self
    }
}
