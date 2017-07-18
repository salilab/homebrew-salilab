require 'formula'

# This is just the regular hdf5 formula, but held at 1.8.18, to be consistent
# with the version that Modeller uses. We also disable the questionably-licensed
# szip compression.
class Hdf5AT1818 < Formula
  desc "File format designed to store large amounts of data"
  homepage 'http://www.hdfgroup.org/HDF5'
  url 'https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8/hdf5-1.8.18/src/hdf5-1.8.18.tar.bz2'
  sha256 '01c6deadf4211f86922400da82c7a8b5b50dc8fc1ce0b5912de3066af316a48c'

  keg_only "Don't interfere with the regular HDF5 formula if installed."

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 "509536d5800e1d3442f04f54d472da51bc8082ace8fa357d42c91169e690ec2e" => :el_capitan
    sha256 "bc50428ce532696c15df19dfb9fc7247bb25ffc0a6c5710f844f6a17880a281e" => :yosemite
    sha256 "27aca7c4a25b82ffd81e0f37ba6503aeb5d9537fe78fcf8aa8b2fb67a1d95b89" => :sierra
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
