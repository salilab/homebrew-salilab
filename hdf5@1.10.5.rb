require 'formula'

# This is just the regular hdf5 formula, but held at 1.10.5, to be consistent
# with the version that Modeller uses. We also disable the questionably-licensed
# szip compression.
class Hdf5AT1105 < Formula
  desc "File format designed to store large amounts of data"
  homepage 'http://www.hdfgroup.org/HDF5'
  url 'https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.10/hdf5-1.10.5/src/hdf5-1.10.5.tar.bz2'
  sha256 '68d6ea8843d2a106ec6a7828564c1689c7a85714a35d8efafa2fee20ca366f44'

  keg_only "it shouldn't interfere with the regular HDF5 formula if installed"

  bottle do
    root_url "https://dl.bintray.com/salilab/homebrew"
  end

  # TODO - warn that these options conflict
  option 'enable-fortran', 'Compile Fortran bindings'
  option 'enable-threadsafe', 'Trade performance and C++ or Fortran support for thread safety'

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

    if build.include? 'enable-threadsafe'
      args.concat %w[--with-pthread=/usr --enable-threadsafe]
    else
      args << '--enable-cxx'
      if build.include? 'enable-fortran'
        args << '--enable-fortran'
        ENV.fortran
      end
    end

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
