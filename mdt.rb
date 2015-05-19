require 'formula'

class Mdt < Formula
  homepage 'http://salilab.org/mdt/'
  url 'http://salilab.org/mdt/5.3/mdt-5.3.tar.gz'
  sha1 'ddaed8c4ea7f28ddbe5da540e9c1ba1cbf4236e8'

  depends_on 'scons' => :build
  depends_on 'swig' => :build
  depends_on 'glib'
  depends_on 'hdf5-1813' # Need same version of HDF5 as Modeller

  def install
    system "scons", "-j #{ENV.make_jobs}",
                    "prefix=#{prefix}",
                    "install"
  end

  def test
    system "scons", "test"
  end
end
