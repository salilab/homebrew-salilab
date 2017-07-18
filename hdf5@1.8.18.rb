require 'formula'

# This is just the regular hdf5 formula, but held at 1.8.18, to be consistent
# with the version that Modeller uses. We also disable the questionably-licensed
# szip compression.
class Hdf5AT1818 < Formula
  desc "File format designed to store large amounts of data"
  homepage 'http://www.hdfgroup.org/HDF5'
  url 'https://www.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8.18/src/hdf5-1.8.18.tar.bz2'
  sha256 '01c6deadf4211f86922400da82c7a8b5b50dc8fc1ce0b5912de3066af316a48c'

  keg_only "Don't interfere with the regular HDF5 formula if installed."

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
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
