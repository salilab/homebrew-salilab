require "formula"

class Imp < Formula
  desc "Integrative Modeling Platform"
  homepage "https://integrativemodeling.org/"
  url "https://integrativemodeling.org/2.16.0/download/imp-2.16.0.tar.gz"
  sha256 "8593a85c729f095fe2e9dd07673a9ad7a7afd4a230ed27ab5b8158809cf61889"
  license "LGPL/GPL"
  revision 2

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_monterey: "c8d2df47574ee11fcadd6f1666db7f51af15e6b848f1339323ad606923b9f2de"
    sha256 arm64_big_sur:  "813f4c769bd86efc862f9e4c84dc36c63e6b4fed33e7818135970a6ec7a3f22c"
    sha256 monterey:       "5678ee7f977912564024e098d8973240d31bf81bda5f5de2aa1581b0cfb542d2"
    sha256 big_sur:        "ecd49372d46511f1787e6714285ef4a15af46d334181c56b4ec699cea1ff0f1f"
    sha256 catalina:       "2cf22cdec4aa964951c51b9a9087e1b51f03b775c31f9e91f725a7a0c22286b5"
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
  depends_on "cgal" => :recommended
  depends_on "gsl" => :recommended
  depends_on "libtau" => :recommended
  depends_on "opencv" => :recommended
  depends_on "python@3.9" => :recommended

  def install
    ENV.cxx11
    pyver = Language::Python.major_minor_version "python2.7"
    args = std_cmake_args
    args << "-DIMP_DISABLED_MODULES=scratch"
    args << ".."
    # Otherwise linkage of _IMP_em2d.so fails on arm64 because it can't find
    # @rpath/libgcc_s.1.1.dylib
    gcclib = Formula["gcc"].lib/"gcc/11"
    args << "-DCMAKE_MODULE_LINKER_FLAGS=-L#{gcclib}"
    # Don't install in lib64 on Linux systems
    args << "-DCMAKE_INSTALL_LIBDIR=#{lib}"
    args << "-DCMAKE_INSTALL_PYTHONDIR=#{lib}/python#{pyver}/site-packages"
    # Don't link against gperftools, even if they were found, since then the
    # bottle won't work on systems without gperftools installed
    args << "-DGPerfTools_found=0"
    # Help cmake to find CGAL
    ENV["CGAL_DIR"] = Formula["cgal"].lib/"cmake/CGAL"
    # Force Python 2
    args << "-DUSE_PYTHON2=on"
    mkdir "build" do
      system "cmake", *args
      pybins = []
      cd "bin" do
        pybins = Dir.glob("*")
      end
      system "make"
      system "make", "install"
      if build.with? "python@3.9"
        version = Language::Python.major_minor_version Formula["python@3.9"].opt_bin/"python3"
        args = ["..",
                "-DCMAKE_INSTALL_PYTHONDIR=#{lib}/python#{version}/site-packages",
                "-DUSE_PYTHON2=off"]
        system "cmake", *args
        system "make", "install"
        cd bin do
          # Make sure binaries use Homebrew Python
          inreplace pybins, %r{^#!.*python.*$},
                            "#!#{Formula["python@3.9"].opt_bin}/python3"
        end
      end
    end
  end

  test do
    pythons = [Formula["python@3.9"].opt_bin/"python3", "python2.7"]
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
