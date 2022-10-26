require "formula"

class Imp < Formula
  desc "Integrative Modeling Platform"
  homepage "https://integrativemodeling.org/"
  url "https://integrativemodeling.org/2.17.0/download/imp-2.17.0.tar.gz"
  sha256 "2667f7a4f7b4830ba27e0d41e2cab0fc21ca22176625bfd8b2f353b283dfc8af"
  license "LGPL/GPL"
  revision 5

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_ventura:  "fff87118d13b82862e6eef1c4382283447931d2c41a3f06e3004511efc040011"
    sha256 arm64_monterey: "1cf6b5c2745731b67150e5370adb209594b9cfa0d2f8328273df3d0fefb94c12"
    sha256 ventura:        "7bfe659e3da2516f1ec2313bd59c8e938c3ed16bf9a20e8a3043644152812a9c"
    sha256 monterey:       "6e9ade5f353a12ea1b055ac3947aa46c63ae83a0736bb69d18921c4fa7cb1a3f"
    sha256 big_sur:        "c175136aa9bbb32de1c08f7e4f0c091c87b0416a5ad950181419abc473a35930"
    sha256 catalina:       "23f45609781b2c2d6c89bb310d90afa824a37c096fb98707daf2effddadfbf12"
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
