require 'formula'

class Mdt < Formula
  homepage 'http://salilab.org/mdt/'
  url 'http://salilab.org/mdt/5.2/mdt-5.2.tar.gz'
  sha1 '97f2771fedef141805f25662bc8dc52cb261c460'

  depends_on 'scons' => :build
  depends_on 'swig' => :build
  depends_on 'glib'
  depends_on 'hdf5-189' # Need same version of HDF5 as Modeller

  def install
    system "scons", "-j #{ENV.make_jobs}",
                    "prefix=#{prefix}",
                    "install"
  end

  def test
    system "scons", "test"
  end
end
