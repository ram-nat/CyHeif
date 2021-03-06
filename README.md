CyHeif - Cython based Python binding for libheif
================================================
Purpose
-------
This package provides Cython based Python binding for libheif allowing access to High-Efficiency Image Format from Python. One of the main goals for CyHeif is that it should work on Windows and allow for manipulating HEIF/HEIC images from Python in Windows. It works on Windows (unlike PyHeif). This is currently barebones but has the critical elements in place and adding functionality for working with HEIF/HEIC files and exposing them to Python as Pillow Images for manipulation.

Known Issues
------------
Setup does not work - sorry, I am a complete novice at creating a Python package and right now this is not where I want to spend my time. Please contact me if you need help setting this package up and I will try to help. I do plan to get this to be an installable Python package at some point when I get time. If you have knowledge with setting up a Python package and want to help me, that would be awesome!


Requirements
------------
You need a compiled, installed, working, accessible version of heif.dll on Windows. You will also need a working C compiler. To get a C compiler, you can download the [Microsoft Visual Studio Community Edition.](https://visualstudio.microsoft.com/vs/community/)

You can compile and install libheif on Windows through vcpkg by running the following command:

```
    vcpkg.exe install libheif --triplet x64-windows
```

More details on [vcpkg is available here.](https://docs.microsoft.com/en-us/cpp/build/vcpkg?view=msvc-160) Once the installation is successful, you should be able to use the extension module by running `pip install`. See `example/run.py` for how to use this extension module.
