require 'formula'

class IfortRuntime < Formula
  homepage 'http://salilab.org/modeller/'
  # Extract Intel Fortran runtime from the Modeller installer image
  url 'http://salilab.org/modeller/9.15/modeller-9.15-mac.pax.gz'
  version "1.11.0"
  sha256 'd1ef0b6b50680dbacc20bc3fb909d86b77026195f70dd5e0e2f07573592f1c22'

  keg_only "Don't conflict with other Intel ifort/icc libs"

  def install
    libtop = "Library/modeller-9.15/lib/mac10v4"
    libs = ["ifcore", "imf", "intlc", "irc", "svml"]
    libs.each do |l|
      lib.install "#{libtop}/lib#{l}.dylib"
      # Set path to dependent libs to Homebrew location, not that used
      # by the Modeller .dmg installer
      libs.each do |dep|
        system "install_name_tool", "-change", "/#{libtop}/lib#{dep}.dylib",
               "#{lib}/lib#{dep}.dylib", "#{lib}/lib#{l}.dylib"
      end
    end
  end

end
