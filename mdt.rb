require 'formula'

class Mdt < Formula
  homepage 'http://salilab.org/mdt/'
  url 'http://salilab.org/mdt/5.3/mdt-5.3.tar.gz'
  sha1 '9bc08fdae5247d82d4adba8ca1ba07edf4da254c'

  depends_on 'scons' => :build
  depends_on 'swig' => :build
  depends_on 'glib'
  depends_on 'hdf5-1813' # Need same version of HDF5 as Modeller

  def install
    hdf5_formula = Formula['hdf5-1813']
    system "scons", "-j #{ENV.make_jobs}",
                    "prefix=#{prefix}",
                    "includepath=#{hdf5_formula.include}",
                    "libpath=#{hdf5_formula.lib}",
                    "install"
  end

  def test
    Language::Python.each_python(build) do |python, version|
      system python, "-c", "import mdt"
    end
  end
end
