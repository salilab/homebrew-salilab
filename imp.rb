require 'formula'

class Imp < Formula
  desc "The Integrative Modeling Platform"
  homepage 'https://integrativemodeling.org/'
  url 'https://integrativemodeling.org/2.12.0/download/imp-2.12.0.tar.gz'
  sha256 '4e7a3103773961d381cf61242060d1d6ba986d971d06fa9ce151adb00de5e837'
  revision 5

  # Work around boost::betweenness_centrality_clustering compile error
  patch do
    url "https://github.com/salilab/imp/commit/5d494e7ba4769343d9add281eb2a658b1b4c6d2f.diff?full_index=1"
    sha256 "27b94702a6cf2dd45aa9306af7e1980fea988b8419e2b6367c0e5922885e6152"
  end

  # Fix to build with HDF5 1.10.6
  patch do
    url "https://github.com/salilab/imp/commit/0eb1fac37aca2a41e548ba16d5ffd6e469a55460.diff?full_index=1"
    sha256 "bbc158906ded645b37b8e06a3faf4cebabd91cdad36002f541413b98bd0e9018"
  end

  # Fix to build with HDF5 1.12
  patch do
    url "https://github.com/salilab/imp/commit/b5f703eb76a9ad9aed2a9684d41fead9ab4c2fbe.diff?full_index=1"
    sha256 "10486f0809bd5b3f9fdcd4c1a5d7492d727b65dc4f422ef9e3a53b853b4dea6c"
  end

  bottle do
    root_url "https://dl.bintray.com/salilab/homebrew"
    sha256 "241b275252cf2c88a9735ab1029ee1264157308ae3601cab55b0be618f971717" => :high_sierra
    sha256 "1bb5306c03c3c040ba402fc24721eb8b5d21816fa36fc35ad18c3acaf0bb5ca4" => :mojave
    sha256 "2c8f43629981e66ee63286cfdf5be9eda130351e431221e587b373e3ed7468e1" => :catalina
  end

  depends_on 'cmake' => :build
  depends_on 'swig' => :build
  depends_on 'pkg-config' => :build

  depends_on 'python' => :recommended

  depends_on 'boost'
  depends_on 'hdf5'
  depends_on 'fftw'
  depends_on 'eigen'
  depends_on 'protobuf'
  depends_on 'open-mpi'
  depends_on 'libtau' => :recommended
  depends_on 'cgal' => :recommended
  depends_on 'gsl' => :recommended
  depends_on 'opencv' => :recommended

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
      if build.with? 'python'
        version = Language::Python.major_minor_version "python3"
        args = ["..",
                "-DCMAKE_INSTALL_PYTHONDIR=#{lib}/python#{version}/site-packages",
                "-DUSE_PYTHON2=off"]
        system "cmake", *args
        system "make", "install"
        cd bin do
          # Make sure binaries use Homebrew Python
          inreplace pybins, %r{^#!.*python.*$},
                            "#!#{Formula["python"].opt_bin}/python3"
        end
      end
    end
  end

  test do
    Language::Python.each_python(build) do |python, pyver|
      system python, "-c", "import IMP; assert(IMP.__version__ == '#{version}')"
      system python, "-c", "import IMP.em2d; assert(IMP.em2d.__version__ == '#{version}')"
      system python, "-c", "import IMP.cgal; assert(IMP.cgal.__version__ == '#{version}')"
      system python, "-c", "import IMP.foxs; assert(IMP.foxs.__version__ == '#{version}')"
      system python, "-c", "import IMP.multifit; assert(IMP.multifit.__version__ == '#{version}')"
      system python, "-c", "import IMP.npctransport; assert(IMP.npctransport.__version__ == '#{version}')"
      system python, "-c", "import IMP.bayesianem; assert(IMP.bayesianem.__version__ == '#{version}')"
      system python, "-c", "import IMP, RMF, os; name = IMP.create_temporary_file_name('assignments', '.hdf5'); root = RMF.HDF5.create_file(name); del root; os.unlink(name)"
      system python, "-c", "import IMP.mpi; assert(IMP.mpi.__version__ == '#{version}')"
    end
    system "multifit"
    system "foxs"
  end

end
