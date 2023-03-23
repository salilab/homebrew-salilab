require "formula"

class Rmf < Formula
  desc "Rich Molecular Format library"
  homepage "https://integrativemodeling.org/rmf/"
  url "https://github.com/salilab/rmf/archive/refs/tags/1.5.0.tar.gz"
  sha256 "cc53760f207faf3523e3ab75d81e41228f28916d7935298fb59455f006f3669a"
  license "Apache-2.0"

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_ventura:  "9698d3ddef64fc8126bf2f12a444e2b0313e3102d810c7ff843c1c4cb34e5124"
    sha256 arm64_monterey: "467f6a2e2b8dd9d93478e20d2843e91e568395956ce71a889c8b7de46507c538"
    sha256 ventura:        "d20e5b98932cf318b8eb77844c480168f3e13b418a9ea515cf6d223dd837b783"
    sha256 monterey:       "2976ad24ae6b6de8cff2bab46ad4d0b4223d97400fd44df03c068dc575483ca0"
    sha256 big_sur:        "5a303a0f490067c15d6872aa6700ea821f8d0ee2eea50e77a89e9934faf51d24"
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
      system python, "-c", "import RMF; assert(RMF.__version__ == '1.5.0')"
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
