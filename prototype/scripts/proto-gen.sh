#!/usr/bin/env bash
# yysystem.proto から Swift 生成物を再生成する。
# 前提: brew install swift-protobuf grpc-swift
# 仕様: README.md#開発環境セットアップ

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROTOS_DIR="$SCRIPT_DIR/../prototype/Speech/Protos"

protoc "$PROTOS_DIR"/*.proto \
    --proto_path="$PROTOS_DIR" \
    --swift_opt=Visibility=Public \
    --swift_out="$PROTOS_DIR" \
    --grpc-swift_opt=Visibility=Public \
    --grpc-swift_out="$PROTOS_DIR"
