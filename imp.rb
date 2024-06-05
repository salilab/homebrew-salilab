require "formula"

class Imp < Formula
  desc "Integrative Modeling Platform"
  homepage "https://integrativemodeling.org/"
  url "https://integrativemodeling.org/2.20.2/download/imp-2.20.2.tar.gz"
  sha256 "056b48f25f8c3de81c4ce73ce82c7bb1d550dfc936d57e0aaea0157dad7326cb"
  license "LGPL/GPL"
  revision 1

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_sonoma:   "54e6f97b87d2c738d43a46baac14b248167023d848aedeba62af6864c7665eb8"
    sha256 arm64_ventura:  "c6e51b89475e9d9550081c16df44c7d37aaf1a10ba3a729b18a28043c8c352c1"
    sha256 arm64_monterey: "f163051768907afa20dfae56154dfd25b9cf12a97be7ee6e77da5974c5fddf18"
    sha256 sonoma:         "b8be57a48b6dcd270a744bb35c61aa7b0004669be47f3e875b6f53ece180d7d8"
    sha256 ventura:        "3443e4ac7424dc3a4cce957c1ff65841cc89a6b0aa9991002a0b0f6d89821a0c"
    sha256 monterey:       "94e5d89a7df5119506b574e040659e17c2efdeb003a455cc5902f371af90e063"
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

  # Fix build with Boost 1.85, filesystem_error
  patch do
    url "https://github.com/salilab/imp/commit/b3a5ae88faa4eb06a7dcc4c53fb663a7471f17e1.patch?full_index=1"
    sha256 "e8deedc75f5e7dedf6ce7805f7af404fb49c0452103c0513f7377c50bec2648e"
  end

  # Fix build with Boost 1.85, filesystem::extension
  patch do
    url "https://github.com/salilab/imp/commit/627bb2d94ab406b19b27e64203a20d3494d2f770.patch?full_index=1"
    sha256 "df96108ae5847e896b065893e2b9b925cb7fd02d1812424108dd4b44684a7f4f"
  end

  # Fix failure to find boost::mpl::not_
  patch do
    url "https://integrativemodeling.org/2.20.2/patches/boost_not.patch"
    sha256 "4bdae7a3bf7ddeabe6369370864b2e676dc8b1974092feda00aab2794f72b8a7"
  end

  # We need C++17 support for protobuf
  fails_with gcc: "5"

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
