require "formula"

class Rmf < Formula
  desc "Rich Molecular Format library"
  homepage "https://integrativemodeling.org/rmf/"
  url "https://github.com/salilab/rmf/archive/refs/tags/1.6.1.tar.gz"
  sha256 "abe143e7411b910e5ba863c162b3a23bfdec440cbb1c4909e88727c0e63ad772"
  license "Apache-2.0"

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_sonoma:   "9afd026022ae51b5d929331145ef681618381707a0963582e8f3c8b841e8b1a4"
    sha256 arm64_ventura:  "a1bee43ae172dd086507347edbc5978a5adf914858e8b8339c5ff005cb522627"
    sha256 arm64_monterey: "9c2ba0ed88a12cf25006436c33293ca21d55b2a0e3e2ebd2f3c0999d1dd289dc"
    sha256 sonoma:         "f43d8374c86281836489a7af1cf7267347ff4fb653d89781e3efe86990b84e4b"
    sha256 ventura:        "38174060fe121ed8d4b7dd8451bf4985fc73b92b3b72c559331252c83cba8b91"
    sha256 monterey:       "af6019cbbe42dd1a6768444143f2f05c03bf42ad9f4185935d09c8694af8aae3"
  end

  depends_on "cmake" => :build
  depends_on "pkg-config" => :build
  depends_on "swig" => :build

  depends_on "boost"
  depends_on "hdf5"
  depends_on "python@3.12"
  depends_on "numpy"

  on_big_sur :or_older do
    patch :DATA
  end

  def install
    ENV.cxx11
    pybin = Formula["python@3.12"].opt_bin/"python3.12"
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
    pythons = [Formula["python@3.12"].opt_bin/"python3.12"]
    pythons.each do |python|
      system python, "-c", "import RMF; assert(RMF.__version__ == '1.6.1')"
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
