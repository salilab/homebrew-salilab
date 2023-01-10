require "formula"

class Rmf < Formula
  desc "Rich Molecular Format library"
  homepage "https://integrativemodeling.org/rmf/"
  url "https://github.com/salilab/rmf/archive/refs/tags/1.4.1.tar.gz"
  sha256 "8ab3a0b13466ecf41e9e42b759c9935d740ceb4698490648a27501b9b27adda0"
  license "Apache-2.0"
  revision 1

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_ventura:  "c01d056d1920c4db468781c4134ffa1c4ce53743f4248ee4c2fb7bd314d03396"
    sha256 arm64_monterey: "13eed0ef94086378169262afd595231849827afd6cd037c42fe4f85e67b72b96"
    sha256 ventura:        "f537349a1c22162e8ed4e3dfc7bb2f2b45bda15e77a8b92c015fc0734c465461"
    sha256 monterey:       "46c3d9aec476dbb5e8180709b7038604356735cd2dc8f78f4b4187b60b282e49"
    sha256 big_sur:        "1bada11d5bcf45917e2c6434b8eab38bf1fc27ef63f0eac76e1739eecf12fbad"
  end

  depends_on "cmake" => :build
  depends_on "pkg-config" => :build
  depends_on "swig" => :build

  depends_on "boost"
  depends_on "hdf5"
  depends_on "python@3.10"

  def install
    ENV.cxx11
    pybin = Formula["python@3.10"].opt_bin/"python3.10"
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
    pythons = [Formula["python@3.10"].opt_bin/"python3.10"]
    pythons.each do |python|
      system python, "-c", "import RMF; assert(RMF.__version__ == '1.4')"
    end
    system "rmf3_dump", "--version"
  end
end
