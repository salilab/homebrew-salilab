require 'formula'

class Imp < Formula
  desc "The Integrative Modeling Platform"
  homepage 'http://integrativemodeling.org/'
  url 'http://integrativemodeling.org/2.6.0/download/imp-2.6.0.tar.gz'
  sha256 '66ab0edbb3226d0f88d1d34afcca88a34ffddb00d2c7400aad5520bc90e88d05'

  bottle do
    root_url "http://integrativemodeling.org/2.6.0/download/homebrew"
    sha256 "351a39b679ca41708c7912231df288d84ef0575abcf2ae9757871b789b794af4" => :yosemite
    sha256 "d7a6b6c494ccfc21a074dacb70c29c00758a69dc6f6cafc18f95174c4171f78c" => :el_capitan
  end

  depends_on 'cmake' => :build
  depends_on 'swig' => :build

  depends_on :python => :recommended
  depends_on :python3 => :optional

  depends_on 'boost'
  depends_on 'hdf5'
  depends_on 'fftw'
  depends_on 'libtau' => :recommended
  depends_on 'cgal' => :recommended
  depends_on 'gsl' => :recommended
  depends_on 'opencv' => :recommended

  # We need boost compiled with c++11 support on Linux
  needs :cxx11 if OS.linux?

  def install
    pyver = Language::Python.major_minor_version "python"
    args = std_cmake_args
    args << "-DIMP_DISABLED_MODULES=scratch"
    args << ".."
    # Don't install in lib64 on Linux systems
    args << "-DCMAKE_INSTALL_LIBDIR=#{lib}"
    args << "-DCMAKE_INSTALL_PYTHONDIR=#{lib}/python#{pyver}/site-packages"
    mkdir "build" do
      system "cmake", *args
      system "make"
      system "make", "install"
      # Avoid conflicting with the "cluster" binary provided by graphviz
      mv bin/"cluster", bin/"rmsd_cluster"
      if build.with? 'python3'
        version = Language::Python.major_minor_version "python3"
        python_framework = (Formula["python3"].opt_prefix)/"Frameworks/Python.framework/Versions/#{version}"
        py3_lib = "#{python_framework}/lib/libpython#{version}.dylib"
        py3_inc = "#{python_framework}/Headers"
        args = ["..",
                "-DCMAKE_INSTALL_PYTHONDIR=#{lib}/python#{version}/site-packages",
                "-DSWIG_PYTHON_LIBRARIES=#{py3_lib}",
                "-DPYTHON_LIBRARIES=#{py3_lib}",
                "-DPYTHON_INCLUDE_DIRS=#{py3_inc}",
                "-DPYTHON_INCLUDE_PATH=#{py3_inc}"]
        system "cmake", *args
        system "make", "install"
        mv bin/"cluster", bin/"rmsd_cluster"
      end
    end
  end

  test do
    Language::Python.each_python(build) do |python, version|
      system python, "-c", "import IMP"
    end
  end

end
