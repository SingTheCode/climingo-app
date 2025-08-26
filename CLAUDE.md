# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Climingo-app is a SwiftUI-based iOS application that wraps a web app (app.climingo.xyz) in a native WebView. The app includes environment switching capabilities and social sharing features.

## Architecture

- **Main App**: `climingo_appApp.swift` - SwiftUI app entry point
- **ContentView**: Main view containing WebView with embedded JavaScript bridge for sharing
- **WebView**: UIViewRepresentable wrapper for WKWebView with custom navigation and script message handling
- **DeveloperModeView**: Hidden developer interface for switching between environments (dev/stg/prd)
- **Developer Access**: Hidden tap gesture (7 taps on top center) with password authentication ("climb_dev")

## Build Commands

```bash
# Build project
xcodebuild -project climingo-app.xcodeproj -scheme climingo-app -destination 'platform=iOS Simulator,name=iPhone 15' build

# Run tests
xcodebuild test -project climingo-app.xcodeproj -scheme climingo-app -destination 'platform=iOS Simulator,name=iPhone 15'

# Clean build
xcodebuild -project climingo-app.xcodeproj -scheme climingo-app clean
```

## Key Features

- **WebView Configuration**: Allows inline media playback, disables user action requirement for media
- **JavaScript Bridge**: Handles "share" messages from web content via WKScriptMessageHandler
- **Native Sharing**: UIActivityViewController integration for web content sharing
- **Environment Switching**: Dev/Staging/Production URL switching through developer mode
- **State Persistence**: Current URL saved to UserDefaults

## Development Notes

- App defaults to production URL: `https://app.climingo.xyz`
- Developer mode URLs:
  - Dev: `https://dev-app.climingo.xyz`  
  - Staging: `https://stg-app.climingo.xyz`
  - Production: `https://app.climingo.xyz`
- App terminates (exit(0)) when switching environments to force restart
- WebView includes 2-second sleep delay on initialization
- Korean language used in UI alerts and messages

## Development Guidelines

프로젝트 개발 시 다음 `.rules/` 디렉토리의 파일들을 참조하세요:

### 📋 General Coding Rules
- **파일**: `.rules/general.md`
- **내용**: 언어 및 명명 규칙, 코드 스타일, 주석 가이드라인, 타입 안전성, 함수 작성, 에러 처리, 성능 최적화

### 🔒 Security Rules  
- **파일**: `.rules/security.md`
- **내용**: 민감 정보 보호, XSS 방지, CSRF 방지, 인증 및 권한 관리, 입력 검증, 개인정보 보호

### 🏛️ Architecture Guidelines
- **파일**: `.rules/architecture.md` 
- **내용**: 아키텍처, 레이어 구조, 의존성 방향

### 🧪 Testing Rules
- **파일**: `.rules/test.md`
- **내용**: 테스트 명명 규칙, AAA 패턴, Locator 우선순위, 비동기 처리, Mock 선언, 프로젝트별 테스트 구조

### 📝 Commit Message Convention
- **파일**: `.rules/commit.md`
- **내용**: 커밋 메시지 구조, 커밋 타입, 스코프, 브랜치명과 일감번호 매핑, 프로젝트별 특수 규칙