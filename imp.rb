require 'formula'

class Imp < Formula
  desc "The Integrative Modeling Platform"
  homepage 'https://integrativemodeling.org/'
  url 'https://integrativemodeling.org/2.8.0/download/imp-2.8.0.tar.gz'
  sha256 '83a23c56f0be9de8900d0edd3978eb8c2637e6d5086f7ef7e2cd61f0b7a5aa80'
  revision 12

  # Fix to work with latest CGAL (4.11)
  patch do
    url "https://github.com/salilab/imp/commit/a8ef53c.patch?full_index=1"
    sha256 "bf712504c1452aab3608d239bc973a56a7d6c05a2a420bac6677e7588c146bcf"
  end
  patch do
    url "https://github.com/salilab/imp/commit/2a3fa49.patch?full_index=1"
    sha256 "af65bd533f32e90a3ac7a72c14d1e77d8ecdd4a662f75737b0278c3caca772fc"
  end

  bottle do
    root_url "https://integrativemodeling.org/2.8.0/download/homebrew"
    sha256 "92e20670340c97847b1c0ef918c9727dcb17e6616ae7dc931ffb7b17338ebfbc" => :high_sierra
    sha256 "d3a241af5e323d0430bf7a46212255e1a5f12ffc04bb6c410eb3344930a098a5" => :el_capitan
    sha256 "4396d83009f4ea32a2963fc436a65e20be258ac7712c9228d52d3b8afee3c2e9" => :yosemite
  end

  depends_on 'cmake' => :build
  depends_on 'swig' => :build

  depends_on 'python@2' => :recommended
  depends_on 'python' => :recommended

  depends_on 'boost'
  depends_on 'hdf5'
  depends_on 'fftw'
  depends_on 'libtau' => :recommended
  depends_on 'cgal' => :recommended
  depends_on 'gsl' => :recommended
  depends_on 'opencv' => :recommended

  # We need boost compiled with c++11 support on Linux
  needs :cxx11 if OS.linux?

  def install
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
    mkdir "build" do
      system "cmake", *args
      system "make"
      system "make", "install"
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
      end
    end
  end

  test do
    Language::Python.each_python(build) do |python, version|
      system python, "-c", "import IMP"
      system python, "-c", "import IMP.em2d"
      system python, "-c", "import IMP.foxs"
      system python, "-c", "import IMP.multifit"
    end
    system "multifit"
    system "foxs"
  end

end
