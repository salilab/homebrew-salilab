require 'formula'

class IfortRuntime < Formula
  desc "Intel Fortran runtime libraries"
  homepage 'http://salilab.org/modeller/'
  # Extract Intel Fortran runtime from the Modeller installer image
  url 'http://salilab.org/modeller/9.15/modeller-9.15-mac.pax.gz' if OS.mac?
  sha256 'd1ef0b6b50680dbacc20bc3fb909d86b77026195f70dd5e0e2f07573592f1c22' if OS.mac?
  url 'http://salilab.org/modeller/9.15/modeller-9.15.tar.gz' if OS.linux?
  sha256 '9833eace132429abee54f2f7055a55f88ac9990cd79024f95a58d12161ca8eee' if OS.linux?
  version "1.11.0"

  keg_only "Don't conflict with other Intel ifort/icc libs"

  depends_on 'patchelf' => :build if OS.linux?

  def install
    if OS.mac?
      libtop = "Library/modeller-9.15/lib/mac10v4"
      libs = ["ifcore", "imf", "intlc", "irc", "svml"]
      libs.each do |l|
        lib.install "#{libtop}/lib#{l}.dylib"
        # Set path to dependent libs to Homebrew location, not that used
        # by the Modeller installer
        libs.each do |dep|
          system "install_name_tool", "-change", "/#{libtop}/lib#{dep}.dylib",
                 "#{lib}/lib#{dep}.dylib", "#{lib}/lib#{l}.dylib"
        end
      end
    end
    if OS.linux?
      libtop = "lib/x86_64-intel8"
      libs = ["ifcore.so.5", "imf.so", "intlc.so.5", "svml.so"]
      libs.each do |l|
        lib.install "#{libtop}/lib#{l}"
        system "patchelf", "--set-rpath", lib, "#{lib}/lib#{l}"
      end
    end
  end

end
