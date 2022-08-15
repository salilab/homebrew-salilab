require "formula"

class Imp < Formula
  desc "Integrative Modeling Platform"
  homepage "https://integrativemodeling.org/"
  url "https://integrativemodeling.org/2.17.0/download/imp-2.17.0.tar.gz"
  sha256 "2667f7a4f7b4830ba27e0d41e2cab0fc21ca22176625bfd8b2f353b283dfc8af"
  license "LGPL/GPL"
  revision 4

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_monterey: "36e91e9183048c4d4f85e7fbaca1377477c975d7761afab726c62abea16b2f88"
    sha256 monterey:       "bb1dce4879a6fd7658604fedd53669886433b4676bc664294e2d0df5629aea3f"
    sha256 big_sur:        "8296f07e800c930ae00739484d4765eddf5023c2136d0914d2479043847dc60d"
    sha256 catalina:       "c9d379450b5fd300651fbcf3821103a8dc6e5923622f75884e9e8cb240cd4410"
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
  depends_on "python@3.10"
  depends_on "cgal" => :recommended
  depends_on "gsl" => :recommended
  depends_on "libtau" => :recommended
  depends_on "opencv" => :recommended

  # Fix build with newer CGAL
  patch do
    url "https://github.com/salilab/imp/commit/c1522b37fb8bcf53c1d9738e30519a0a5c2b0831.patch?full_index=1"
    sha256 "6b5bc748a393b006dcd76bda02163d5b80b573cfb07a944d50bb49ef7dc8851f"
  end
  patch do
    url "https://github.com/salilab/imp/commit/806d3f182b4e8f23420f5cc6687a48836099b0c7.patch?full_index=1"
    sha256 "c10fc7b3913725f7123cbdbd14eec57a4126e11aaf0a5e53f541e02ad36937cf"
  end

  def install
    ENV.cxx11
    version = Language::Python.major_minor_version Formula["python@3.10"].opt_bin/"python3.10"
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
                          "#!#{Formula["python@3.10"].opt_bin}/python3.10"
      end
    end
  end

  test do
    pythons = [Formula["python@3.10"].opt_bin/"python3.10"]
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
