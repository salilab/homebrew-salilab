require "formula"

class Imp < Formula
  desc "Integrative Modeling Platform"
  homepage "https://integrativemodeling.org/"
  url "https://integrativemodeling.org/2.18.0/download/imp-2.18.0.tar.gz"
  sha256 "48ca1f1451bfe8c237a02cd58892b3aaaf6b0f15d9ac65f8048781a901f42ff5"
  license "LGPL/GPL"
  revision 7

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_ventura:  "cea67019c8e9cb81e2f8b0f6e391c4a8e2aa297fb15fe4365304e910cfae9a5c"
    sha256 arm64_monterey: "8a26295866990e871cd034ee7bac13a3079d3762532b80250ce05d0d378b4629"
    sha256 ventura:        "257cddaf0e6f7f0518a549389a096a859b88411753ca1adb2b66178ceb633cf6"
    sha256 monterey:       "b3b37e0b700bbbee8a0bcb248860fa2c14e175303cffc398d29b268e5d07cc5f"
    sha256 big_sur:        "ade19c3c7f18cc103de53f19c4189a0ebd9591417801a3d6398b046544b642af"
  end

  depends_on "cmake" => :build
  depends_on "pkg-config" => :build
  depends_on "swig" => :build

  depends_on "boost"
  depends_on "rmf"
  depends_on "ihm"
  depends_on "eigen"
  depends_on "fftw"
  depends_on "hdf5"
  depends_on "open-mpi"
  # Stick with old protobuf for now to match opencv
  depends_on "protobuf@21"
  depends_on "python@3.11"
  depends_on "cgal" => :recommended
  depends_on "gsl" => :recommended
  depends_on "libtau" => :recommended
  depends_on "opencv" => :recommended

  # Fix build with Boost 1.81
  patch do
    url "https://github.com/salilab/imp/commit/c8863fc2047c0462d233780bec1fdc661b3ce913.patch?full_index=1"
    sha256 "dc0987efe8b23d802ad0cab41e303693d3a3d5f75866e742672ce42d7cc79a67"
  end

  def install
    ENV.cxx11
    pybin = Formula["python@3.11"].opt_bin/"python3.11"
    pyver = Language::Python.major_minor_version pybin
    args = std_cmake_args
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
    # Use older protobuf for now to match opencv
    ENV.prepend_path "PATH", #{Formula["protobuf@21"].bin}
    args << "-DCMAKE_INCLUDE_PATH=#{Formula['protobuf@21'].include}"
    args << "-DCMAKE_LIBRARY_PATH=#{Formula['protobuf@21'].opt_lib}"
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
