require "formula"

class Imp < Formula
  desc "Integrative Modeling Platform"
  homepage "https://integrativemodeling.org/"
  url "https://integrativemodeling.org/2.23.0/download/imp-2.23.0.tar.gz"
  sha256 "18300beeae294a4917fb112bc697364292118184250acfd8ac76b88023281f20"
  license "LGPL/GPL"
  revision 7

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_sequoia: "482bbacbb0d9d59a0cefeeaad37ad98f9679ad67d15087175a732ed87b6cd975"
    sha256 arm64_sonoma:  "329702bc0f7e06487333d3bf1fce83ecbd490d97ee6325b273b1a184f31911ad"
    sha256 arm64_ventura: "a49b5459c5317b7b76293791a3448271d85a38011fca4fae6b77901a87b30f56"
    sha256 sequoia:       "72356991377669face525c3bb08f31f65077153025a3df4a4d35de55f3690d43"
    sha256 sonoma:        "a66c66958fa10e581bd159a8d43a171211fe18a638d344b47552a526317c5634"
    sha256 ventura:       "e1e6ac4199c5eb0e2726c4da3945bcf2c7bd2248c0837f30a19b280fc24fb847"
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
  depends_on "python@3.13"
  depends_on "cgal" => :recommended
  depends_on "gsl" => :recommended
  depends_on "libtau" => :recommended
  depends_on "opencv" => :recommended

  # We need C++17 support for protobuf
  fails_with gcc: "5"

  # Fix build with protobuf v30
  patch :DATA

  # Fix build with Boost 1.89
  patch do
    url "https://github.com/salilab/imp/commit/be6117f488ed78646e382421ae41394419f449ea.patch?full_index=1"
    sha256 "0e0341fb0826b0fe292a415f67eaec590bc5229454f231348e7315306e82ad87"
  end

  def install
    pybin = Formula["python@3.13"].opt_bin/"python3.13"
    pyver = Language::Python.major_minor_version pybin
    args = std_cmake_args
    # Work around boost/clang incompatibility
    args << "-DCMAKE_CXX_FLAGS='-std=c++17 -D_LIBCPP_ENABLE_CXX17_REMOVED_UNARY_BINARY_FUNCTION'"
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
    pythons = [Formula["python@3.13"].opt_bin/"python3.13"]
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
      system python, "-c", "import IMP.mpi; assert(IMP.mpi.__version__ == '#{version}')"
    end
    system "multifit"
    system "foxs"
  end
end
__END__
diff --git a/modules/npctransport/src/protobuf.cpp b/modules/npctransport/src/protobuf.cpp
index 7e8cbad..d162fa6 100644
--- a/modules/npctransport/src/protobuf.cpp
+++ b/modules/npctransport/src/protobuf.cpp
@@ -61,7 +61,8 @@ namespace {
             show_ranges(oss.str(), &r->GetRepeatedMessage(*message, fd, i));
           }
         } else {
-          show_ranges(fd->name(), &r->GetMessage(*message, fd));
+          show_ranges(static_cast<std::string>(fd->name()),
+                      &r->GetMessage(*message, fd));
         }
       }
       }
@@ -209,12 +210,14 @@ namespace {
             int sz = in_r->FieldSize(*in_message, in_fd);
             for (int i = 0; i < sz; ++i) {
               ret +=
-                get_ranges(in_fd->name(), &in_r->GetRepeatedMessage(*in_message, in_fd, i),
+                get_ranges(static_cast<std::string>(in_fd->name()),
+                           &in_r->GetRepeatedMessage(*in_message, in_fd, i),
                            out_r->AddMessage(out_message, out_fd));
               // IMP_LOG(VERBOSE, "Got " << IMP::Showable(ret) << std::endl);
             }
           } else { // not repeated:
-            ret += get_ranges(in_fd->name(), &in_r->GetMessage(*in_message, in_fd),
+            ret += get_ranges(static_cast<std::string>(in_fd->name()),
+                              &in_r->GetMessage(*in_message, in_fd),
                               out_r->MutableMessage(out_message, out_fd));
             // IMP_LOG(VERBOSE, "Got " << IMP::Showable(ret) << std::endl);
           }
