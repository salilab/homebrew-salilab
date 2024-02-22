require 'formula'

# libTAU is needed to build the IMP MultiFit modules
class Libtau < Formula
  desc "Support library needed for IMP's MultiFit module"
  homepage 'http://integrativemodeling.org/libTAU.html'
  url 'https://integrativemodeling.org/libTAU/libTAU-1.0.2.zip'
  sha256 'd539436c0f4222bfb27ef34c9220a1977431f1f5989720321a6209b7e5bc532a'

  depends_on "python@3.12" => :build

  def install
    args = ["#{prefix}"]

    if OS.mac?
      system Formula["python@3.12"].opt_bin/"python3.12", "mac-install.py", *args
    elsif OS.linux?
      lib.install "lib/Fedora23.x86_64/libTAU.so.1"
      ln_s "libTAU.so.1", lib/"libTAU.so"
      (include/"libTAU").install Dir["include/*"]
    end
  end
end
