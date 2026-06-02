// 仕様: docs/spec/timeline-screen.md

import AVFoundation
import Foundation
import os

protocol AudioControllerDelegate: AnyObject {
    func processSampleData(_ data: Data)
}

final class AudioController {
    var remoteIOUnit: AudioComponentInstance?
    weak var delegate: AudioControllerDelegate?
    private let logger = Logger(subsystem: "yysystem.prototype", category: "AudioController")

    static let shared = AudioController()

    deinit {
        if let remoteIOUnit {
            AudioComponentInstanceDispose(remoteIOUnit)
        }
    }

    func requestRecordPermission() async throws {
        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .undetermined:
                logger.info("Permission has not been requested yet")
                if await AVAudioApplication.requestRecordPermission() {
                    logger.info("Permission is granted")
                } else {
                    logger.warning("Permission is denied")
                    throw permissionDeniedError()
                }
            case .denied:
                logger.warning("Permission has been denied")
                throw permissionDeniedError()
            case .granted:
                logger.info("Permission is already granted")
            @unknown default:
                break
            }
        } else {
            switch AVAudioSession.sharedInstance().recordPermission {
            case .undetermined:
                logger.info("Permission has not been requested yet")
                let granted = await withCheckedContinuation { continuation in
                    AVAudioSession.sharedInstance().requestRecordPermission { granted in
                        continuation.resume(returning: granted)
                    }
                }
                if granted {
                    logger.info("Permission is granted")
                } else {
                    logger.warning("Permission is denied")
                    throw permissionDeniedError()
                }
            case .denied:
                logger.warning("Permission has been denied")
                throw permissionDeniedError()
            case .granted:
                logger.info("Permission is already granted")
            @unknown default:
                break
            }
        }
    }

    func prepare(specifiedSampleRate: Int) -> OSStatus {
        logger.info("prepare start")

        var status = noErr

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setPreferredIOBufferDuration(10)
        } catch {
            return -1
        }

        var sampleRate = session.sampleRate
        logger.info("hardware sample rate = \(sampleRate), using specified rate = \(specifiedSampleRate)")
        sampleRate = Double(specifiedSampleRate)

        var audioComponentDescription = AudioComponentDescription()
        audioComponentDescription.componentType = kAudioUnitType_Output
        audioComponentDescription.componentSubType = kAudioUnitSubType_RemoteIO
        audioComponentDescription.componentManufacturer = kAudioUnitManufacturer_Apple
        audioComponentDescription.componentFlags = 0
        audioComponentDescription.componentFlagsMask = 0

        let remoteIOComponent = AudioComponentFindNext(nil, &audioComponentDescription)
        status = AudioComponentInstanceNew(remoteIOComponent!, &remoteIOUnit)
        if status != noErr {
            return status
        }

        let bus1: AudioUnitElement = 1
        var oneFlag: UInt32 = 1

        status = AudioUnitSetProperty(
            remoteIOUnit!,
            kAudioOutputUnitProperty_EnableIO,
            kAudioUnitScope_Input,
            bus1,
            &oneFlag,
            UInt32(MemoryLayout<UInt32>.size)
        )
        if status != noErr {
            return status
        }

        var asbd = AudioStreamBasicDescription()
        asbd.mSampleRate = sampleRate
        asbd.mFormatID = kAudioFormatLinearPCM
        asbd.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked
        asbd.mBytesPerPacket = 2
        asbd.mFramesPerPacket = 1
        asbd.mBytesPerFrame = 2
        asbd.mChannelsPerFrame = 1
        asbd.mBitsPerChannel = 16
        status = AudioUnitSetProperty(
            remoteIOUnit!,
            kAudioUnitProperty_StreamFormat,
            kAudioUnitScope_Output,
            bus1,
            &asbd,
            UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
        )
        if status != noErr {
            return status
        }

        var callbackStruct = AURenderCallbackStruct()
        callbackStruct.inputProc = recordingCallback
        callbackStruct.inputProcRefCon = nil
        status = AudioUnitSetProperty(
            remoteIOUnit!,
            kAudioOutputUnitProperty_SetInputCallback,
            kAudioUnitScope_Global,
            bus1,
            &callbackStruct,
            UInt32(MemoryLayout<AURenderCallbackStruct>.size)
        )
        if status != noErr {
            return status
        }

        logger.info("prepare end")
        return AudioUnitInitialize(remoteIOUnit!)
    }

    func start() -> OSStatus {
        logger.info("recorder start")
        guard let remoteIOUnit else { return noErr }
        return AudioOutputUnitStart(remoteIOUnit)
    }

    func stop() -> OSStatus {
        guard let remoteIOUnit else { return noErr }
        logger.info("recorder stop")
        return AudioOutputUnitStop(remoteIOUnit)
    }

    private func permissionDeniedError() -> NSError {
        NSError(
            domain: "PermissionError",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Record Permission has been denied"]
        )
    }
}

func recordingCallback(
    inRefCon: UnsafeMutableRawPointer,
    ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
    inTimeStamp: UnsafePointer<AudioTimeStamp>,
    inBusNumber: UInt32,
    inNumberFrames: UInt32,
    ioData: UnsafeMutablePointer<AudioBufferList>?
) -> OSStatus {
    var status = noErr
    let channelCount: UInt32 = 1

    let dataByteSize = inNumberFrames * 2
    let dataPointer = malloc(Int(dataByteSize))
    defer {
        free(dataPointer)
    }
    let buffer = AudioBuffer(mNumberChannels: channelCount, mDataByteSize: dataByteSize, mData: dataPointer)
    var bufferList = AudioBufferList(mNumberBuffers: 1, mBuffers: buffer)

    status = withUnsafeMutablePointer(to: &bufferList) { bufferListPtr in
        AudioUnitRender(
            AudioController.shared.remoteIOUnit!,
            ioActionFlags,
            inTimeStamp,
            inBusNumber,
            inNumberFrames,
            UnsafeMutablePointer<AudioBufferList>(bufferListPtr)
        )
    }
    if status != noErr {
        return status
    }
    let data = Data(bytes: bufferList.mBuffers.mData!, count: Int(bufferList.mBuffers.mDataByteSize))
    DispatchQueue.main.async {
        AudioController.shared.delegate?.processSampleData(data)
    }
    return noErr
}
