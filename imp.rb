require "formula"

class Imp < Formula
  desc "Integrative Modeling Platform"
  homepage "https://integrativemodeling.org/"
  url "https://integrativemodeling.org/2.24.0/download/imp-2.24.0.tar.gz"
  sha256 "e5ad6795bc950ac24d98983ec0c6799c9de3998b66592ce0e8cb611d826febc9"
  license "LGPL/GPL"
  revision 6

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_tahoe:   "b314c3a07f7192d7e76fee4701055aa0521fdce9b1dda1d120ed8f457feeb0d4"
    sha256 arm64_sequoia: "ba645f12e9aab6b9c764e80525b038d3810bf9dbaf083124ffef8aec9d6fb7cb"
    sha256 arm64_sonoma:  "d58c1a97735a649af3f8912b12ff0da7bef73a9824d49489972892403b1500ed"
    sha256 tahoe:         "2f98b78714cd74d77d8676969c28f9c1b18df98535f919fadd2816ffcd0fd2bf"
    sha256 sequoia:       "70d7e85e127a5b87f49dc0d07eb2e4bd4b2e4eb2757d7d64317100e8ecc4f250"
    sha256 sonoma:        "7395e761941b1931e12b998aa1d06f5b8ec420952f61b918d428bfd20e4e9c2a"
  end

  depends_on "cmake" => :build
  depends_on "pkg-config" => :build
  depends_on "swig" => :build
  depends_on "cereal" => :build

  depends_on "boost"
  depends_on "salilab/salilab/rmf"
  depends_on "salilab/salilab/ihm"
  depends_on "eigen"
  depends_on "fftw"
  depends_on "hdf5"
  depends_on "open-mpi"
  depends_on "protobuf"
  depends_on "python@3.14"
  depends_on "cgal" => :recommended
  depends_on "gsl" => :recommended
  depends_on "libtau" => :recommended
  depends_on "opencv" => :recommended

  # We need C++17 support for protobuf
  fails_with gcc: "5"

  # Fix build with OpenCV 5
  patch :DATA

  def install
    pybin = Formula["python@3.14"].opt_bin/"python3.14"
    pyver = Language::Python.major_minor_version pybin
    args = std_cmake_args
    args << "-DCMAKE_CXX_FLAGS='-std=c++17'"
    args << "-DIMP_DISABLED_MODULES=scratch"
    args << "-DIMP_USE_SYSTEM_RMF=on"
    args << "-DIMP_USE_SYSTEM_IHM=on"
    args << ".."
    args << "-DCMAKE_INSTALL_PYTHONDIR=#{lib}/python#{pyver}/site-packages"
    # Otherwise linkage of _IMP_em2d.so fails on arm64 because it can't find
    # @rpath/libgcc_s.1.1.dylib
    gcclib = Formula["gcc"].lib/"gcc/current"
    args << "-DCMAKE_MODULE_LINKER_FLAGS=-L#{gcclib}"
    # Don't install in lib64 on Linux systems
    args << "-DCMAKE_INSTALL_LIBDIR=#{lib}"
    # Don't link against gperftools, even if they were found, since then the
    # bottle won't work on systems without gperftools installed
    args << "-DGPerfTools_found=0"
    # Don't link against log4cxx, even if available, since then the
    # bottle won't work on systems without log4cxx installed
    args << "-DLog4CXX_LIBRARY=Log4CXX_LIBRARY-NOTFOUND"
    args << "-DIMP_NO_LOG4CXX=1"
    # Help cmake to find CGAL
    ENV["CGAL_DIR"] = Formula["cgal"].lib/"cmake/CGAL"
    # Make sure we use Homebrew Python
    args << "-DPython3_EXECUTABLE:FILEPATH=#{pybin}"
    mkdir "build" do
      system "cmake", *args
      imppybins = []
      cd "bin" do
        imppybins = Dir.glob("*")
      end
      system "make"
      system "make", "install"
      cd bin do
        # Make sure binaries use Homebrew Python
        inreplace imppybins, %r{^#!.*python.*$}, "#!#{pybin}"
      end
    end
  end

  test do
    pythons = [Formula["python@3.14"].opt_bin/"python3.14"]
    pythons.each do |python|
      system python, "-c", "import IMP; assert(IMP.__version__ == '#{version}')"
      system python, "-c", "import IMP.em2d; assert(IMP.em2d.__version__ == '#{version}')"
      system python, "-c", "import IMP.cgal; assert(IMP.cgal.__version__ == '#{version}')"
      system python, "-c", "import IMP.foxs; assert(IMP.foxs.__version__ == '#{version}')"
      system python, "-c", "import IMP.multifit; assert(IMP.multifit.__version__ == '#{version}')"
      system python, "-c", "import IMP.npctransport; assert(IMP.npctransport.__version__ == '#{version}')"
      system python, "-c", "import IMP.bayesianem; assert(IMP.bayesianem.__version__ == '#{version}')"
      system python, "-c", "import IMP.sampcon; assert(IMP.sampcon.__version__ == '#{version}')"
      system python, "-c", "import IMP, RMF, os; name = IMP.create_temporary_file_name('assignments', '.hdf5'); root = RMF.HDF5.create_file(name); del root; os.unlink(name)"
      system python, "-c", "import IMP.rmf, RMF; b = RMF.BufferHandle(); r = RMF.create_rmf_buffer(b); m = IMP.Model(); p = IMP.Particle(m); IMP.rmf.add_particle(r, p)"
      system python, "-c", "import IMP.mpi; assert(IMP.mpi.__version__ == '#{version}')"
    end
    system "multifit"
    system "foxs"
  end
end

__END__
diff --git a/modules/em2d/Setup.cmake b/modules/em2d/Setup.cmake
index 6c74423d6c..f9711591fd 100644
--- a/modules/em2d/Setup.cmake
+++ b/modules/em2d/Setup.cmake
@@ -1,5 +1,5 @@
-if("${OPENCV3_LIBRARIES}" STREQUAL "" AND "${OPENCV22_LIBRARIES}" STREQUAL "" AND "${OPENCV21_LIBRARIES}" STREQUAL "")
-  message(STATUS "Required dependency of OpenCV 2.1 or later not found")
+if("${OPENCV3_LIBRARIES}" STREQUAL "" AND "${OPENCV5_LIBRARIES}" STREQUAL "")
+  message(STATUS "Required dependency of OpenCV 3 or later not found")
 # disable em2d
   file(STRINGS ${CMAKE_BINARY_DIR}/build_info/disabled disabled)
   list(APPEND disabled "em2d")
diff --git a/modules/em2d/dependencies.py b/modules/em2d/dependencies.py
index f7cb2515f9..5bbeaa4ff1 100644
--- a/modules/em2d/dependencies.py
+++ b/modules/em2d/dependencies.py
@@ -1,3 +1,3 @@
 required_modules = 'container:core:atom:algebra:em:display:gsl:domino'
 required_dependencies = 'FFTW3:Boost.ProgramOptions:Boost.FileSystem'
-optional_dependencies = 'OpenCV21:OpenCV22:OpenCV3'
+optional_dependencies = 'OpenCV3:OpenCV5'
diff --git a/modules/em2d/dependency/OpenCV3.description b/modules/em2d/dependency/OpenCV3.description
index 2b502773a7..6d5eb53f0b 100644
--- a/modules/em2d/dependency/OpenCV3.description
+++ b/modules/em2d/dependency/OpenCV3.description
@@ -1,12 +1,12 @@
-full_name="OpenCV 3 or later"
+full_name="OpenCV 3 or 4"
 pkg_config_name="opencv4:opencv"
 libraries="opencv_core:opencv_imgproc:opencv_highgui:opencv_imgcodecs"
 headers="opencv2/core/core.hpp:opencv2/imgproc/imgproc.hpp:opencv2/highgui/highgui.hpp:opencv2/core/version.hpp"
 body="""
-#if CV_MAJOR_VERSION>=3
+#if CV_MAJOR_VERSION>=3 && CV_MAJOR_VERSION < 5
 new cv::Mat();
 #else
-#error "Version is not at least 3.0"
+#error "Version is not at least 3.0 and less than 5.0"
 #endif
 """
 versionheader="opencv2/core/version.hpp"
diff --git a/modules/em2d/dependency/OpenCV5.description b/modules/em2d/dependency/OpenCV5.description
new file mode 100644
index 0000000000..e01e5dc2e1
--- /dev/null
+++ b/modules/em2d/dependency/OpenCV5.description
@@ -0,0 +1,13 @@
+full_name="OpenCV 5 or later"
+pkg_config_name="opencv5"
+libraries="opencv_core:opencv_imgproc:opencv_highgui:opencv_imgcodecs:opencv_geometry"
+headers="opencv2/core/core.hpp:opencv2/imgproc/imgproc.hpp:opencv2/highgui/highgui.hpp:opencv2/core/version.hpp"
+body="""
+#if CV_MAJOR_VERSION>=5
+new cv::Mat();
+#else
+#error "Version is not at least 5.0"
+#endif
+"""
+versionheader="opencv2/core/version.hpp"
+versioncpp="CV_MAJOR_VERSION:CV_MINOR_VERSION:CV_SUBMINOR_VERSION"
diff --git a/modules/em2d/include/opencv_interface.h b/modules/em2d/include/opencv_interface.h
index 3fcee7da92..4f7655b64b 100644
--- a/modules/em2d/include/opencv_interface.h
+++ b/modules/em2d/include/opencv_interface.h
@@ -1,7 +1,7 @@
 /**
  *  \file IMP/em2d/opencv_interface.h
  *  \brief Interface with OpenCV
- *  Copyright 2007-2022 IMP Inventors. All rights reserved.
+ *  Copyright 2007-2026 IMP Inventors. All rights reserved.
 */
 
 #ifndef IMPEM2D_OPENCV_INTERFACE_H
@@ -10,14 +10,14 @@
 #include <IMP/em2d/em2d_config.h>
 #include "IMP/algebra/Transformation2D.h"
 
-#if IMP_EM2D_HAS_OPENCV22 || IMP_EM2D_HAS_OPENCV3
 #include "opencv2/core/core.hpp"
 #include "opencv2/core/version.hpp"
 #include "opencv2/imgproc/imgproc.hpp"
 #include "opencv2/highgui/highgui.hpp"
-#else
-#include "opencv/cv.h"
-#include "opencv/highgui.h"
+
+// OpenCV 5 includes
+#if !defined(CV_VERSION_EPOCH) && CV_VERSION_MAJOR >= 5
+# include <opencv2/geometry/2d.hpp>
 #endif
 
 #include <iostream>
