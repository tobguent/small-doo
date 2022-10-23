# Decoupled Opacity Optimization Demo

This program demonstrates the decoupled opacity optimization technique of the paper:

Tobias Günther, Holger Theisel and Markus Gross <br/>
**Decoupled Opacity Optimization for Points, Lines and Surfaces** <br/>
Computer Graphics Forum (Proc. Eurographics), 2017.

The demo is tested on:
- Windows 11
- Visual Studio 2022 (Community Edition)

Requirements:
- Windows SDK (10.0.19041.0)
- DirectX 11
- CMake 3.8

Instructions: <br/>
Move the camera by holding the right mouse button and move back and forth with 'W' and 'S'. <br/>
Use '0', '1' or '2' as command line argument to select a data set:
- 0 = data/tornado.obj (default)
- 1 = data/rings.obj
- 2 = data/heli.obj
  
The demo code only contains the implementation for line data. It is not the most efficient implementation, but it shows the idea.
