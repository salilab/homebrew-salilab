require 'formula'

# libTAU is needed to build the IMP MultiFit modules
class Libtau < Formula
  desc "Support library needed for IMP's MultiFit module"
  homepage 'http://integrativemodeling.org/libTAU.html'
  url 'http://integrativemodeling.org/libTAU/libTAU-1.0.1.zip'
  sha256 'b6dd528bcced1d0f67366f84d2476162c91d97349e5eb9b7fd18b75075d11360'

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
