require 'formula'

class Imp < Formula
  desc "The Integrative Modeling Platform"
  homepage 'https://integrativemodeling.org/'
  url 'https://integrativemodeling.org/2.8.0/download/imp-2.8.0.tar.gz'
  sha256 '83a23c56f0be9de8900d0edd3978eb8c2637e6d5086f7ef7e2cd61f0b7a5aa80'
  revision 10

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
    sha256 "d73cf1600e479a889cb775f2f75d2a89ea02d3761cce1df22f75cbbcad2dda54" => :yosemite
    sha256 "4a8e12024df8d25d3bb87bd1c103c8696d24e706fed38a3fc44319fa91cc2ea1" => :el_capitan
    sha256 "c75f0fe94dd604da9aae8fc3599b1aa08291b7dcb027c8da0e525ee6b3e36970" => :high_sierra
  end

  depends_on 'cmake' => :build
  depends_on 'swig' => :build

  depends_on 'python' => :recommended
  depends_on 'python3' => :recommended

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
    pyver = Language::Python.major_minor_version "python"
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
      if build.with? 'python3'
        version = Language::Python.major_minor_version "python3"
        python_framework = (Formula["python3"].opt_prefix)/"Frameworks/Python.framework/Versions/#{version}"
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
