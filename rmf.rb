require "formula"

class Rmf < Formula
  desc "Rich Molecular Format library"
  homepage "https://integrativemodeling.org/rmf/"
  url "https://github.com/salilab/rmf/archive/refs/tags/1.4.1.tar.gz"
  sha256 "8ab3a0b13466ecf41e9e42b759c9935d740ceb4698490648a27501b9b27adda0"
  license "Apache-2.0"
  revision 2

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_ventura:  "eec4edbfc01e4b1fe27d1038321b7508b047bdf9aac688186ae1be40e307448d"
    sha256 arm64_monterey: "c0b74e4e842fe3d160aeccb8d0f170af4a703a010599cbfec7cd4923028f91d4"
    sha256 ventura:        "1031f0cc99de72334a10ddd04710b27746ab91a516aa6fd0d611d27d19ddfbba"
    sha256 monterey:       "a01632d5d49a54664c7863846dcaa21aaebf34f7714bd7e7854a576aede49a11"
    sha256 big_sur:        "2a720d8e3d93b9e759fe85de5ecd92106a332649f5acd6030001ca1aa0b58240"
  end

  depends_on "cmake" => :build
  depends_on "pkg-config" => :build
  depends_on "swig" => :build

  depends_on "boost"
  depends_on "hdf5"
  depends_on "python@3.11"

  def install
    ENV.cxx11
    pybin = Formula["python@3.11"].opt_bin/"python3.11"
    pyver = Language::Python.major_minor_version pybin
    args = std_cmake_args
    args << ".."
    args << "-DCMAKE_INSTALL_PYTHONDIR=#{lib}/python#{pyver}/site-packages"
    # Don't install in lib64 on Linux systems
    args << "-DCMAKE_INSTALL_LIBDIR=#{lib}"
    # Don't link against log4cxx, even if available, since then the
    # bottle won't work on systems without log4cxx installed
    args << "-DLog4CXX_LIBRARY=Log4CXX_LIBRARY-NOTFOUND"
    # Force Python 3
    args << "-DUSE_PYTHON2=off"
    args << "-DPython3_EXECUTABLE:FILEPATH=#{pybin}"

    mkdir "build" do
      system "cmake", *args
      system "make"
      system "make", "install"
    end
  end

  test do
    pythons = [Formula["python@3.11"].opt_bin/"python3.11"]
    pythons.each do |python|
      system python, "-c", "import RMF; assert(RMF.__version__ == '1.4')"
    end
    system "rmf3_dump", "--version"
  end
end
