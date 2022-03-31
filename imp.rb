require "formula"

class Imp < Formula
  desc "Integrative Modeling Platform"
  homepage "https://integrativemodeling.org/"
  url "https://integrativemodeling.org/2.16.0/download/imp-2.16.0.tar.gz"
  sha256 "8593a85c729f095fe2e9dd07673a9ad7a7afd4a230ed27ab5b8158809cf61889"
  license "LGPL/GPL"
  revision 6

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_monterey: "c249e6dcc5914ef4db666794212c528b0b448fb8169030ada09a488bd868ec74"
    sha256 monterey:       "f4fc5f0c4d8d7fe1476e944f86525176d12b84b152dcb5f381f28834c9ad9b4b"
    sha256 big_sur:        "1074ae9d589bc02f30019de3d874073da0a7106200bfc9ae6e522c898c554a6f"
    sha256 catalina:       "4b46da288c84557156fe44d950e394726cca0392fdd6cb6236d959fd24478047"
  end

  depends_on "cmake" => :build
  depends_on "pkg-config" => :build
  depends_on "swig" => :build

  depends_on "boost"
  depends_on "eigen"
  depends_on "fftw"
  depends_on "hdf5"
  depends_on "open-mpi"
  depends_on "protobuf"
  depends_on "python@3.9"
  depends_on "cgal" => :recommended
  depends_on "gsl" => :recommended
  depends_on "libtau" => :recommended
  depends_on "opencv" => :recommended

  def install
    ENV.cxx11
    version = Language::Python.major_minor_version Formula["python@3.9"].opt_bin/"python3"
    args = std_cmake_args
    args << "-DIMP_DISABLED_MODULES=scratch"
    args << ".."
    args << "-DCMAKE_INSTALL_PYTHONDIR=#{lib}/python#{version}/site-packages"
    # Otherwise linkage of _IMP_em2d.so fails on arm64 because it can't find
    # @rpath/libgcc_s.1.1.dylib
    gcclib = Formula["gcc"].lib/"gcc/11"
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
    mkdir "build" do
      system "cmake", *args
      pybins = []
      cd "bin" do
        pybins = Dir.glob("*")
      end
      system "make"
      system "make", "install"
      cd bin do
        # Make sure binaries use Homebrew Python
        inreplace pybins, %r{^#!.*python.*$},
                          "#!#{Formula["python@3.9"].opt_bin}/python3"
      end
    end
  end

  test do
    pythons = [Formula["python@3.9"].opt_bin/"python3"]
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
