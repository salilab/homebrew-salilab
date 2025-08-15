require "formula"

class Mdt < Formula
  desc "Generate frequency tables used by Modeller and IMP"
  homepage "https://salilab.org/mdt/"
  url "https://salilab.org/mdt/5.6/mdt-5.6.tar.gz"
  sha256 "1ff0aaa4c3995486e11eefc77b99359cb5a80c12f81309f1bc22f486d7bbd3b7"
  license "GPL-2.0-or-later"

  depends_on "patchelf" => :build if OS.linux?
  depends_on "cmake" => :build
  depends_on "swig" => :build
  depends_on "glib"
  depends_on "salilab/salilab/modeller"
  depends_on "python@3.13" => :recommended

  def install
    hdf5_formula = Formula["hdf5@1.14.6"]

    if build.with? "python@3.13"
      python_version = Language::Python.major_minor_version Formula["python@3.13"].opt_bin/"python3.13"
      python_framework = Formula["python@3.13"].opt_prefix/"Frameworks/Python.framework/Versions/#{python_version}"
      py3_binary = Formula["python@3.13"].opt_prefix/"bin/python3.13"
      py3_lib = "#{python_framework}/lib/libpython#{python_version}.dylib"
      py3_inc = "#{python_framework}/Headers"
      py3_sitepack = "#{lib}/python#{python_version}/site-packages"
      mkdir "build" do
        args = std_cmake_args
        rm("../src/mdt_config.h")
        args << "-DCMAKE_INCLUDE_PATH=#{hdf5_formula.include}"
        args << "-DCMAKE_LIBRARY_PATH=#{hdf5_formula.lib}"
        args << "-DPYTHON_EXECUTABLE=#{py3_binary}"
        args << "-DPYTHON_LIBRARY=#{py3_lib}"
        args << "-DPYTHON_INCLUDE_DIR=#{py3_inc}"
        args << "-DCMAKE_INSTALL_PYTHONDIR=#{py3_sitepack}"
        args << ".."
        system "cmake", *args
        system "make", "-j#{ENV.make_jobs}", "install"
      end
    end

    if OS.linux?
      python_version = Language::Python.major_minor_version "python"
      system "patchelf", "--set-rpath", "#{HOMEBREW_PREFIX}/lib",
             lib/"python#{python_version}/site-packages/_mdt.so"
    end
  end

  test do
    Language::Python.each_python(build) do |python, _version|
      system python, "-c", "import mdt"
    end
  end
end
