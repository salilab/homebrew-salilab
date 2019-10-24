require 'formula'

class Mdt < Formula
  desc "Generate frequency tables used by Modeller and IMP."
  homepage 'https://salilab.org/mdt/'
  url 'https://salilab.org/mdt/5.4/mdt-5.4.tar.gz'
  sha256 'fc403b8c26365c11bd9522929aef0c3b51dff860fddc8ac446a980acec5a3d44'
  revision 2

  depends_on 'python@2' => :recommended
  depends_on 'python' => :recommended

  depends_on 'scons' => :build
  depends_on 'swig' => :build
  depends_on 'patchelf' => :build if OS.linux?
  depends_on 'glib'
  depends_on 'hdf5@1.8.20' # Need same version of HDF5 as Modeller
  depends_on 'ifort-runtime' # Need to link against Modeller Fortran libs

  def install
    hdf5_formula = Formula['hdf5@1.8.20']
    ifort_formula = Formula['ifort-runtime']
    system "scons", "-j #{ENV.make_jobs}",
                    "prefix=#{prefix}",
                    "libdir=#{lib}",
                    "includepath=#{hdf5_formula.include}",
		    "libpath=#{hdf5_formula.lib}:#{ifort_formula.lib}",
                    "install"

    if OS.linux?
      python_version = Language::Python.major_minor_version "python"
      system "patchelf", "--set-rpath", "#{HOMEBREW_PREFIX}/lib",
             lib/"python#{python_version}/site-packages/_mdt.so"
    end

    if build.with? 'python'
      python_version = Language::Python.major_minor_version "python3"
      python_framework = (Formula["python"].opt_prefix)/"Frameworks/Python.framework/Versions/#{python_version}"
      py3_inc = "#{python_framework}/Headers"
      py3_sitepack = "#{lib}/python#{python_version}/site-packages"

      system "scons", "-j #{ENV.make_jobs}",
                      "prefix=#{prefix}",
                      "libdir=#{lib}",
                      "includepath=#{hdf5_formula.include}",
                      "libpath=#{hdf5_formula.lib}",
                      "python=python3",
                      "pythoninclude=#{py3_inc}",
                      "pythondir=#{py3_sitepack}",
                      "install"
    end
  end

  def test
    Language::Python.each_python(build) do |python, version|
      system python, "-c", "import mdt"
    end
  end
end
