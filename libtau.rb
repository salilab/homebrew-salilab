require 'formula'

# libTAU is needed to build the IMP MultiFit modules
class Libtau < Formula
  desc "Support library needed for IMP's MultiFit module"
  homepage 'http://integrativemodeling.org/libTAU.html'
  url 'http://integrativemodeling.org/libTAU/libTAU-1.0.1.zip'
  sha256 'f3a3319cdd6dda71ca1d6f04f4c401f15d6f715249fa476dca0d7e94580fe882'

  option :universal

  def install
    ENV.universal_binary if build.universal?

    args = ["#{prefix}"]
    args << "--universal" if build.universal?

    system "./mac-install.py", *args
  end
end
