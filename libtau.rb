require 'formula'

# libTAU is needed to build the IMP MultiFit modules
class Libtau < Formula
  homepage 'http://salilab.org/imp/libTAU.html'
  url 'http://salilab.org/imp/libTAU/libTAU-1.0.1.zip'
  sha1 '2ae493b3a4a65df778de731ce3167e00f660a52d'

  option :universal

  def install
    ENV.universal_binary if build.universal?

    args = ["#{prefix}"]
    args << "--universal" if build.universal?

    system "./mac-install.py", *args
  end
end
