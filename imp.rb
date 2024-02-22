require "formula"

class Imp < Formula
  desc "Integrative Modeling Platform"
  homepage "https://integrativemodeling.org/"
  url "https://integrativemodeling.org/2.20.1/download/imp-2.20.1.tar.gz"
  sha256 "9cf1173f3c2eba3ae65d0f62a6ecf35d8ccbea64988de5818bbafa69ef125186"
  license "LGPL/GPL"
  revision 3

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_sonoma:   "0254e485ec079e445d6602f2f6926b946ba8fc12f634704f42b9df55f49be78f"
    sha256 arm64_ventura:  "a22b9fb606dbe228519235c5eaba3631f6373d7aa3a1d5ea2d791e20c1431358"
    sha256 arm64_monterey: "e965cf686caa3a0620c2fd5c95cdb81a0f3788c117fbf2be6476846bbe902a70"
    sha256 sonoma:         "422062489bc03a517bf7fcdeb27aa4e04359bdf1589175d61a7c5d3da8c1bb1f"
    sha256 ventura:        "394a7bb463e453bfcf9b4e588ef8018ff4c197fae8c912044c526dd365033f0a"
    sha256 monterey:       "c775b6bd64f8647b71b86a70a1e62ff63a11fe3f75db7e8ec118445402e21821"
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
