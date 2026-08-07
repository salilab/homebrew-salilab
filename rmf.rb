require "formula"

class Rmf < Formula
  desc "Rich Molecular Format library"
  homepage "https://integrativemodeling.org/rmf/"
  url "https://github.com/salilab/rmf/archive/refs/tags/1.7.2.tar.gz"
  sha256 "132599e2904e7533c433a3770dc0ceae25e989f7a4d9a0fbeda93623acfdba60"
  license "Apache-2.0"

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_tahoe:   "aa337bc21706270951e084ebd7f6db48d97bcf7110a91ae62a90f625c89c77c1"
    sha256 arm64_sequoia: "5b595dc7c49e553ee802537901c7963cea4d678311b6a51790836e4ade069b26"
    sha256 arm64_sonoma:  "7d40b17d71389949e1a5f9a526b0d037626e8e75bc6569eb0dfb4b54afe8dfce"
    sha256 tahoe:         "9cc036db073ffc7428f1e134e3ff3c1be7f1005adcff979e8764c3cefc738ea4"
    sha256 sequoia:       "35b28cc2b0c8becb94ed4f27fcbbda5c351f6d3c234f5843164ac27215206e3d"
    sha256 sonoma:        "bd347732e6aeaa9d2eba8e375dff61f24cbae3493c84fdf228d62b691730b5b0"
  end

  depends_on "cmake" => :build
  depends_on "pkg-config" => :build
  depends_on "swig" => :build

  depends_on "boost"
  depends_on "hdf5"
  depends_on "python@3.14"
  depends_on "numpy"

  def install
    ENV.cxx11
    pybin = Formula["python@3.14"].opt_bin/"python3.14"
    pyver = Language::Python.major_minor_version pybin
    args = std_cmake_args
    args << ".."
    args << "-DCMAKE_INSTALL_PYTHONDIR=#{lib}/python#{pyver}/site-packages"
    # Don't install in lib64 on Linux systems
    args << "-DCMAKE_INSTALL_LIBDIR=#{lib}"
    # Don't link against log4cxx, even if available, since then the
    # bottle won't work on systems without log4cxx installed
    args << "-DLog4CXX_LIBRARY=Log4CXX_LIBRARY-NOTFOUND"
    args << "-DPython3_EXECUTABLE:FILEPATH=#{pybin}"
    # Work around boost/clang incompatibility
    args << "-DCMAKE_CXX_FLAGS=-D_LIBCPP_ENABLE_CXX17_REMOVED_UNARY_BINARY_FUNCTION"

    mkdir "build" do
      system "cmake", *args
      system "make"
      system "make", "install"
    end
  end

  test do
    pythons = [Formula["python@3.14"].opt_bin/"python3.14"]
    pythons.each do |python|
      system python, "-c", "import RMF; assert(RMF.__version__ == '1.7.2')"
      system python, "-c", "import RMF; assert(hasattr(RMF, 'get_all_global_coordinates'))"
    end
    system "rmf3_dump", "--version"
  end
end
