require 'formula'

class Mdt < Formula
  homepage 'http://salilab.org/mdt/'
  url 'http://salilab.org/mdt/5.3/mdt-5.3.tar.gz'
  sha1 '306606523dc69056d1488108019974f85518901d'

  depends_on 'scons' => :build
  depends_on 'swig' => :build
  depends_on 'glib'
  depends_on 'hdf5-1813' # Need same version of HDF5 as Modeller

  def install
    system "scons", "-j #{ENV.make_jobs}",
                    "prefix=#{prefix}",
                    "includepath=#{HOMEBREW_PREFIX}/Cellar/hdf5-1813/1.8.13/include",
                    "libpath=#{HOMEBREW_PREFIX}/Cellar/hdf5-1813/1.8.13/lib",
                    "install"
  end

  def test
    system "scons", "test"
  end
end
