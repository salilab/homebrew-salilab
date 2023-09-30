require "formula"

class Rmf < Formula
  desc "Rich Molecular Format library"
  homepage "https://integrativemodeling.org/rmf/"
  url "https://github.com/salilab/rmf/archive/refs/tags/1.5.1.tar.gz"
  sha256 "9e885b2342bc0896502ca4fd9c1712103af199b9b6c170b8f004fa82feb94ada"
  license "Apache-2.0"
  revision 1

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_sonoma:   "775b698223f7ddc93fcba7a09dba8e0060386b762251330c50b48f6e039813fe"
    sha256 arm64_ventura:  "bbd81d45d4bc254da773488f8abdfe276b393368043aea14d0f02b1dcd04b020"
    sha256 arm64_monterey: "7ddfa0835583c9efb050671a3b2089db0273cb0e92803ddada251215972faafe"
    sha256 sonoma:         "02723e3cdafdbc8f9ccd0a1bb8145602c407adab46b67ae0942591e6a246c422"
    sha256 ventura:        "018cf5b78f10631455d2f42bced02a1e9fdcee99d01e445671798398df517ad9"
    sha256 monterey:       "40d7d0ab4feca4b37154047948ac6f42366c44472ea35a0f551b49424f8cbb09"
    sha256 big_sur:        "88d7262df407bf8b7d783f11e4362470767ff37fe63938fccdd024683af9ee95"
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
    # Work around boost/clang incompatibility
    args << "-DCMAKE_CXX_FLAGS=-D_LIBCPP_ENABLE_CXX17_REMOVED_UNARY_BINARY_FUNCTION"

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
