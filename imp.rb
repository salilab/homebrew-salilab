require 'formula'

class Imp < Formula
  desc "The Integrative Modeling Platform"
  homepage 'https://integrativemodeling.org/'
  url 'https://integrativemodeling.org/2.12.0/download/imp-2.12.0.tar.gz'
  sha256 '4e7a3103773961d381cf61242060d1d6ba986d971d06fa9ce151adb00de5e837'
  revision 3

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

  bottle do
    root_url "https://dl.bintray.com/salilab/homebrew"
    sha256 "713643b06d5bb5653cd8910213067c9a0084da68e585b48f65a5cad05bb8bc5d" => :sierra
    sha256 "bb87d8d6b70be23db05cecfd90cd68151f5390fb16eb78bdcfd8a36796bcb4e2" => :high_sierra
    sha256 "f752ec089dcbfc1d9c8ad917b9fa78551bdee7c013e1b05722233df26a935c3a" => :mojave
    sha256 "adc8dceed17750078f23d12d3e2f0ec0ba8c208274a0119a58ad084935f3c268" => :catalina
  end

  depends_on 'cmake' => :build
  depends_on 'swig' => :build
  depends_on 'pkg-config' => :build

  depends_on 'python@2' => :recommended
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
      cd bin do
        # Make sure binaries use Homebrew Python, not some other Python in PATH
        inreplace pybins, %r{^#!.*python.*$},
                          "#!#{Formula["python@2"].opt_bin}/python2"
      end
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
