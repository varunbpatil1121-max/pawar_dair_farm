// Jenkins pipeline for Pawar Dairy.
// Runs on a Jenkins node that has Flutter and the Android SDK installed
// (the defaults below match the farm's Mac; override them as node
// environment variables if Jenkins runs elsewhere).

pipeline {
  agent any

  options {
    buildDiscarder(logRotator(numToKeepStr: '20', artifactNumToKeepStr: '5'))
    disableConcurrentBuilds()
    timeout(time: 30, unit: 'MINUTES')
  }

  triggers {
    // Check GitHub for new commits every ~5 minutes.
    pollSCM('H/5 * * * *')
  }

  environment {
    FLUTTER_HOME = "${env.FLUTTER_HOME ?: '/Users/varunpatil/develop/flutter'}"
    ANDROID_HOME = "${env.ANDROID_HOME ?: '/Users/varunpatil/Library/Android/sdk'}"
    PATH = "${FLUTTER_HOME}/bin:${ANDROID_HOME}/platform-tools:/opt/homebrew/bin:/usr/local/bin:${env.PATH}"
    // Keep Flutter from prompting or sending analytics on CI.
    CI = 'true'
  }

  stages {
    stage('Flutter info') {
      steps {
        sh 'flutter --version'
        sh 'flutter --disable-analytics || true'
      }
    }

    stage('Dependencies') {
      steps {
        sh 'flutter pub get'
      }
    }

    stage('Analyze') {
      steps {
        sh 'dart format --output=none --set-exit-if-changed lib test'
        sh 'flutter analyze'
      }
    }

    stage('Test') {
      steps {
        sh 'flutter test --reporter expanded'
      }
    }

    stage('Build APK') {
      steps {
        sh "flutter build apk --release --build-number=${env.BUILD_NUMBER}"
        sh "cp build/app/outputs/flutter-apk/app-release.apk build/app/outputs/flutter-apk/pawar-dairy-${env.BUILD_NUMBER}.apk"
      }
    }
  }

  post {
    success {
      archiveArtifacts artifacts: 'build/app/outputs/flutter-apk/pawar-dairy-*.apk', fingerprint: true
    }
  }
}
