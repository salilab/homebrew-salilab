require 'formula'

class Mdt < Formula
  homepage 'http://salilab.org/mdt/'
  url 'http://salilab.org/mdt/5.3/mdt-5.3.tar.gz'
  sha1 '9bc08fdae5247d82d4adba8ca1ba07edf4da254c'
  revision 1

  depends_on :python => :recommended
  depends_on :python3 => :optional

  depends_on 'scons' => :build
  depends_on 'swig' => :build
  depends_on 'glib'
  depends_on 'hdf5-1814' # Need same version of HDF5 as Modeller

  def install
    hdf5_formula = Formula['hdf5-1814']
    system "scons", "-j #{ENV.make_jobs}",
                    "prefix=#{prefix}",
                    "includepath=#{hdf5_formula.include}",
                    "libpath=#{hdf5_formula.lib}",
                    "install"

    if build.with? 'python3'
      python_version = Language::Python.major_minor_version "python3"
      python_framework = (Formula["python3"].opt_prefix)/"Frameworks/Python.framework/Versions/#{python_version}"
      py3_inc = "#{python_framework}/Headers"
      py3_sitepack = "#{lib}/python#{python_version}/site-packages"

      system "scons", "-j #{ENV.make_jobs}",
                      "prefix=#{prefix}",
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
