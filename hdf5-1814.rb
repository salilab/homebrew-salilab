require 'formula'

# This is just the regular hdf5 formula, but held at 1.8.14, to be consistent
# with the version that Modeller uses. We also disable the questionably-licensed
# szip compression.
class Hdf51814 < Formula
  desc "File format designed to store large amounts of data"
  homepage 'http://www.hdfgroup.org/HDF5'
  url 'http://www.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8.14/src/hdf5-1.8.14.tar.bz2'
  sha256 '53722cb9f5977af2908f92fc1a3f8c597800a5cb448cfe5c75060d6335bb9bab'

  keg_only "Don't interfere with the regular HDF5 formula if installed."

  bottle do
    root_url "http://salilab.org/homebrew/bottles"
    sha256 "d331a0a171126e0b7825896592614d58799adb3fa5e9fa307071aae60f8f9eb1" => :yosemite
    sha256 "3515a41ab10e97e21322cdda642d85096780fc10e77b1674ab59932e7a4b8626" => :el_capitan
  end

  # TODO - warn that these options conflict
  option 'enable-fortran', 'Compile Fortran bindings'
  option 'enable-threadsafe', 'Trade performance and C++ or Fortran support for thread safety'

  def install
    args = %W[
      --prefix=#{prefix}
      --enable-production
      --enable-debug=no
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
end
