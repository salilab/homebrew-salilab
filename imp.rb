require "formula"

class Imp < Formula
  desc "Integrative Modeling Platform"
  homepage "https://integrativemodeling.org/"
  url "https://integrativemodeling.org/2.23.0/download/imp-2.23.0.tar.gz"
  sha256 "18300beeae294a4917fb112bc697364292118184250acfd8ac76b88023281f20"
  license "LGPL/GPL"
  revision 3

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_sequoia: "a0731e45fe6216ddf182264641af2e04a1c60e94e39184cb0095a4241d600c5a"
    sha256 arm64_sonoma:  "fcccb49a628de9b770e8752dfde59a2a08b6f56fffd993641defa8158368fd8e"
    sha256 arm64_ventura: "be87b4a700396d5f7bd893b20a459d6159e758a1272316ee14e830b40436841e"
    sha256 sequoia:       "6d1fa7a176154cf43e99697377446f8bbfc055e10097ae9639760ecec1b4ff1b"
    sha256 sonoma:        "3d40f04545dca6c1a464964e16a8d0db259de4d994f7b601770876cc4473ec35"
    sha256 ventura:       "42560e5ef5519ad66229a11ea5c7311d017871486304b592a1894be85ddae3c4"
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
