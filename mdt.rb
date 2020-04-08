require 'formula'

class Mdt < Formula
  desc "Generate frequency tables used by Modeller and IMP."
  homepage 'https://salilab.org/mdt/'
  url 'https://salilab.org/mdt/5.5/mdt-5.5.tar.gz'
  sha256 '94b3dbd3050be14568ed613cc1d534e11ef37cb32a646116f35ef66cab5c187c'

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
    python_version = Language::Python.major_minor_version "python3.7"
    python_framework = (Formula["python"].opt_prefix)/"Frameworks/Python.framework/Versions/#{python_version}"
    py3_inc = "#{python_framework}/Headers"
    py3_sitepack = "#{lib}/python#{python_version}/site-packages"

    inreplace "pyext/SConscript" do |s|
      s.gsub! /'include'\)/, "'include').replace('3.8', '3.7')"
    end

    system "scons", "-j #{ENV.make_jobs}",
                    "prefix=#{prefix}",
                    "libdir=#{lib}",
                    "includepath=#{hdf5_formula.include}",
                    "libpath=#{hdf5_formula.lib}",
                    "python=python3.7",
                    "pythoninclude=#{py3_inc}",
                    "pythondir=#{py3_sitepack}",
                    "install"
    File.rename("#{lib}/python3.7/site-packages/_mdt.cpython-38-darwin.so",
                "#{lib}/python3.7/site-packages/_mdt.cpython-37m-darwin.so")

    if OS.linux?
      python_version = Language::Python.major_minor_version "python"
      system "patchelf", "--set-rpath", "#{HOMEBREW_PREFIX}/lib",
             lib/"python#{python_version}/site-packages/_mdt.so"
    end

  end

  def test
    Language::Python.each_python(build) do |python, version|
      system python, "-c", "import mdt"
    end
  end
end
