from setuptools import setup
import pathlib
from setuptools.extension import Extension
import sys
import os
import argparse

default_vcpkg_root = os.getenv("VCPKG_ROOT", "C:/vcpkg")

argparser = argparse.ArgumentParser(add_help=False)
argparser.add_argument('--use-cython', action='store_true', default=False)
argparser.add_argument('--libheif_path', default=f"{default_vcpkg_root}/installed/x64-windows")
args, unknown = argparser.parse_known_args()
sys.argv = [sys.argv[0]] + unknown

here = pathlib.Path(__file__).parent.resolve()

# Get the long description from the README file
long_description = (here / 'README.md').read_text(encoding='utf-8')

lib_dirs = []
inc_dirs = []
bin_files = []
if sys.platform.startswith('win32'):
    required_dlls = ("heif.dll", "libde265.dll", "libx265.dll")
    libheif_bin_path = os.path.join(args.libheif_path, 'bin')
    libheif_lib_path = os.path.join(args.libheif_path, 'lib')
    libheif_inc_path = os.path.join(args.libheif_path, 'include')
    lib_dirs = [libheif_bin_path, libheif_lib_path]
    inc_dirs = [libheif_inc_path]
    bin_files = [str(x.absolute()) for x in pathlib.Path(libheif_bin_path).glob("*") if x.name in required_dlls]

ext = '.pyx' if args.use_cython else '.c'

extensions = [
    Extension(
        'cyheif', 
        sources=['heif/heif'+ext], 
        language='c', 
        libraries=['heif'], 
        library_dirs=lib_dirs,
        include_dirs=inc_dirs
    )
]

if args.use_cython:
    from Cython.Build import cythonize
    compiler_directives={'language_level': '3'}
    extensions = cythonize(extensions, compiler_directives=compiler_directives)

setup(
    name='cyheif',
    version='0.0.6',
    description='Python wrapper for libheif',
    long_description=long_description,
    long_description_content_type='text/markdown',
    url='https://github.com/ram-nat/CyHeif/',
    author='Ramkumar Natarajan',
    keywords='libheif, heif, heic, high-efficiency image format',
    python_requires='>=3.6',
    ext_modules=extensions,
    packages=['cyheifloader'],
    install_requires=['pillow'],
    data_files=[('bin', bin_files)] if sys.platform.startswith('win32') else [],
)
