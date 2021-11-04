require 'formula'

# This is just the regular hdf5 formula, but held at 1.10.7, to be consistent
# with the version that Modeller uses. We also disable the questionably-licensed
# szip compression.
class Hdf5AT1107 < Formula
  desc "File format designed to store large amounts of data"
  homepage 'http://www.hdfgroup.org/HDF5'
  url 'https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.10/hdf5-1.10.7/src/hdf5-1.10.7.tar.bz2'
  sha256 '02018fac7e5efc496d9539a303cfb41924a5dadffab05df9812096e273efa55e'

  keg_only "it shouldn't interfere with the regular HDF5 formula if installed"

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_big_sur: "482541fb672fcacf97d3560e634ac4927541e9bbc4a4f3985913fe2dfed09e8e"
    sha256 monterey:      "84935833702e995a120083840272596060fd87dd7816c622fd8e9ee8a60b69fc"
    sha256 big_sur:       "bddf432b5167972c31b81b7deac485e81f0b1d565b721203d696ccad304ee47d"
    sha256 catalina:      "bd414dbcd0fe76063e06ae3304d4fcedfbe631db68792e54aaf3c7769be3ba75"
  end

  def install
    # The older gcc in OS X 10.6 doesn't like the use of #pragma pack()
    if MacOS.version <= :snow_leopard
      inreplace "hl/c++/test/ptableTest.cpp", "#pragma pack()", "#pragma pack(1)"
    end

    args = %W[
      --prefix=#{prefix}
      --enable-build-mode=production
      --disable-dependency-tracking
      --with-zlib=/usr
      --with-szlib=no
      --enable-filters=all
      --enable-static=yes
      --enable-shared=yes
    ]

    system "./configure", *args
    system "make install"
  end

  test do
    (testpath/"test.c").write <<~EOS
      #include <stdio.h>
      #include "hdf5.h"
      int main()
      {
        printf("%d.%d.%d\\n", H5_VERS_MAJOR, H5_VERS_MINOR, H5_VERS_RELEASE);
        return 0;
      }
    EOS
    system "#{bin}/h5cc", "test.c"
    assert_equal version.to_s, shell_output("./a.out").chomp
  end
end
