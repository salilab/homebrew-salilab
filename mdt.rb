require "formula"

class Mdt < Formula
  desc "Generate frequency tables used by Modeller and IMP"
  homepage "https://salilab.org/mdt/"
  url "https://salilab.org/mdt/5.5/mdt-5.5.tar.gz"
  sha256 "94b3dbd3050be14568ed613cc1d534e11ef37cb32a646116f35ef66cab5c187c"
  license "GPL-2.0-or-later"
  revision 7

  depends_on "patchelf" => :build if OS.linux?
  depends_on "scons" => :build
  depends_on "swig" => :build
  depends_on "glib"
  depends_on "modeller"
  depends_on "python@3.9" => :recommended

  def install
    hdf5_formula = Formula["hdf5@1.10.6"]

    if build.with? "python@3.9"
      python_version = Language::Python.major_minor_version Formula["python@3.9"].opt_bin/"python3"
      python_framework = Formula["python@3.9"].opt_prefix/"Frameworks/Python.framework/Versions/#{python_version}"
      py3_inc = "#{python_framework}/Headers"
      py3_sitepack = "#{lib}/python#{python_version}/site-packages"
      system "scons", "-j #{ENV.make_jobs}",
                      "prefix=#{prefix}",
                      "libdir=#{lib}",
                      "includepath=#{hdf5_formula.include}",
                      "libpath=#{hdf5_formula.lib}",
                      "python=python3.9",
                      "pythoninclude=#{py3_inc}",
                      "pythondir=#{py3_sitepack}",
                      "install"
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
