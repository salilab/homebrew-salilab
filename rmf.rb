require "formula"

class Rmf < Formula
  desc "Rich Molecular Format library"
  homepage "https://integrativemodeling.org/rmf/"
  url "https://github.com/salilab/rmf/archive/refs/tags/1.4.1.tar.gz"
  sha256 "8ab3a0b13466ecf41e9e42b759c9935d740ceb4698490648a27501b9b27adda0"
  license "Apache-2.0"

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_ventura:  "f3c0cd0281188a34e27db112c0616312196f88a60bef2afd73af62c65e13ae34"
    sha256 arm64_monterey: "d369d36077f16f226758ca172702d34d45c906c0b3808f08dfce85ac79615943"
    sha256 ventura:        "b2932d8c144a779d526e9aa2087d8131d2b994afc4644e4e65942c4a3d51cca3"
    sha256 monterey:       "fa1356b913fb685e37371570142c6f14d3bbc66505b00ec14a4528f4361474b2"
    sha256 big_sur:        "3d35f3ee4525cf58bb47dacc6fc0a07be2d5840257e2762e156dcca4e9befe6e"
    sha256 catalina:       "3b0bcc7a4c610301af7edeaae636466d644080c036d9c90b78fc155a6708c40d"
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
