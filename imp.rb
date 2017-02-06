require 'formula'

class Imp < Formula
  desc "The Integrative Modeling Platform"
  homepage 'https://integrativemodeling.org/'
  url 'https://integrativemodeling.org/2.6.2/download/imp-2.6.2.tar.gz'
  sha256 'd048d1d0d867d4bc98de1ff1953118569b4be36c2198bc7538a7a503f7e9b853'
  revision 3

  bottle do
    root_url "https://integrativemodeling.org/2.6.2/download/homebrew"
    sha256 "0b8c2c9e09346981317df0308e880604650b136110224cc4254e567518e9a636" => :yosemite
    sha256 "18011fa46f3400f2df7f65c0b332dc7a3ad5b54bca75d46e5f67a6df5922dfa8" => :el_capitan
    sha256 "21c4419aa9d7626a600aad2519dbf326c6b7904928d22e0abf6c75379ec1461a" => :sierra
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
