import sys, os
from distutils.core import setup
from distutils.extension import Extension

# we'd better have Cython installed, or it's a no-go
from Cython.Build import cythonize

try:
    from Cython.Distutils import build_ext
except:
    print("You don't seem to have Cython installed. Please get a")
    print("copy from www.cython.org and install it")
    sys.exit(1)


# scan the 'dvedit' directory for extension files, converting
# them to extension names in dotted notation
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
    extPath = extName.replace(".", os.path.sep) + ".pyx"
    return Extension(
        extName,
        [extPath],
        language="c++",
        extra_compile_args=["-O3", "-Wall", '-std=c++11', '-v'],
    )


# get the list of extensions
extNames = scandir("gmatch4py")

# and build up the set of Extension objects
extensions = cythonize([makeExtension(name) for name in extNames])

# finally, we can pass all this to distutils
setup(
    name="Gmatch4py",
    description="A module for graph matching",
    packages=["gmatch4py", "gmatch4py.ged", "gmatch4py.kernels"],
    ext_modules=extensions,
    cmdclass={'build_ext': build_ext},
    setup_requires=["numpy"],
    install_requires=["numpy"]
)
