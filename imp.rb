require 'formula'

class Imp < Formula
  desc "The Integrative Modeling Platform"
  homepage 'https://integrativemodeling.org/'
  url 'https://integrativemodeling.org/2.8.0/download/imp-2.8.0.tar.gz'
  sha256 '83a23c56f0be9de8900d0edd3978eb8c2637e6d5086f7ef7e2cd61f0b7a5aa80'
  revision 3

  bottle do
    root_url "https://integrativemodeling.org/2.8.0/download/homebrew"
    sha256 "6124e332be52237e79fffc83c57471a72ae9558857b97e080fb11afda900fea4" => :yosemite
    sha256 "96c841a1a22daf60a12179231a5bee32cdae180a6492599a53670be7e8c4af7e" => :el_capitan
    sha256 "6880e65d7e4180bbd43d3dcbce1c3f3e2116cb51f6783a73753b3680be3e94fe" => :sierra
  end

  depends_on 'cmake' => :build
  depends_on 'swig' => :build

  depends_on :python => :recommended
  depends_on :python3 => :recommended

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
