require "formula"

class Rmf < Formula
  desc "Rich Molecular Format library"
  homepage "https://integrativemodeling.org/rmf/"
  url "https://github.com/salilab/rmf/archive/refs/tags/1.6.1.tar.gz"
  sha256 "abe143e7411b910e5ba863c162b3a23bfdec440cbb1c4909e88727c0e63ad772"
  license "Apache-2.0"
  revision 1

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_sonoma:   "ec85006ad6576e2b024458d0482e98ea105295835e50c9a84866c02caf8bafe4"
    sha256 arm64_ventura:  "f303754c4dc590363e8faea66e3c24d1a1ca0701b389222cd2919455a1c79d29"
    sha256 arm64_monterey: "04be6b615f1003a79078ee64c4899ca371a1a67e4985a9761f0fab7d7cc95d74"
    sha256 sonoma:         "64e108d8cce84da0f419253fa0b5d785aa38a16da7b025b7a7c4b674884a32e8"
    sha256 ventura:        "5fac71ef1179bf0a142fb5ae5683b1e0ccc579431955ff7af6c50a63758d75fb"
    sha256 monterey:       "2f9d2477681b13d4a40f04accfa76f30d1c20e414c6d8c0ed8b37a9fba7369dd"
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
