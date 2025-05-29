require 'formula'

# This is just the regular hdf5 formula, but held at 1.14.6, to be consistent
# with the version that Modeller uses. We also disable the questionably-licensed
# szip compression.
class Hdf5AT1146 < Formula
  desc "File format designed to store large amounts of data"
  homepage "https://www.hdfgroup.org/solutions/hdf5/"
  url "https://github.com/HDFGroup/hdf5/releases/download/hdf5_1.14.6/hdf5-1.14.6.tar.gz"
  sha256 "e4defbac30f50d64e1556374aa49e574417c9e72c6b1de7a4ff88c4b1bea6e9b"
  license "BSD-3-Clause"

  keg_only "it shouldn't interfere with the regular HDF5 formula if installed"

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_sequoia: "530f8835866249aa7ede534cb048bc2e56d85a630a30c4e92fd872dff07e5f17"
    sha256 arm64_sonoma:  "853a3c92065242a4e4edf13b0701c35842802f51f3d0d32e161b2d0cd89e9a6b"
    sha256 arm64_ventura: "7c2d65af89ff56c216928782733790e0e95bb6dcbc52ecad04cb24d42de66124"
    sha256 sequoia:       "8e1a308d8ce24108d336d3b2dd3bf910939b2d6b6db4cadb288f9ebc6f16ea45"
    sha256 sonoma:        "d24e9c108dc7cfa93adf816cbab21280ee59076d772b05cae8da2828bdde3b1d"
    sha256 ventura:       "c34d09ea4168538a10d5cb553a5a57d1a3989f10c685e3d42b7456400da610e8"
  end

  # OS X 10.6 doesn't have strnlen or strndup
  if MacOS.version <= :snow_leopard
    patch do
      url "https://salilab.org/homebrew/patches/hdf5-mac-strndup-strnlen.patch"
      sha256 "cb5a460b5074b620eae04c8f7f39546061c262252789b03c49f3fb986e981224"
    end
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

    # Older llvm is missing the __truncxfhf2 function needed to convert
    # long double to float16, causing HDF5 tests to fail; see also
    # https://github.com/HDFGroup/hdf5/issues/4310
    args << "--disable-nonstandard-feature-float16"

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
