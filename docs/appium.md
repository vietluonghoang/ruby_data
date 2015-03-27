# Running Appium Tests

*The Enrichment Center reminds you that the Companion Cube will never threaten
to stab you and, in fact, cannot speak. In the event that the Companion Cube
does speak, the Enrichment Center urges you to disregard its advice.*

**Appium is a mobile automation framework** that allows writing functional tests
that can be run on real and simulated/emulated mobile devices. Currently Appium
supports Android 2.3+ and iOS 6.0+. Test Chamber has Appium support built-in.

# Table of Contents

* [Overview](#overview)
* [How Appium Works](#works)
* [Usage](#usage)
    * [Running Locally](#local)
    * [Running on Appthwack](#appthwack)
    * [Running on Saucelabs](#saucelabs)
* [Compiling Apps](#apps)

## <a name='overview'></a>Overview

There are 3 options for running tests using Appium and iOS/Android.

1. Run locally with a simulator/emulator/real device.
2. Run using a remote simulator/emulator on Sauce Labs.
3. Run using a remote real device on AppThwack.

Sauce Labs and AppThwack are services we use for cloud based testing with our
mobile test apps. For development, you should run Appium locally using a
Simulator or Emulator. In Jenkins, tests will run against Saucelabs or Appthwack
and should be able to pass against both environments.

## <a name='works'></a> How Appium Works

Appium is an open-source tool for automating native, mobile web, and hybrid
applications on iOS and Android platforms [<sup>1</sup>][1]. Appium provides a
server, written in node.js, which interacts with vendor provided automation
frameworks like [UIAutomation][] and [UIAutomator][] to automate mobile
applications.

The Appium server exposes a JSON Wire Protocol which conforms to the w3c
[WebDriver Spec][], AKA 'Selenium 3'. This allows us to use existing tools like
Capybara and the Ruby Selenium Library to write our Appium automation.

## <a name='usage'></a> Usage

*Note:* To use Appium in tmux you must use [reattach-to-user-namespace][].

Since Appium is written in node.js, the installation has a few prerequisites.

1. Install Node.js and NPM: `brew install node`
2. Install Appium: `npm install -g appium` (`-g` makes it globally available)
3. Install XCode 5.1.1 or later
4. In Xcode preferences, download the iPhone Simulator SDKs you want to test.

You will also need a .app bundle for iOS, or an .apk file for Android. This is
the app you want to automate in the emulator/simulator. For information on how
to build this app/apk from the SDK, see [Compiling Apps](#apps).

### <a name='local'></a> Running Locally

Before running any tests on iOS, run `sudo authorize_ios`. This will authorize
Apple's Automation tool, Instruments, to control your simulator. `authorize_ios`
is a binary packaged with Appium. If you do not do this step you will have a
persistent popup that you have to manually dismiss.

The easiest way to get setup to run Appium on iOS is to use the `appium-doctor`
utility. It will check:

1. XCode is installed and the location is accessible.
2. XCode command line tools are installed.
3. DevToolsSecurity is enabled (done by `authorize_ios`).
4. OS X's internal iOS authorization DB is set up correctly.
5. Node is installed correctly.
6. ANDROID_HOME is set to the location of the Android SDK.
7. JAVA_HOME is set to the location of the Java JDK.

Simply run `appium-doctor` and resolve any warnings.

Once Appium is configured, you need to start the server by running `appium` at
the command line. Some helpful flags you can pass:

* `--session-override`: clobbers the current session and starts a new one
  whenever a new session is requested. Useful if you use `ctrl+c` to exit tests.
* `--show-sim-log` and `--show-ios-log`: Will output logging from the iOS
  Simulator and the running iOS processes to the console.
* `--command-timeout`: The global default command timeout in seconds. If you
  intend to use `pry` to debug a session, set this absurdly high so your session
  doesn't get shutdown (e.g. '60000').

Now that Appium is running, configure Test Chamber to use Appium as the backend
for tests by changing the `TC_DRIVER` environment variable to `appium`. This
will make Test Chamber only run specs tagged with `:appium` and use Appium as
the automation tool for those specs.

The Settings for OS, Version, Device, and App Path are set in
[`config/appium/appium.yml`](../config/appium/appium.yml), and are heavily
documented in the sample configuration file at ['config/appium/sample_appium.yml'](../config/appium/sample_appium.yml).

#### Running iOS Locally

iOS Specs need no further setup; simply set the capabilities you want in
`config/appium/appium.yml` and run your specs.

#### Running Android Locally

Android Specs need a running Android Emulator to connect to; Appium can install
and launch the application under test, as well as unlock the screen, but AVD
launching is currently unsupported.

To create and configure an AVD:

1. Ensure you have downloaded and unzipped the [Android SDK][].
2. Configure Android SDK:
  * Launch Android SDK Manager: `$ANDROID_HOME/tools/android`
  * Install everything in the 'tools' folder, plus every version of android's
  'SDK Platform' and 'Google APIs'. These are necessary for building apk files
  for the TapjoyEasyApp.
  * Install the 'Intel x86 Emulator Accelerator (HAXM Installer)' under
  'Extras'.
  * Install the 'Google APIs Intel x86 Atom System Image', or 'Google APIs (x86
  System Image)' for any version of Android you want to test with. Android 4.4.2
  (Api 19) is recommended. Be careful not to select the 'Android TV Intel x86
  Atom System Image' or 'Android Wear Intel x86 Atom System Image'.
3. Create and configure an Android Virtual Device (AVD)
  * Open the 'Android Virtual Device Manager' in the Android SDK Manager by
  opening Tools -> Manage AVDs.
  * Create a new AVD by clicking 'create'.
  * Give the AVD a name, select the device you would like to test, and the
  target version of Android (Make sure to select the Google APIs x86 image). If
  your computer can handle it, it is best to set the Memory Options and SD Card
  size to match the actual device under test. **Do not select the 'Use Host GPU'
  checkbox, as it is incompatible with Appium.**
  * Select the device in the AVD Manager and click 'Start' and then Launch the
  device. You can use a snapshot if you would like.
  * Once the device is launched, you can set it up with whatever settings you
  need (location services, for example),
  * Make sure you're on the home screen, and close emulator via CTRL+C or
  closing the window. **If you are using a snapshot, do not shut down the
  emulator with the power button.** (This sets up the 'snapshot' to make the
  emulator load faster.)

Before running `rspec`, launch your AVD with the version and device you want to
test. Appium will use the `adb` utility to discover and interact with your AVD.
If this connection is flaky or doesn't work, restart adb with
`adb --kill-server && adb --start-server`.

Once the AVD is running, change `config/appium/appium.yml` to use the OS,
Version, Device, and App Path you want to use.

### <a name='appthwack'></a> Running on Appthwack

**Appthwack is a mobile device cloud** that we use to test our SDK on multiple
real devices. To use Appthwack to run your test, change the `driver` option in
`config/appium/appium.yml` to `appthwack` and the `device` option to the [fully
branded name][] of the device you wish to use, e.g. 'Apple iPhone 5s' or
'Samsung Galaxy Nexus'.

Test Chamber will use the Appthwack Devices API to match your device string to a
device provided by Appthwack, or raise an error if no device matches. To make
Test Chamber match on exact matches only, set the `device_exact` option in
`config/appium/appthwack.yml`.

### <a name='saucelabs'></a> Running on Saucelabs

**Saucelabs is a mobile simulator, emulator, and browser cloud** that we use to
test our SDK on Simulators and Emulators. Sauce supports a broad range of iOS
and Android versions, and is a 'one-stop-shop' for our build to test simulated
and emulated devices.

Currently, there are fairly large timing issues with iOS Simulators on Saucelabs
but everything does work (just not reliably). Consider Saucelabs support to be
experimental.

To use Saucelabs, change the `driver` option in `config/appium/appium.yml` to
`saucelabs` and the `device` option to the [Saucelabs Device] you want to use
for your tests.

### <a name='apps'></a> Compiling Apps

To use Appium you need to have a debug build (.app bundle for iOS, .apk for
Android) for the App you want to test. In this guide it's assumed you're
building the TapjoyEasyApp [for iOS][] or [Android][].

#### Android

1. From the TapjoyEasyApp directory in the [tapjoyandroidlibrary][Android] repo
**that was built for your Tapinabox**, run
`$ANDROID_HOME/tools/android update project -p .`. This will create a build.xml
file, which is necessary for ant to build the project.
2. From the TapjoyEasyApp directory, run `ant debug`.

This will produce a debug APK that will work with Appium in the `bin` directory.
Use the absolute path to this apk for Appium tests. This APK works for real
devices as well as emulators.

#### iOS Simulators

From the TapjoyEasyApp directory in the [tapjoyconnectlibrary][for iOS] repo
**that was built for your Tapinabox**, run `xcodebuild -sdk iphonesimulator7.1`
(substitute your targeted sdk version).

This will produce a .app bundle in the `build` directory that you can zip, and
point Appium to the absolute path of this zip. (Appium will also work *locally*
if you point it to the .app bundle, but Saucelabs requires a zip file).

If you manually update the path in the SDK to point to your tapinabox you have to:

- Edit the url to point to the tapinabox
- Run the build in XCode
- Run `xcodebuild -sdk iphonesimulator7.1` from the TapjoyEasyApp directory

#### iOS Real Devices

To run tests on an iOS Device, the app bundle requires code signing. If you do
not have an iOS Signing Identity and Provisioning Certificate, email
tools@tapjoy.com.

To build a .app for a real device, run
`xcodebuild -sdk iphoneos7.1 -configuration Debug` (substitute your targeted
sdk version).

This will produce a .app bundle in the `build` directory that you can zip, and
point Appium to the absolute path of this zip. (Appium will also work *locally*
if you point it to the .app bundle, but Saucelabs requires a zip file).

[1]: http://appium.io/slate/en/master/
[UIAutomation]: https://developer.apple.com/library/ios/documentation/DeveloperTools/Reference/UIAutomationRef/_index.html
[UIAutomator]: http://developer.android.com/tools/help/uiautomator/index.html
[WebDriver Spec]: http://w3c.github.io/webdriver/webdriver-spec.html
[fully branded name]: https://appthwack.com/devicelab
[Saucelabs device]: https://saucelabs.com/platforms
[Android SDK]: http://developer.android.com/sdk/index.html
[for iOS]: https://github.com/Tapjoy/tapjoyconnectlibrary/tree/develop/apps/TapjoyEasyApp
[Android]: https://github.com/Tapjoy/tapjoylibraryandroid/tree/develop/apps/TapjoyEasyApp
[reattach-to-user-namespace]: https://github.com/ChrisJohnsen/tmux-MacOSX-pasteboard/blob/master/README.md
