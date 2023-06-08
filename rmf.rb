require "formula"

class Rmf < Formula
  desc "Rich Molecular Format library"
  homepage "https://integrativemodeling.org/rmf/"
  url "https://github.com/salilab/rmf/archive/refs/tags/1.5.1.tar.gz"
  sha256 "9e885b2342bc0896502ca4fd9c1712103af199b9b6c170b8f004fa82feb94ada"
  license "Apache-2.0"

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_ventura:  "3eb704f8ea5b304ef365a0ffb19b69876cdfc8387e23414daa4dbf58559cc87b"
    sha256 arm64_monterey: "5b0faa876f646316c5e33381b38a46825334e7be983347720f32f06e00ac9f9f"
    sha256 ventura:        "9db5776f6ceb7bc05a45f05f241e2561baa7744aad602a7c5a9f82a3476e9a7e"
    sha256 monterey:       "064cd608c36471d46b20bab0a4ca0f24d1e9cd32e7bcbca1cfa1262888f346bf"
    sha256 big_sur:        "825d9102ebe7f16fda0399d08cac917dabba66fd0754da12a300c7dfa14b1e52"
  end

  depends_on "cmake" => :build
  depends_on "pkg-config" => :build
  depends_on "swig" => :build

  depends_on "boost"
  depends_on "hdf5"
  depends_on "python@3.11"
  depends_on "numpy"

  on_big_sur :or_older do
    patch :DATA
  end

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
      system python, "-c", "import RMF; assert(RMF.__version__ == '1.5.1')"
      system python, "-c", "import RMF; assert(hasattr(RMF, 'get_all_global_coordinates'))"
    end
    system "rmf3_dump", "--version"
  end
end

__END__
--- a/include/RMF/HDF5/handle.h
+++ b/include/RMF/HDF5/handle.h
@@ -70,9 +70,9 @@ class RMFEXPORT Handle : public boost::noncopyable {
     }
     h_ = -1;
   }
-// Older clang does not like exception specification in combination
+// Many clang/macOS versions do not like exception specification in combination
 // with std::shared_ptr
-#if defined(__clang__) && __clang_major__ <= 7
+#if defined(__clang__)
   ~Handle() {
 #else
   ~Handle() noexcept(false) {
