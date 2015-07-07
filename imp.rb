require 'formula'

class Imp < Formula
  homepage 'http://integrativemodeling.org/'
  url 'http://integrativemodeling.org/2.5.0/download/imp-2.5.0.tar.gz'
  sha1 '6d4b2547bcc53cd2d704d874be8fddf75a33a601'

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

  def install
    args = std_cmake_args
    args << "-DIMP_DISABLED_MODULES=scratch"
    args << ".."
    mkdir "build" do
      system "cmake", *args
      system "make"
      system "make", "install"
      if build.with? 'python3'
        version = Language::Python.major_minor_version "python3"
        python_framework = (Formula["python3"].opt_prefix)/"Frameworks/Python.framework/Versions/#{version}"
        py3_lib = "#{python_framework}/lib/libpython#{version}.dylib"
        py3_inc = "#{python_framework}/Headers"
        args = ["..", "-DCMAKE_INSTALL_PYTHONDIR",
               "#{lib}/python#{version}/site-packages",
                "-DSWIG_PYTHON_LIBRARIES", py3_lib,
                "-DPYTHON_LIBRARIES", py3_lib,
                "-DPYTHON_INCLUDE_DIRS", py3_inc,
                "-DPYTHON_INCLUDE_PATH", py3_inc]
        system "cmake", *args
        system "make", "install"
      end
    end
  end

  test do
    Language::Python.each_python(build) do |python, version|
      system python, "-c", "import IMP"
    end
  end

end
