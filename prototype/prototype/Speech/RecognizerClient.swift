// 仕様: docs/spec/timeline-screen.md

import Foundation
import GRPCCore
import GRPCNIOTransportHTTP2
import SwiftProtobuf
import os

enum RecognizerEvent {
    case onData(String, Bool)
    case onError(String)
}

enum RecognizerError: Error, LocalizedError {
    case configurationFailed(String)
    case initializationFailed(String)
    case recognitionCanceled(String)
    case requestFailed(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .configurationFailed(let message):
            return "Configuration failed: \(message)"
        case .initializationFailed(let message):
            return "Initialization failed: \(message)"
        case .recognitionCanceled(let message):
            return "Recognition canceled: \(message)"
        case .requestFailed(let message):
            return "Request failed: \(message)"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
}

final class RecognizerClient {
    private var continuation: AsyncThrowingStream<RecognizerEvent, Error>.Continuation?
    private var requestStream: AsyncStream<Yysystem_StreamRequest>?
    private var requestContinuation: AsyncStream<Yysystem_StreamRequest>.Continuation?
    private let logger = Logger(subsystem: "yysystem.prototype", category: "RecognizerClient")
    private var responseChunkCount = 0

    init() {
        logger.info("RecognizerClient initialized.")
    }

    func stream() async throws -> AsyncThrowingStream<RecognizerEvent, Error> {
        responseChunkCount = 0
        logger.info("recognition stream start requested.")
        let (requestStream, requestContinuation) = AsyncStream<Yysystem_StreamRequest>.makeStream()
        self.requestStream = requestStream
        self.requestContinuation = requestContinuation
        requestContinuation.onTermination = { @Sendable [weak self] _ in
            self?.logger.info("RequestContinuation terminated.")
        }
        let (stream, continuation) = AsyncThrowingStream<RecognizerEvent, Error>.makeStream()
        self.continuation = continuation
        continuation.onTermination = { @Sendable [weak self] _ in
            self?.logger.info("Continuation terminated.")
            self?.requestContinuation?.finish()
        }
        Task {
            do {
                try await withGRPCClient(
                    transport: .http2NIOPosix(
                        target: .dns(host: "api-grpc-2.yysystem2021.com", port: 443),
                        transportSecurity: .tls(.defaults())
                    )
                ) { channel in
                    logger.info("channel created")
                    let client = Yysystem_YYSpeech.Client(wrapping: channel)
                    guard let apiKey = ProcessInfo.processInfo.environment["API_KEY"] else {
                        continuation.finish(throwing: RecognizerError.configurationFailed("API_KEY is missing"))
                        return
                    }
                    var metadata = Metadata()
                    metadata.addString(apiKey, forKey: "yyapis-api-key")
                    logger.info("metadate: \(metadata.description)")
                    do {
                        try await client.recognizeStream(metadata: metadata) { call in
                            self.logger.info("call created")
                            try await call.write(.with {
                                $0.streamingConfig = Yysystem_StreamingConfig.with {
                                    $0.model = 10
                                    $0.enableInterimResults = true
                                    $0.languageCode = 4
                                    $0.sampleRateHertz = 16000
                                    $0.audioChannelCount = 1
                                    $0.encoding = "LINEAR16"
                                }
                            })
                            self.logger.info("streaming config sent. sampleRate=\(16000), channels=\(1), interim=\(true)")
                            do {
                                for try await request in requestStream {
                                    self.logger.debug("audio request chunk received from app, sending to gRPC stream.")
                                    try await call.write(request)
                                }
                                self.logger.info("request stream completed from app side.")
                            } catch {
                                self.logger.error("\(error.localizedDescription)")
                                continuation.finish(throwing: RecognizerError.requestFailed(error.localizedDescription))
                            }
                        } onResponse: { response in
                            do {
                                for try await chunk in response.messages {
                                    self.responseChunkCount += 1
                                    if chunk.hasResult {
                                        let result = chunk.result
                                        let isFinal = result.isFinal
                                        let text = result.transcript
                                        self.logger.info(
                                            "recognition result received. chunk=\(self.responseChunkCount), isFinal=\(isFinal), textLength=\(text.count)"
                                        )
                                        if !text.isEmpty {
                                            self.logger.debug("recognition transcript: \(text, privacy: .public)")
                                            continuation.yield(.onData(text, isFinal))
                                        }
                                    } else {
                                        self.logger.debug("response chunk without result received. chunk=\(self.responseChunkCount)")
                                    }
                                }
                                self.logger.info("response stream completed successfully.")
                            } catch {
                                self.logger.error("error: \(error)")
                                continuation.finish(throwing: RecognizerError.recognitionCanceled(error.localizedDescription))
                            }
                        }
                    } catch {
                        logger.error("error: \(error)")
                        continuation.finish(throwing: RecognizerError.initializationFailed(error.localizedDescription))
                    }
                }
            } catch {
                logger.info("error: \(error)")
                continuation.finish(throwing: RecognizerError.configurationFailed(error.localizedDescription))
            }
        }
        return stream
    }

    func write(_ request: Yysystem_StreamRequest) async throws {
        guard let continuation = requestContinuation else {
            logger.info("skip write, requestContinuation is nil")
            return
        }
        logger.debug("write called for recognition request.")
        continuation.yield(request)
    }

    func stop() {
        logger.info("stop requested for recognition stream.")
        self.continuation?.finish()
    }
}
