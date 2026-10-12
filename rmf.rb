require "formula"

class Rmf < Formula
  desc "Rich Molecular Format library"
  homepage "https://integrativemodeling.org/rmf/"
  url "https://github.com/salilab/rmf/archive/refs/tags/1.7.2.tar.gz"
  sha256 "132599e2904e7533c433a3770dc0ceae25e989f7a4d9a0fbeda93623acfdba60"
  license "Apache-2.0"
  revision 2

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_golden_gate: "605fc005bc6da87ca021e6ceaa273845597302b4394e89a17f02ef2ddfca288b"
    sha256 arm64_tahoe:       "5aedfb84ba66b47165a4562d3b2a79d5d5414930e24af33d74bea2a81bf057d0"
    sha256 arm64_sequoia:     "b4a60ed9d380974484b1ef47c9055274f9abcce91865f49136bfad5773756799"
  end

  depends_on "cmake" => :build
  depends_on "pkg-config" => :build
  depends_on "swig" => :build

  depends_on "boost"
  depends_on "hdf5"
  depends_on "python@3.15"
  depends_on "numpy"

  def install
    ENV.cxx11
    pybin = Formula["python@3.15"].opt_bin/"python3.15"
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
    pythons = [Formula["python@3.15"].opt_bin/"python3.15"]
    pythons.each do |python|
      system python, "-c", "import RMF; assert(RMF.__version__ == '1.7.2')"
      system python, "-c", "import RMF; assert(hasattr(RMF, 'get_all_global_coordinates'))"
    end
    system "rmf3_dump", "--version"
  end
end
