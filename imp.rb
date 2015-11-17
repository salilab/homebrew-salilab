require 'formula'

class Imp < Formula
  homepage 'http://integrativemodeling.org/'
  url 'http://integrativemodeling.org/2.5.0/download/imp-2.5.0.tar.gz'
  sha256 '5510ffed71cb0a0bc3e8fddb6939dc0e75ca31eec0cc8b30650d169aa60a4aab'
  revision 1

  bottle do
    root_url "http://integrativemodeling.org/2.5.0/download/homebrew"
    sha256 "efcd3cead414a485389cab226347e159a36ffc967c01299c1ba96079f1658d94" => :el_capitan
    sha256 "fbdfa912e0050c7066ffdad90db57b4182bd6ace710e953ba72e9f950ddb9855" => :yosemite
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
        args = ["..",
                "-DCMAKE_INSTALL_PYTHONDIR=#{lib}/python#{version}/site-packages",
                "-DSWIG_PYTHON_LIBRARIES=#{py3_lib}",
                "-DPYTHON_LIBRARIES=#{py3_lib}",
                "-DPYTHON_INCLUDE_DIRS=#{py3_inc}",
                "-DPYTHON_INCLUDE_PATH=#{py3_inc}"]
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
