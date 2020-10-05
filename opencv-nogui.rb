# Since homebrew doesn't yet support optional dependencies, this is a slightly
# modified version of opencv that disables some dependencies we don't use in
# the Sali lab, to reduce the libraries we need to bundle with IMP.
class OpencvNogui < Formula
  desc "Open source computer vision library"
  homepage "http://opencv.org/"
  url "https://github.com/Itseez/opencv/archive/2.4.13.tar.gz"
  sha256 "94ebcca61c30034d5fb16feab8ec12c8a868f5162d20a9f0396f0f5f6d8bbbff"
  license "BSD-3-Clause"
  head "https://github.com/Itseez/opencv.git", :branch => "2.4"

  option "32-bit"
  option "with-tbb", "Enable parallel code in OpenCV using Intel TBB"

  option :cxx11
  option :universal

  depends_on "cmake"      => :build
  depends_on 'jpeg' => :optional

  depends_on "pkg-config" => :build

  depends_on 'python' => :recommended unless OS.mac? && MacOS.version > :snow_leopard
  depends_on "homebrew/python/numpy" => :recommended if build.with? "python"

  # Can also depend on ffmpeg, but this pulls in a lot of extra stuff that
  # you don't need unless you're doing video analysis, and some of it isn't
  # in Homebrew anyway. Will depend on openexr if it's installed.

  def arg_switch(opt)
    (build.with? opt) ? "ON" : "OFF"
  end

  def install
    ENV.cxx11 if build.cxx11?
    jpeg = Formula["jpeg"]
    dylib = OS.mac? ? "dylib" : "so"

    args = std_cmake_args + %W[
      -DWITH_CUDA=OFF
      -DWITH_TIFF=1
      -DWITH_JPEG=1
      -DWITH_PNG=0
      -DWITH_QT=OFF
      -DWITH_JASPER=0
      -DBUILD_ZLIB=OFF
      -DBUILD_TIFF=OFF
      -DBUILD_PNG=OFF
      -DBUILD_JPEG=OFF
      -DBUILD_JASPER=OFF
      -DBUILD_TESTS=OFF
      -DBUILD_PERF_TESTS=OFF
    ]
    args << "-DWITH_TBB="       + arg_switch("tbb")

    if build.with? "python"
      py_prefix = `python-config --prefix`.chomp
      py_lib = OS.linux? ? `python-config --configdir`.chomp : "#{py_prefix}/lib"
      args << "-DPYTHON_LIBRARY=#{py_lib}/libpython2.7.#{dylib}"
      args << "-DPYTHON_INCLUDE_DIR=#{py_prefix}/include/python2.7"
      # Make sure find_program locates system Python
      # https://github.com/Homebrew/homebrew-science/issues/2302
      args << "-DCMAKE_PREFIX_PATH=#{py_prefix}" if OS.mac?
    end

    if build.with? "cuda"
      ENV["CUDA_NVCC_FLAGS"] = "-Xcompiler -stdlib=libc++; -Xlinker -stdlib=libc++"
      args << "-DWITH_CUDA=ON"
      args << "-DCMAKE_CXX_FLAGS=-stdlib=libc++"
      args << "-DCUDA_GENERATION=Kepler"
    else
      args << "-DWITH_CUDA=OFF"
    end

    # OpenCL 1.1 is required, but Snow Leopard and older come with 1.0
    args << "-DWITH_OPENCL=OFF" if build.without?("opencl") || MacOS.version < :lion

    if build.with? "openni"
      args << "-DWITH_OPENNI=ON"
      # Set proper path for Homebrew's openni
      inreplace "cmake/OpenCVFindOpenNI.cmake" do |s|
        s.gsub! "/usr/include/ni", Formula["openni"].opt_include/"ni"
        s.gsub! "/usr/lib", Formula["openni"].opt_lib
      end
    end

    if build.include? "32-bit"
      args << "-DCMAKE_OSX_ARCHITECTURES=i386"
      args << "-DOPENCV_EXTRA_C_FLAGS='-arch i386 -m32'"
      args << "-DOPENCV_EXTRA_CXX_FLAGS='-arch i386 -m32'"
    end

    if build.universal?
      ENV.universal_binary
      args << "-DCMAKE_OSX_ARCHITECTURES=#{Hardware::CPU.universal_archs.as_cmake_arch_flags}"
    end

    if ENV.compiler == :clang && !build.bottle?
      args << "-DENABLE_SSSE3=ON" if Hardware::CPU.ssse3?
      args << "-DENABLE_SSE41=ON" if Hardware::CPU.sse4?
      args << "-DENABLE_SSE42=ON" if Hardware::CPU.sse4_2?
      args << "-DENABLE_AVX=ON" if Hardware::CPU.avx?
    end

    mkdir "macbuild" do
      system "cmake", "..", *args
      system "make"
      system "make", "install"
    end
  end

  test do
    (testpath/"test.cpp").write <<-EOS.undent
      #include <opencv/cv.h>
      #include <iostream>
      int main()
      {
        std::cout << CV_VERSION << std::endl;
        return 0;
      }
    EOS
    system ENV.cxx, "test.cpp", "-I#{include}", "-L#{lib}", "-o", "test"
    assert_equal `./test`.strip, version.to_s

    assert_match version.to_s, shell_output("python -c 'import cv2; print(cv2.__version__)'")
  end
end
