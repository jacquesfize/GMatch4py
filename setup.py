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

is_linux = sys.platform == 'linux'
libs=[]
if is_linux:  # Issue #42
    libs.append('rt')  # -lrt for clock_gettime

def scandir(dir, files=[]):
    for file in os.listdir(dir):
        path = os.path.join(dir, file)
        if os.path.isfile(path) and path.endswith(".pyx"):
            files.append(path.replace(os.path.sep, ".")[:-4])
        elif os.path.isdir(path):
            scandir(path, files)
    return files

# generate an Extension object from its dotted name
def makeExtension(extName):
    global libs
    extPath = extName.replace(".", os.path.sep)+".pyx"
    return Extension(
        extName,
        [extPath],include_dirs=[np.get_include()],language='c++',libraries=libs
        )

# get the list of extensions
extNames = scandir("gmatch4py")

# and build up the set of Extension objects
extensions = cythonize([makeExtension(name) for name in extNames])

setup(
    name="GMatch4py",
    description="A module for graph matching",
    packages=["gmatch4py","gmatch4py.helpers"],
    ext_modules=extensions,
    cmdclass={'build_ext': build_ext},
    setup_requires=["numpy","networkx","scipy"],
    install_requires=["numpy","networkx","scipy"],
    version="0.1"
)
#Clean cpp and compiled file
f=True
if f:
    if os.path.exists("build"):
        shutil.rmtree("build")
    os.system("find . -name \*.c -delete ; find . -name \*.cpp -delete ;")