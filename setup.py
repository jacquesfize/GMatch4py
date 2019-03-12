#import setuptools
import sys, os, shutil
from distutils.core import setup
from distutils.extension import Extension
import numpy as np
import platform
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

    ## For Mojave Users
    if platform.system() == "Darwin":
        if "10.14" in platform.mac_ver()[0]:
            return Extension(
            extName,
            [extPath],include_dirs=[np.get_include()],language='c++',libraries=libs,
            extra_compile_args=["-stdlib=libc++"]
            )
    
    return Extension(
        extName,
        [extPath],include_dirs=[np.get_include()],language='c++',libraries=libs,
        #extra_compile_args = ["-O0", "-fopenmp"],extra_link_args=['-fopenmp']

        )

# get the list of extensions
extNames = scandir("gmatch4py")

# and build up the set of Extension objects
extensions = cythonize([makeExtension(name) for name in extNames])

from os import path
this_directory = path.abspath(path.dirname(__file__))
with open(path.join(this_directory, 'README.md'), encoding='utf-8') as f:
    long_description = f.read()

requirements=["numpy","networkx","scipy",'scikit-learn','tqdm','pandas',"joblib","gensim","psutil"]
setup(
    name="GMatch4py",
    author="Jacques Fize",
    description="A python module for graph matching (use Cython)",
    long_description=long_description,
    long_description_content_type='text/markdown',
    url="https://github.com/Jacobe2169/GMatch4py",
    packages=["gmatch4py"],
    ext_modules=extensions,
    cmdclass={'build_ext': build_ext},
    setup_requires=requirements,
    install_requires=requirements,
    version="0.2.5b",
    classifiers=[
            "Programming Language :: Python :: 3",
            "License :: OSI Approved :: MIT License",
            "Operating System :: OS Independent",
        ]
)
#Clean cpp and compiled file
f=True
if f:
    if os.path.exists("build"):
        shutil.rmtree("build")
    if os.path.exists("dist"):
        shutil.rmtree("dist")
    os.system("find . -name \*.c -delete ; find . -name \*.cpp -delete ;")