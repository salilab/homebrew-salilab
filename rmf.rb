require "formula"

class Rmf < Formula
  desc "Rich Molecular Format library"
  homepage "https://integrativemodeling.org/rmf/"
  url "https://github.com/salilab/rmf/archive/refs/tags/1.7.1.tar.gz"
  sha256 "7f1b7babf687513966a9b3366b9c95dbcce14e1fe9fc22d8ff146f0c5681747f"
  license "Apache-2.0"

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_tahoe:   "a662f2e1b25ba015ad38870dabe8bbb4db116983080749011ee94fbed5172c30"
    sha256 arm64_sequoia: "f258a22697977a788045986d12c87bb8e6f51cd4de12ea87aca21a434eb694df"
    sha256 arm64_sonoma:  "4bbcc57995e4ea0caa120870e67797abfde448da403b34d39b45bfed9d3ecc13"
    sha256 tahoe:         "5f1931d56af478950011e74d83c1df47dbdabf0b8e9d2ef1ad8dbf1feb8850d2"
    sha256 sequoia:       "1a02c6c78aba4440fc1f02433d21bd65e773d54d9627c1daf654d076699e4cee"
    sha256 sonoma:        "f1cfa3c05bdf09ed8ceadd15391618634aa0d037fed8cc489bd651d924a5e4cf"
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
      system python, "-c", "import RMF; assert(RMF.__version__ == '1.7.1')"
      system python, "-c", "import RMF; assert(hasattr(RMF, 'get_all_global_coordinates'))"
    end
    system "rmf3_dump", "--version"
  end
end
