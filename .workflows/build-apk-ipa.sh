name: Build and Release KMM Application

on:
  push:
    branches:
      - main
  tags:
    - 'v*'

jobs:
  build_android:
    runs-on: ubuntu-latest

    steps:
      # Checkout the repository
      - name: Checkout code
        uses: actions/checkout@v3

      # Set up JDK 17 (or your Kotlin version compatible with the project)
      - name: Set up JDK 17
        uses: actions/setup-java@v3
        with:
          java-version: '17'
          distribution: 'adoptopenjdk'

      # Set up Kotlin
      - name: Set up Kotlin
        uses: actions/setup-kotlin@v1

      # Cache Gradle dependencies (to speed up the build)
      - name: Cache Gradle dependencies
        uses: actions/cache@v3
        with:
          path: ~/.gradle/caches
          key: ${{ runner.os }}-gradle-${{ hashFiles('**/*.gradle*', '**/gradle-wrapper.properties') }}
          restore-keys: |
            ${{ runner.os }}-gradle-

      # Build the Android APK
      - name: Build Android APK
        run: ./gradlew assembleRelease

  build_ios:
    runs-on: macos-latest

    steps:
      # Checkout the repository
      - name: Checkout code
        uses: actions/checkout@v3

      # Set up JDK 17 (ensure compatibility with KMM)
      - name: Set up JDK 17
        uses: actions/setup-java@v3
        with:
          java-version: '17'
          distribution: 'adoptopenjdk'

      # Set up Xcode (necessary for iOS builds)
      - name: Set up Xcode
        run: sudo xcode-select -s /Applications/Xcode_14.3.app

      # Cache Gradle dependencies (to speed up the build)
      - name: Cache Gradle dependencies
        uses: actions/cache@v3
        with:
          path: ~/.gradle/caches
          key: ${{ runner.os }}-gradle-${{ hashFiles('**/*.gradle*', '**/gradle-wrapper.properties') }}
          restore-keys: |
            ${{ runner.os }}-gradle-

      # Build the iOS IPA file
      - name: Build iOS IPA
        run: ./gradlew iosArm64XcodeBuild

  create_release:
    needs: [build_android, build_ios]
    runs-on: ubuntu-latest

    steps:
      # Checkout the repository again to ensure we have the latest state
      - name: Checkout code
        uses: actions/checkout@v3

      # Create GitHub Release
      - name: Create GitHub Release
        id: create_release
        uses: softprops/action-gh-release@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          files: |
            app/build/outputs/apk/release/app-release.apk
            app/build/ios/ipa/release/app-release.ipa

  upload_to_appcenter:
    needs: [build_android, build_ios]
    runs-on: ubuntu-latest

    steps:
      - name: Upload APK and IPA to AppCenter
        uses: AppCenter/appcenter-action@v1
        with:
          app_name: your-app-name
          owner_name: your-owner-name
          token: ${{ secrets.APPCENTER_API_TOKEN }}
          distribution_group: your-distribution-group
          apk_path: app/build/outputs/apk/release/app-release.apk
          ipa_path: app/build/ios/ipa/release/app-release.ipa

