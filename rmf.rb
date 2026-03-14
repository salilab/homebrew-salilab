require "formula"

class Rmf < Formula
  desc "Rich Molecular Format library"
  homepage "https://integrativemodeling.org/rmf/"
  url "https://github.com/salilab/rmf/archive/refs/tags/1.7.0.tar.gz"
  sha256 "37997f189702b4705f69b2db5f64cef31cfa9ab9eb151dfc0457c72dba422345"
  license "Apache-2.0"
  revision 6

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_tahoe:   "cbeaf9068969c19492794619748e65bc167f3eb06337284e2fc43e390bfae5a3"
    sha256 arm64_sequoia: "5c98358d883167bb8654443fdc8d6dca9da79cb28580140c4c8d1aa88ca9b049"
    sha256 arm64_sonoma:  "3a9ad61af233fcb6ac0fa65f7845b8022c8af22feb1947403de4688ac9432fde"
    sha256 tahoe:         "79ab9d30843859f9b8faa968c24877083f703f836e54a8f1a9385f4fa360c00e"
    sha256 sequoia:       "12ceaebcb1ff932162577e07c72e1e2ab749ace3746024aaa954f056a0fa8918"
    sha256 sonoma:        "c6b7e9736d292ed44e296660289821e05b90112cfc724d84436cb90284bd1cd5"
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
