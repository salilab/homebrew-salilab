require 'formula'

class Imp < Formula
  desc "The Integrative Modeling Platform"
  homepage 'https://integrativemodeling.org/'
  url 'https://integrativemodeling.org/2.10.1/download/imp-2.10.1.tar.gz'
  sha256 '53a99ae24c3c2bdabfcfa04a94df42b5f034ef689284351034bc82105daea5ec'

  bottle do
    root_url "https://dl.bintray.com/salilab/homebrew"
    sha256 "44090e51381f223cc6fb3b3c755d1b39f1abd0d7b72d25a03e7992c66b7f3ce7" => :mojave
    sha256 "e9a0c07fcb760ca90e306f9a71c6ed13dcc15bfce60f25a493ac03b3ffb96d7f" => :yosemite
    sha256 "9956bc55ab1d4de206a372d2f97e15b3be8100b4920d5a23a3e72f9b8f52e162" => :el_capitan
    sha256 "0e0cc452c4bfd241321545a9ffcdfdd93f990d6b2637060f5d1b0a37a9d49c5b" => :high_sierra
    sha256 "7bc37606167603eedbf583d4d3dd4170aad0c6d635d83ff9b2aed74af5cac526" => :sierra
  end

  depends_on 'cmake' => :build
  depends_on 'swig' => :build

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
    # Don't install in lib64 on Linux systems
    args << "-DCMAKE_INSTALL_LIBDIR=#{lib}"
    args << "-DCMAKE_INSTALL_PYTHONDIR=#{lib}/python#{pyver}/site-packages"
    # Don't link against gperftools, even if they were found, since then the
    # bottle won't work on systems without gperftools installed
    args << "-DGPerfTools_found=0"
    # Help cmake to find CGAL
    ENV["CGAL_DIR"] = Formula["cgal"].lib/"cmake/CGAL"
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
        python_framework = (Formula["python"].opt_prefix)/"Frameworks/Python.framework/Versions/#{version}"
        py3_lib = "#{python_framework}/lib/libpython#{version}.dylib"
        py3_inc = "#{python_framework}/Headers"
        args = ["..",
                "-DCMAKE_INSTALL_PYTHONDIR=#{lib}/python#{version}/site-packages",
                "-DSWIG_PYTHON_LIBRARIES=#{py3_lib}",
                "-DPYTHON_LIBRARIES=#{py3_lib}",
                "-DPYTHON_INCLUDE_DIRS=#{py3_inc}",
                "-DPYTHON_INCLUDE_PATH=#{py3_inc}"]
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
      system python, "-c", "import IMP, RMF, os; name = IMP.create_temporary_file_name('assignments', '.hdf5'); root = RMF.HDF5.create_file(name); del root; os.unlink(name)"
      system python, "-c", "import IMP.mpi; assert(IMP.mpi.__version__ == '#{version}')"
    end
    system "multifit"
    system "foxs"
  end

end
