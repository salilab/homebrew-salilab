require 'formula'

# libTAU is needed to build the IMP MultiFit modules
class Libtau < Formula
  homepage 'http://salilab.org/imp/libTAU.html'
  url 'http://salilab.org/imp/libTAU/libTAU-1.0.0.zip'
  sha1 '861614ac6c03f82c1ee17ccb66caf975a051dc0b'

  option :universal

  def install
    ENV.universal_binary if build.universal?

    args = ["#{prefix}"]
    args << "--universal" if build.universal?

    system "./mac-install.py", *args
  end
end
