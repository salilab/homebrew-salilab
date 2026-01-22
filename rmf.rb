require "formula"

class Rmf < Formula
  desc "Rich Molecular Format library"
  homepage "https://integrativemodeling.org/rmf/"
  url "https://github.com/salilab/rmf/archive/refs/tags/1.7.0.tar.gz"
  sha256 "37997f189702b4705f69b2db5f64cef31cfa9ab9eb151dfc0457c72dba422345"
  license "Apache-2.0"
  revision 4

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_tahoe:   "7c74ef4fe8b59ac63f265460936951ac14da96e3fdffe4fa9c6d2dcfe2ebd753"
    sha256 arm64_sequoia: "708a11470f2f7032d328bf632f80ab677e4ca8f031b70d5604a577f47bfdaa9c"
    sha256 arm64_sonoma:  "2523ff194e83b1dddb30665ff7accf8dfdd3c1e90525de3fe79d27c99f6219f5"
    sha256 tahoe:         "b29b621894639d8643cbad395041528fe1b301476072930fcf1c15d5374d1d54"
    sha256 sequoia:       "339c3f85bc1938f08db163a2ff8a488d7395224115eafd80ad49d7c7d5b9c74b"
    sha256 sonoma:        "539f5aa5346bd1113bdb88de6baad780a6bdc236c8770c83a5479228c46906db"
  end

  depends_on "cmake" => :build
  depends_on "pkg-config" => :build
  depends_on "swig" => :build

  depends_on "boost"
  depends_on "hdf5"
  depends_on "python@3.14"
  depends_on "numpy"

  on_big_sur :or_older do
    patch :DATA
  end

  # Fix build with Boost 1.89
  patch do
    url "https://github.com/salilab/rmf/commit/a86359a79cc19a8bc8814e12ad778fc7cbfa6f0b.patch?full_index=1"
    sha256 "03a730ba5ed1955bad7930e4c59ddd05d35ba63178492d9946590a5a930f7ac4"
  end

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
      system python, "-c", "import RMF; assert(RMF.__version__ == '1.7.0')"
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
