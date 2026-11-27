# libTAU is needed to build the IMP MultiFit modules
class Libtau < Formula
  desc "Support library needed for IMP's MultiFit module"
  homepage "http://integrativemodeling.org/libTAU.html"
  url "https://integrativemodeling.org/libTAU/libTAU-1.0.2.zip"
  sha256 "d539436c0f4222bfb27ef34c9220a1977431f1f5989720321a6209b7e5bc532a"
  revision 1

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_golden_gate: "658d85dde4d7e3a0ad9e4f8d75b9474c1ff090c8794c5c1205bd6bef5a35c6bd"
    sha256 arm64_tahoe:       "206f06ad7e5689a2cc78e24b86f325cf45d018da05b661de80538d222467306f"
    sha256 arm64_sequoia:     "7ee29715833de187966b2e62ac913f856bc8ea215c20121e8a8c88882d9474fc"
  end

  depends_on "python@3.15" => :build

  def install
    args = [prefix.to_s]

    if OS.mac?
      system formula_opt_bin("python@3.15")/"python3.15", "mac-install.py", *args
    elsif OS.linux?
      lib.install "lib/Fedora23.x86_64/libTAU.so.1"
      ln_s "libTAU.so.1", lib/"libTAU.so"
      (include/"libTAU").install Dir["include/*"]
    end
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <libTAU/Matrix3.h>
      int main() {
        TAU::Matrix3 m(2.0);
        TAU::Vector3 v = m * TAU::Vector3(1., 2., 3.);
        v.show();
        return 0;
      }
    CPP
    system ENV.cxx, "test.cpp", "-I#{include}", "-L#{lib}", "-lTAU", "-o", "test"
    assert_equal "2 4 6", shell_output("./test").strip
  end
end
