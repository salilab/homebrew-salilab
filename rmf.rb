require "formula"

class Rmf < Formula
  desc "Rich Molecular Format library"
  homepage "https://integrativemodeling.org/rmf/"
  url "https://github.com/salilab/rmf/archive/refs/tags/1.7.0.tar.gz"
  sha256 "37997f189702b4705f69b2db5f64cef31cfa9ab9eb151dfc0457c72dba422345"
  license "Apache-2.0"
  revision 3

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_tahoe:   "de169037bd68bc55765d86bdb96c39661b5a4157178bfe6256aee1d51bcb3324"
    sha256 arm64_sequoia: "0bb47a3a1110a7825612581bfeeed54cdcae32c1102f977ecabe5d3163551d7f"
    sha256 arm64_sonoma:  "6beee99a6dc79c2b5c3ccc6608eaf7ca3b095b8c55512237cc18a38002f0f79b"
    sha256 tahoe:         "97ea31e7674403ed3c2028f2ebdabd7a67f8e19880281cfb8f3e76ee7e386f1e"
    sha256 sequoia:       "198ebbfcb64de288dbb2109276aecde5c1e6b39912febd214da45aaabf9a61ab"
    sha256 sonoma:        "96ad7233228c7b6a25347d7125171787bec995862c37fc320b53da2843a6b3f2"
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
