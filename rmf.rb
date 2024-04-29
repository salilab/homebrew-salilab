require "formula"

class Rmf < Formula
  desc "Rich Molecular Format library"
  homepage "https://integrativemodeling.org/rmf/"
  url "https://github.com/salilab/rmf/archive/refs/tags/1.6.0.tar.gz"
  sha256 "4ab69a6e1c8c67c670377b387439ebcbd6ad10226e0414ce5e9113883738c383"
  license "Apache-2.0"
  revision 2

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_sonoma:   "78bc581cc44892f6abfff744f9b0c0c041c35a54b0186e480eec863f50293cdb"
    sha256 arm64_ventura:  "a692725b9a2c4483bd3d329071e46ea9bd1cd4225b9240d7947c36e35843db8c"
    sha256 arm64_monterey: "c43ede14c12406a9347e52c738193494bee5c7d7276aa9589b6736916c7c9faa"
    sha256 sonoma:         "adc71c6c55b2db1f81f4fd44d2a10a3f8463f7ad6e820f0bf2569dd154e343c7"
    sha256 ventura:        "2f53c773647eef4bfdc9c9aeae085e7dd8230df249300021b59638235fc70c2a"
    sha256 monterey:       "2663ad93b0b66b5828a6e99106a37252f7362507b888fb90070924b82fdb376c"
  end

  depends_on "cmake" => :build
  depends_on "pkg-config" => :build
  depends_on "swig" => :build

  depends_on "boost"
  depends_on "hdf5"
  depends_on "python@3.12"
  depends_on "numpy"

  # Fix build with Boost 1.85
  patch do
    url "https://github.com/salilab/rmf/commit/dc27f6810c2011424f0ee241fe64de8583c1236a.patch?full_index=1"
    sha256 "7005b6c75841b05be009a619a882f576bf47e8d761da4dcf18b69f64f7487a19"
  end

  # Fix failure to find HDF5 libraries
  patch do
    url "https://github.com/salilab/rmf/commit/643ad763ce9466784dbd21baa789171dd32f3056.patch?full_index=1"
    sha256 "71d3bf0cc45d91a1ee1aefc973cbcd81e1714b46b0add38d418b18789611079f"
  end

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
      system python, "-c", "import RMF; assert(RMF.__version__ == '1.6.0')"
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
