require 'formula'

class Imp < Formula
  desc "The Integrative Modeling Platform"
  homepage 'https://integrativemodeling.org/'
  url 'https://integrativemodeling.org/2.7.0/download/imp-2.7.0.tar.gz'
  sha256 '877af254567051c78317ea94730dfff742aa56d21aefd71edf14a3f4b153b036'
  revision 3

  # Fix OpenMP support to work with latest cmake
  patch do
    url "https://github.com/salilab/imp/commit/ca6e758.patch?full_index=1"
    sha256 "cd65fc25285ed8efa6072730a95628d57f2c119356f9fc3e51a693486abb4138"
  end

  bottle do
    root_url "https://integrativemodeling.org/2.7.0/download/homebrew"
    sha256 "47e2d06f72be25c6b0498e72e8fccbeca002ee59eed2b6ff34e0c40bf0792f84" => :yosemite
    sha256 "949fcc6eec1fa1d2442e899e6486a62eeb1754d2e60ce72230f2be701d35a8fa" => :el_capitan
    sha256 "ef66776acde66679b77c978bc6bb3f4879a88d0ff4c35da1bd72cbc88d12fb51" => :sierra
  end

  depends_on 'cmake' => :build
  depends_on 'swig' => :build

  depends_on :python => :recommended
  depends_on :python3 => :optional

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
    end
  end

end
