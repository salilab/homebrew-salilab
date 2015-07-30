require 'formula'

# libTAU is needed to build the IMP MultiFit modules
class Libtau < Formula
  homepage 'http://salilab.org/imp/libTAU.html'
  url 'http://salilab.org/imp/libTAU/libTAU-1.0.1.zip'
  sha256 '0eb798f9f5ae637e40b7befaaed91c8fd155a4f20c55fac4bdf8af24ef292f1f'

  option :universal

  def install
    ENV.universal_binary if build.universal?

    args = ["#{prefix}"]
    args << "--universal" if build.universal?

    system "./mac-install.py", *args
  end
end
