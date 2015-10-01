require 'formula'

class Imp < Formula
  homepage 'http://integrativemodeling.org/'
  url 'http://integrativemodeling.org/2.5.0/download/imp-2.5.0.tar.gz'
  sha256 '5510ffed71cb0a0bc3e8fddb6939dc0e75ca31eec0cc8b30650d169aa60a4aab'

  bottle do
    root_url "http://integrativemodeling.org/2.5.0/download/homebrew"
    sha256 "52316e004e33ab427e8f07588aa845e2141051d5b6728111f3477604ee79942d" => :el_capitan
    sha256 "12c1a771a394ed6a124b0cb3e46313837abab2659b2cf07c7dd70635934ae2c6" => :yosemite
    sha256 "d3bfd31d7e65c94779d9e6c32c0ae5967122b4b982bb2c01de327800c5e6da2d" => :mavericks
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
