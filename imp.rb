require "formula"

class Imp < Formula
  desc "Integrative Modeling Platform"
  homepage "https://integrativemodeling.org/"
  url "https://integrativemodeling.org/2.19.0/download/imp-2.19.0.tar.gz"
  sha256 "75529285e6d94ffe5b4246097d70e223d984947193226b39313c1a85bc011ddd"
  license "LGPL/GPL"
  revision 5

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_sonoma:   "88656eaa4bdd7d914f8f24d99124db2bbbeb3b63882736f5d8388ecfa289975d"
    sha256 arm64_ventura:  "92b88abcdb13c84c9a9ee6ef129afd690b6afe4ba0477b6b8c591628c4dcba5c"
    sha256 arm64_monterey: "0840982578bbf452a336ae179127f7596f733129b91884805724454175f5a602"
    sha256 sonoma:         "a1ef87be74d2dc5f0112b93ca0271f8ececb36530f3d83da0c216d84453bc074"
    sha256 ventura:        "b33a88b63fb8c51954ff6f986322225b16186658813f8011dcc769c991214c24"
    sha256 monterey:       "105cae867e0054031b7b298ad11e4902a5c3628acc67fc3d4674159ecf734220"
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
  depends_on "python@3.11"
  depends_on "cgal" => :recommended
  depends_on "gsl" => :recommended
  depends_on "libtau" => :recommended
  depends_on "opencv" => :recommended

  # We need C++17 support for protobuf
  fails_with gcc: "5"

  def install
    pybin = Formula["python@3.11"].opt_bin/"python3.11"
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
    pythons = [Formula["python@3.11"].opt_bin/"python3.11"]
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
