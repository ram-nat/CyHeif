CyHeif - Cython based Python binding for libheif
================================================
Purpose
-------
HEIF and HEIC read and write support for Python using LibHeif that works across platforms (Windows and Linux) and has write support for EXIF metadata and HEIC output. 
This package provides Cython based Python binding for libheif allowing access to High-Efficiency Image Format from Python. One of the main goals for CyHeif is that it should work on Windows and allow for manipulating HEIF/HEIC images from Python in Windows. It works on Windows (unlike PyHeif) and Linux. This is currently barebones but has the critical elements in place and adding functionality for working with HEIF/HEIC files and exposing them to Python as Pillow Images for manipulation.

Functionality
-------------
Supports the following:
- Reading a HEIC file into a Pillow Image
- Reading the EXIF metadata from a HEIC file into a Pillow Image.Exif
- Updating the EXIF metadata from a HEIC file and writing it back as HEIC
- Writing a Pillow Image out as a HEIC file
- Use Pillow functionality for other image manipulations - resize, transforms etc.

Known Issues
------------
No Documentation - working on it. No binary distributions yet - help welcome to create these. See example/run.py for usage of key functionality.

Requirements
------------
You need a compiled, installed, working, accessible version of heif.dll on Windows. You will also need a working C compiler. To get a C compiler, you can download the [Microsoft Visual Studio Community Edition.](https://visualstudio.microsoft.com/vs/community/)

You can compile and install libheif on Windows through vcpkg by running the following command:

```
    vcpkg.exe install libheif --triplet x64-windows
```

More details on [vcpkg is available here.](https://docs.microsoft.com/en-us/cpp/build/vcpkg?view=msvc-160) 

On Linux, Ubuntu based distributions can install libheif and libheif-dev with the following commands:

```
sudo apt install libheif
sudo apt install libheif-dev
```

Once the installation is successful, you should be able to use the extension module by running `pip install`. See `example/run.py` for how to use this extension module.
