require 'formula'

# This is just the regular hdf5 formula, but held at 1.8.8, to be consistent
# with the version that Modeller uses. We also disable the questionably-licensed
# szip compression.
class Hdf5188 < Formula
  desc "File format designed to store large amounts of data"
  homepage 'http://www.hdfgroup.org/HDF5'
  url 'http://www.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8.8/src/hdf5-1.8.8.tar.bz2'
  sha256 'b0ebb0b5478c6c0427631d4ad08f96e39f1b09fde615aa98d2a1b8fb7f6dced3'

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
