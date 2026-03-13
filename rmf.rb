require "formula"

class Rmf < Formula
  desc "Rich Molecular Format library"
  homepage "https://integrativemodeling.org/rmf/"
  url "https://github.com/salilab/rmf/archive/refs/tags/1.7.0.tar.gz"
  sha256 "37997f189702b4705f69b2db5f64cef31cfa9ab9eb151dfc0457c72dba422345"
  license "Apache-2.0"
  revision 5

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_tahoe:   "aee26b6cd63196c22227afe894744cb4256b0811c0782fa8682aea9fd8d06f2d"
    sha256 arm64_sequoia: "d75293bb7471658df17d58f5181f5421368c42284d899a7321c02bbb05d56f96"
    sha256 arm64_sonoma:  "ab7d1360a68d890c37f22ef906b32027932f14a8da48d8e2f39ec1416ff33235"
    sha256 tahoe:         "b1c27d3ef3aec2897048bd764b4e04ec905abcc119c1d070bf7ace67854e4972"
    sha256 sequoia:       "904f7c36356d41628fc5bffcfa36bff08c167de633a64bb238c463bd4db6faba"
    sha256 sonoma:        "fc3ac6c461d33622568e8b6a094b014729584c01ddd35787cf0cb286bb6774c3"
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
