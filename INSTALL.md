Installation
============

There are two ways to use the _C3-PRO_ iOS framework: install via _CocoaPods_ or a manual install.

The CocoaPods install is **not yet functional**, hope to resolve issues with it soon.


CocoaPods
---------

Soon you can use [CocoaPods](http://cocoapods.org) (v 0.38.2 or above) to install _C3-PRO_.
If you don't have it yet, you can install CocoaPods with the following command:

```bash
$ gem install cocoapods
```

Create a `Podfile` with these contents:

```ruby
platform :ios, '8.0'
use_frameworks!

pod 'C3PRO', '~> 1.0'
```

To install run:

```bash
$ pod install
```

If C3-PRO has been updated, run:

```bash
$ pod update
```


Manual Installation
-------------------

Installing C3-PRO via git gives you most control but requires some fidgeting with Xcode.

Add C3-PRO as a git [submodule](http://git-scm.com/docs/git-submodule) to your own project by running the following command:

```bash
$ git submodule add https://github.com/chb/c3-pro-ios-framework.git
```

#### _“Add files to XY”_

Open your Xcode project, select the blue top level project file, then at the bottom click <key>+</key> to add a new file to your project.
Select `c3-pro-ios-framework/C3PRO.xcodeproj` and make sure it appears nested in your own project hierarchy (doesn't matter whether at the top or bottom).

#### Embed Libraries

With your blue project icon still active (in the Project Navigator), select the _“General”_ tab and scroll down to _“Embedded Libraries”_.
Click on the <key>+</key> button; under `C3PRO.xcodeproj` you will see a `Products` folder with `C3PRO.framework`.
Select it.

Xcode will automatically add the C3-PRO framework as a target dependency, meaning it will build first whenever you build your app, and add a copy-files build phase that copies the built framework into your app bundle.

#### Sub-Frameworks

You will need to **manually add sub-frameworks** that are used by C3-PRO but are not automatically linked and embedded.
This works similar to how you added _C3-PRO_ above, by choosing _“Add files to XY”_, then selecting the `*.xcodeproj` files for the following libraries, found **nested in _c3-pro-ios-framework_**:

- ResearchKit
- Swift-SMART
- CryptoSwift
- SQLiteSwift

Make sure these also appear in the _“Embedded Libraries”_ section.

