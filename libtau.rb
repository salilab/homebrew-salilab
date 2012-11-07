require 'formula'

# libTAU is needed to build the IMP MultiFit modules
class Libtau < Formula
  homepage 'http://salilab.org/imp/libTAU/'
  url 'http://salilab.org/imp/libTAU/libTAU-1.0.0.zip'
  sha1 'de3e265668cfa1cd66a19cb0595bf5f18953a052'

  option :universal

  def install
    ENV.universal_binary if build.universal?

    args = ["#{prefix}"]
    args << "--universal" if build.universal?

    system "./mac-install.py", *args
  end
end
