<p align="center" width="100%"><img src="project/radio.svg"></p>

# IcyRadioStreamer

A GDExtension plugin for receiving IceCast streams inside the Godot 4.x game engine.

## Features

* Modular architecture designed to support additional media decoders in the future
* HTTP streaming performed on a dedicated thread
* Lightweight implementation that operates entirely outside the SceneTree
* Compatible with any Godot audio playback node, including 2D, 3D, and non-positional audio players
* Full in-editor documentation

## Current Support

At present, the plugin includes an MP3 decoder implementation. Support for additional audio formats is planned.

## Getting Started

To see the plugin in action, check out the example script at:

```text
project/addons/icy-radio-streamer/example.gd
```

## Overview

IcyRadioStreamer downloads and decodes IceCast audio streams and exposes the resulting raw audio data for playback through Godot's default audio system, allowing you to route streamed audio to any suitable audio player node.
