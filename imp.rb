require 'formula'

class Imp < Formula
  desc "The Integrative Modeling Platform"
  homepage 'https://integrativemodeling.org/'
  url 'https://integrativemodeling.org/2.13.0/download/imp-2.13.0.tar.gz'
  sha256 '528aeed272e35d79028af0e215a41c086c09782cef59ee3f983d52bff8653bfc'

  # Make sure each module has __version__
  patch do
    url "https://github.com/salilab/imp/commit/17be5981c6b631d9aef8ac7f11739baecde10f19.diff?full_index=1"
    sha256 "f454fca74610afe86a9468e488699158c6ca27fa3eec6906e5c92f1bc0cd8f7e"
  end

  bottle do
    root_url "https://dl.bintray.com/salilab/homebrew"
    sha256 "3f58c25215096f89d24a747aa9cd99b13993ae69d11ce23d8295dfc4e3578d36" => :high_sierra
    sha256 "3f40c0d65a0b278ce14e506ec1266cc766c65656ce5440d6f17af0a218e6f655" => :mojave
    sha256 "3df62890818b6ac41f293065a524b52cd21b9bc5a378f8d133cc4b1e7a243b1d" => :catalina
  end

  depends_on 'cmake' => :build
  depends_on 'swig' => :build
  depends_on 'pkg-config' => :build

  depends_on 'python@3.8' => :recommended

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
      if build.with? 'python@3.8'
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
    pythons = [ Formula["python@3.8"].opt_bin/"python3", "python2.7" ]
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

  def caveats
    <<~EOS
      IMP has been built to work with the latest version of Python 3
      supported by Homebrew, Python 3.8.

      Note that currently this is not in Homebrew's default path.
      See "brew info python@3.8" for the full path to Python 3.8 and
      instructions on how to add it to the default PATH.
    EOS
  end

end
