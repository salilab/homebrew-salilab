require "formula"

class Rmf < Formula
  desc "Rich Molecular Format library"
  homepage "https://integrativemodeling.org/rmf/"
  url "https://github.com/salilab/rmf/archive/refs/tags/1.7.0.tar.gz"
  sha256 "37997f189702b4705f69b2db5f64cef31cfa9ab9eb151dfc0457c72dba422345"
  license "Apache-2.0"

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_sequoia: "f5455dc19c813499722c962be2843e66e2d07781b8a66d4ea003ab51cc13f594"
    sha256 arm64_sonoma:  "741b2da011f25654c5f6ca6bd6b2996cd5b615e0a09af20bc3b9ffbb38bf4fbe"
    sha256 arm64_ventura: "565f6c062b32f399519cdc36992f908961a6ea17235f48833df60ec6b280823a"
    sha256 sequoia:       "efab102788398724d37a32c578b078aaa40ecb4d2d39f9495bd66981cc5f8ea3"
    sha256 sonoma:        "39908a4b859843a217e4857cfee0f47367d36e51075cba3388c290dd130f1003"
    sha256 ventura:       "578fd0a02041ab3e55be6103b6608a969006093d3d3742ac6ed42dbc29d9aae9"
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
