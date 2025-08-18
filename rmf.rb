require "formula"

class Rmf < Formula
  desc "Rich Molecular Format library"
  homepage "https://integrativemodeling.org/rmf/"
  url "https://github.com/salilab/rmf/archive/refs/tags/1.7.0.tar.gz"
  sha256 "37997f189702b4705f69b2db5f64cef31cfa9ab9eb151dfc0457c72dba422345"
  license "Apache-2.0"
  revision 2

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_sequoia: "d0ffc063badd7485954517bbc3077365d56184108a26d80e6a413af2bbae494e"
    sha256 arm64_sonoma:  "7e02f8f19faf33cddd16a9d28fd9c5db138d8f4a0a4c82310264150ed50974f9"
    sha256 arm64_ventura: "a6cc3da957f799eb59cf3fba9a6bdd2841693b8cfa4f83d7339092ddf43aaf02"
    sha256 sequoia:       "c51bf238b13be58aab043ac07afa21f93445f65ad99b8607161d65f8e3a82430"
    sha256 sonoma:        "b03f62ec608099f45211aa12693896fbb3c94ffce41535110b0f369f266d4e56"
    sha256 ventura:       "d397938c247b1366432d08d59e3ef3e0b0a4dcad5104789f06c7b2229740b149"
  end

  depends_on "cmake" => :build
  depends_on "pkg-config" => :build
  depends_on "swig" => :build

  depends_on "boost"
  depends_on "hdf5"
  depends_on "python@3.13"
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
    pybin = Formula["python@3.13"].opt_bin/"python3.13"
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
    pythons = [Formula["python@3.13"].opt_bin/"python3.13"]
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
