require 'formula'

# libTAU is needed to build the IMP MultiFit modules
class Libtau < Formula
  desc "Support library needed for IMP's MultiFit module"
  homepage 'http://integrativemodeling.org/libTAU.html'
  url 'http://integrativemodeling.org/libTAU/libTAU-1.0.1.zip'
  sha256 'ebb4c008b50d2cf665e51704887353aa1901dd9de83ccd3e7680d5f955edd5b2'

  option :universal

  def install
    ENV.universal_binary if build.universal?

    args = ["#{prefix}"]
    args << "--universal" if build.universal?

    if OS.mac?
      system "./mac-install.py", *args
    elsif OS.linux?
      lib.install "lib/Fedora23.x86_64/libTAU.so.1"
      ln_s "libTAU.so.1", lib/"libTAU.so"
      (include/"libTAU").install Dir["include/*"]
    end
  end
end
