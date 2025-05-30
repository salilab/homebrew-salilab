require "formula"

class Mdt < Formula
  desc "Generate frequency tables used by Modeller and IMP"
  homepage "https://salilab.org/mdt/"
  url "https://salilab.org/mdt/5.5/mdt-5.5.tar.gz"
  sha256 "94b3dbd3050be14568ed613cc1d534e11ef37cb32a646116f35ef66cab5c187c"
  license "GPL-2.0-or-later"
  revision 14

  depends_on "patchelf" => :build if OS.linux?
  depends_on "cmake" => :build
  depends_on "swig" => :build
  depends_on "glib"
  depends_on "modeller"
  depends_on "python@3.13" => :recommended

  # Be sure to link against HDF5 HL library
  patch do
    url "https://github.com/salilab/mdt/commit/be7c9e286ae596169750f962490ef733bdb1a841.patch?full_index=1"
    sha256 "fa8746c87b603b3993f139478b6195ede113a1a4777a2addd8754cca261c8bd4"
  end

  # Fix build with Python 3.13
  patch do
    url "https://github.com/salilab/mdt/commit/0227a4229179f32aa20fdab400e5c47cc8c9cfb6.patch?full_index=1"
    sha256 "8409ec0330015921f8f91de30f48cdceb6d54d953795952f20bb0da4057df059"
  end

  # Fix build with Numpy 2
  patch do
    url "https://github.com/salilab/mdt/commit/7053e44ab0e0087a45db1d87646823fa4afc885c.patch?full_index=1"
    sha256 "39a56a5ac0ad869c30feb5cf49d3f2efa7dd9e137fdac498c2966c869454dca9"
  end

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
        args << "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
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
