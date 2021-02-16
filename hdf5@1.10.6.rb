require 'formula'

# This is just the regular hdf5 formula, but held at 1.10.6, to be consistent
# with the version that Modeller uses. We also disable the questionably-licensed
# szip compression.
class Hdf5AT1106 < Formula
  desc "File format designed to store large amounts of data"
  homepage 'http://www.hdfgroup.org/HDF5'
  url 'https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.10/hdf5-1.10.6/src/hdf5-1.10.6.tar.bz2'
  sha256 '09d6301901685201bb272a73e21c98f2bf7e044765107200b01089104a47c3bd'

  keg_only "it shouldn't interfere with the regular HDF5 formula if installed"

  bottle do
    root_url "https://dl.bintray.com/salilab/homebrew"
    sha256 cellar: :any, arm64_big_sur: "603b90aacd9739f9727d8cd5f8c903c2bd9ddb88783d02fcea303bf315c52703"
    sha256 cellar: :any, big_sur:       "cefa5fd7b56db1a7df8968be15614524781415105a5d46899b08f9fb86e790c7"
    sha256 cellar: :any, catalina:      "bba37f9154e93aa039eb2f2cd3f475cde0d5fbde45ab569ff727d2ab10d62065"
    sha256 cellar: :any, mojave:        "73c2903f1fff23027c09e518b006ab789cb6b9ad8fe07082d8e8319cd4c97a3d"
    sha256 cellar: :any, high_sierra:   "11e8efa0d1108904d9d2b98d01a1f7b65a1c9819ac796cb477768c7bc7ed1ee4"

  end

  # TODO - warn that these options conflict
  option 'enable-fortran', 'Compile Fortran bindings'
  option 'enable-threadsafe', 'Trade performance and C++ or Fortran support for thread safety'

  def install
    # The older gcc in OS X 10.6 doesn't like the use of #pragma pack() or -Wvla
    if MacOS.version <= :snow_leopard
      inreplace "hl/c++/test/ptableTest.cpp", "#pragma pack()", "#pragma pack(1)"
      inreplace "config/gnu-flags", " -Wvla", ""
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
