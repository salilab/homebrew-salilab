require "formula"

class Imp < Formula
  desc "Integrative Modeling Platform"
  homepage "https://integrativemodeling.org/"
  url "https://integrativemodeling.org/2.19.0/download/imp-2.19.0.tar.gz"
  sha256 "75529285e6d94ffe5b4246097d70e223d984947193226b39313c1a85bc011ddd"
  license "LGPL/GPL"
  revision 7

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_sonoma:   "f62aba11906917a4d4cc350b7c0325e12e55371795ae68bacc5aa0f19e42fe94"
    sha256 arm64_ventura:  "97b3236af0a4ad0d85b7dd24b0086b3b9effa00b3a861c1b10fe494e9134974f"
    sha256 arm64_monterey: "6479166cf515cf45ab42ccb9d8045fcddf09be2b1986ef8f491b89b26b3fa91e"
    sha256 sonoma:         "9bf824cdd7d97e8e9233a12ae2ab486eb1e870851c5a6a94bbb2b8dd822a1116"
    sha256 ventura:        "93c58e2fc17af9f8f713b7d04af176febf33013a4321770dbb10f7b9ad3ccdb1"
    sha256 monterey:       "46571e55b589993c712957f26fda6d538249a404377f5802f4f28588a41c1b1b"
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
