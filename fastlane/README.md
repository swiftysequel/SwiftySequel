fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew cask install fastlane`

# Available Actions
## Mac
### mac setup
```
fastlane mac setup
```
Sets up the working directory for development, testing etc.
### mac lint
```
fastlane mac lint
```
Lints the code.
### mac analyze
```
fastlane mac analyze
```
Runs `swiftlint analyze` on the code base.

Run `bundle exec fastlane analyze autocorrect:true` to attempt auto-correction of rule violations.
### mac test
```
fastlane mac test
```
Runs all the tests.

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
