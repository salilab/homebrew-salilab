require "formula"

class Imp < Formula
  desc "Integrative Modeling Platform"
  homepage "https://integrativemodeling.org/"
  url "https://integrativemodeling.org/2.13.0/download/imp-2.13.0.tar.gz"
  sha256 "528aeed272e35d79028af0e215a41c086c09782cef59ee3f983d52bff8653bfc"
  license "LGPL/GPL"
  revision 5

  bottle do
    root_url "https://dl.bintray.com/salilab/homebrew"
    sha256 "26e683e8f7be80e4701746b8fb49345aeb9d336ffaa577e9cc193415671db80a" => :catalina
    sha256 "baeb61e0f1bfb725dc653b18baf7a377d5b8604a9587ee729a46fb1a1723b1b9" => :mojave
    sha256 "b51425a05bb38b3dfd1b95b58d863f217a93936167be1749b86375effe1c80db" => :high_sierra
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

  # Make sure each module has __version__
  patch do
    url "https://github.com/salilab/imp/commit/17be5981c6b631d9aef8ac7f11739baecde10f19.patch?full_index=1"
    sha256 "9d714f878b4018bc3d2a57f5724dd60cc4ff993ed7a7e54132e0c38b94de3451"
  end

  # Fix build with Boost 1.73
  patch do
    url "https://github.com/salilab/imp/commit/c6ef3b67de787e0475be6227cac1442033432909.patch?full_index=1"
    sha256 "cb3b760cdb2c4a3983cfc43abef4b46f8a24303d21ef698c9e60249eb8461497"
  end

  # Fix build with Boost 1.74
  patch do
    url "https://github.com/salilab/imp/commit/0ea7f7a4dbf3294dbc63a728ead787b1325008ee.patch?full_index=1"
    sha256 "36d2cd93a366e5b4e1eb10beb1cbb26157bce67b864161099c97f3af36bb03f0"
  end

  # Fix build with CGAL 5.1
  patch do
    url "https://github.com/salilab/imp/commit/879b8d2544ec66d9663b574296eb37ff62c5adfa.patch?full_index=1"
    sha256 "342a2a2c036df0dc324ae08f1c672cca8f67a9e81f346b75bd8a6471f3f16d27"
  end

  def install
    ENV.cxx11
    pyver = Language::Python.major_minor_version "python2.7"
    args = std_cmake_args
    args << "-DIMP_DISABLED_MODULES=scratch"
    args << ".."
    # We need explicit C++11 in order for the OpenCV compile test to work
    args << '-DCMAKE_CXX_FLAGS="-std=c++11"'
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
      if build.with? "python@3.8"
        version = Language::Python.major_minor_version Formula["python@3.8"].opt_bin/"python3"
        args = ["..",
                "-DCMAKE_INSTALL_PYTHONDIR=#{lib}/python#{version}/site-packages",
                "-DUSE_PYTHON2=off"]
        system "cmake", *args
        system "make", "install"
        cd bin do
          # Make sure binaries use Homebrew Python
          inreplace pybins, %r{^#!.*python.*$},
                            "#!#{Formula["python@3.8"].opt_bin}/python3"
        end
      end
    end
  end

  test do
    pythons = [Formula["python@3.8"].opt_bin/"python3", "python2.7"]
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
