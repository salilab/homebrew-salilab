require 'formula'

class Imp < Formula
  desc "The Integrative Modeling Platform"
  homepage 'http://integrativemodeling.org/'
  url 'http://integrativemodeling.org/2.6.2/download/imp-2.6.2.tar.gz'
  sha256 'd048d1d0d867d4bc98de1ff1953118569b4be36c2198bc7538a7a503f7e9b853'

  bottle do
    root_url "http://integrativemodeling.org/2.6.2/download/homebrew"
    sha256 "bcebfbe1040dd8f15eb8a683c0e04833592f0c65021810bf1161fb71c38f4a13" => :yosemite
    sha256 "06b6d8356bb3c34176f9a5d791e39686c39e084e25f7fc87564487b20cdc91fb" => :el_capitan
    sha256 "e72616b10b22cf2f0c77adeb21e12258f93bcc2cf63a8718a0e1a11eea0c887f" => :sierra
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
