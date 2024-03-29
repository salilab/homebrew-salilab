require "formula"

class Imp < Formula
  desc "Integrative Modeling Platform"
  homepage "https://integrativemodeling.org/"
  url "https://integrativemodeling.org/2.20.1/download/imp-2.20.1.tar.gz"
  sha256 "9cf1173f3c2eba3ae65d0f62a6ecf35d8ccbea64988de5818bbafa69ef125186"
  license "LGPL/GPL"
  revision 4

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_sonoma:   "b0f513e1dc591eadc5fa5fc3786c1bbf8c0b20180e4f1049a981a799aa7af294"
    sha256 arm64_ventura:  "b611375f30b0e9212ce29340d065f7b8c23efd0a8e9e5c56e79815a043120b52"
    sha256 arm64_monterey: "fda169b7681ecd92a2b67076b425d58295528bb64a6e8c59e7e784194c392f1b"
    sha256 sonoma:         "0eddc0522ea339cff1d3aae56e27e28cb4f7da444b5316043a16b90db9718e59"
    sha256 ventura:        "3fe08f69077bed9cf32c6fe6bae1e44aaaf750fb17792d024a6f7a8c17e60430"
    sha256 monterey:       "4a8412476fb8a59b355222f72d7505743e8eb737ea3d849c456392304e0714c7"
  end

  depends_on "cmake" => :build
  depends_on "pkg-config" => :build
  depends_on "swig" => :build
  depends_on "cereal" => :build

  depends_on "boost"
  depends_on "rmf"
  depends_on "ihm"
  depends_on "eigen"
  depends_on "fftw"
  depends_on "hdf5"
  depends_on "open-mpi"
  depends_on "protobuf"
  depends_on "python@3.12"
  depends_on "cgal" => :recommended
  depends_on "gsl" => :recommended
  depends_on "libtau" => :recommended
  depends_on "opencv" => :recommended

  # We need C++17 support for protobuf
  fails_with gcc: "5"

  # Force cereal for serializing boost::unordered_map
  patch do
    url "https://github.com/salilab/imp/commit/b9b18196d9b31165191068e1e3db3950d6883b86.patch?full_index=1"
    sha256 "ea6508f9060a90bd76cf77b3c8fdb36d2ec766371515ad3a669d99db0c2912e0"
  end

  # Hide use of nested classes from SWIG
  patch do
    url "https://github.com/salilab/imp/commit/2742effffe0bf69bfb7281104ee3aa7c7b29eca5.patch?full_index=1"
    sha256 "984c8cc4a0cd36dc69e34fef1a08d61c28cfdbc3ff3c74832193bc56910a25c9"
  end

  def install
    pybin = Formula["python@3.12"].opt_bin/"python3.12"
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
    # Force Python 3
    args << "-DUSE_PYTHON2=off"
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
    pythons = [Formula["python@3.12"].opt_bin/"python3.12"]
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
