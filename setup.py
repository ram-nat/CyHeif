from setuptools import setup
from setuptools.extension import Extension
import sys
import os
import argparse

argparser = argparse.ArgumentParser(add_help=False)
argparser.add_argument('--use-cython', action='store_true', default=False)
argparser.add_argument('--libheif_path', default='C:/vcpkg/installed/x64-windows')
args, unknown = argparser.parse_known_args()
sys.argv = [sys.argv[0]] + unknown

lib_dirs = []
inc_dirs = []
package_dirs = []
if sys.platform.startswith('win32'):
    libheif_bin_path = os.path.join(args.libheif_path, 'bin')
    libheif_lib_path = os.path.join(args.libheif_path, 'lib')
    libheif_inc_path = os.path.join(args.libheif_path, 'include')
    lib_dirs = [libheif_bin_path, libheif_lib_path]
    inc_dirs = [libheif_inc_path]
    package_dirs = ['cyheifloader']

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
    ext_modules=extensions,
    packages=package_dirs
)
