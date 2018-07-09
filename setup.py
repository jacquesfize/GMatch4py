import sys, os, shutil
from distutils.core import setup
from distutils.extension import Extension
import numpy as np
try:
    from Cython.Build import cythonize
    from Cython.Distutils import build_ext
except:
    print("You don't seem to have Cython installed. Please get a")
    print("copy from www.cython.org and install it")
    sys.exit(1)

setup(
    name="Gmatch4py",
    description="A module for graph matching",
    packages=["gmatch4py", "gmatch4py.ged", "gmatch4py.kernels"],
    ext_modules=cythonize([Extension("*", ["gmatch4py/*.pyx"],include_dirs=[np.get_include()])]),
    cmdclass={'build_ext': build_ext},
    setup_requires=["numpy","networkx"],
    install_requires=["numpy","networkx"],
    version="0.1"
)
#Clean cpp and compiled file
f=False
if f:
    if os.path.exists("build"):
        shutil.rmtree("build")
    os.system("find . -name \*.c -delete ; find . -name \*.cpp -delete ;")