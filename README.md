# Sukhasana
Mac status item for searching Asana. An experiment with [MVVM](https://github.com/ReactiveCocoa/ReactiveViewModel) in [ReactiveCocoa 3](https://github.com/ReactiveCocoa/ReactiveCocoa/pull/1382).

![screenshot](http://zippy.gfycat.com/WellmadeBewitchedHart.gif)

Requires OS X Yosemite (10.10).

## Installation

### Binary

1. Download `Sukhasana.zip` from the [latest release](https://github.com/brow/Sukhasana/releases/latest).
2. Open `Sukhasana.zip`.
3. Move `Sukhasana` into your `Applications` folder.

### From source
Sukhasana's dependencies are built with [Carthage](https://github.com/Carthage/Carthage). You can install Carthage using [Homebrew](http://brew.sh/).
```
brew install carthage
```
Build with `make`.
```
git clone git@github.com:brow/Sukhasana.git
cd Sukhasana
make install
```
Be sure to `make clean` when you update.
```
git pull
make clean install
```

## Development
```
brew install carthage
git clone git@github.com:brow/Sukhasana.git
cd Sukhasana
carthage bootstrap --platform Mac
open Sukhasana.xcodeproj
```
