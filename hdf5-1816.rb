require 'formula'

# This is just the regular hdf5 formula, but held at 1.8.16, to be consistent
# with the version that Modeller uses. We also disable the questionably-licensed
# szip compression.
class Hdf51816 < Formula
  desc "File format designed to store large amounts of data"
  homepage 'http://www.hdfgroup.org/HDF5'
  url 'https://www.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8.16/src/hdf5-1.8.16.tar.bz2'
  sha256 '13aaae5ba10b70749ee1718816a4b4bfead897c2fcb72c24176e759aec4598c6'

  keg_only "Don't interfere with the regular HDF5 formula if installed."

  bottle do
    root_url "http://salilab.org/homebrew/bottles"
    sha256 "a22de3f41ddb0449c91f3c17e015dd5ae1188a9f3a07257c84d7f8906e88802c" => :yosemite
    sha256 "f8494ca45a1ab1fd1e1e6d7d5e3c12a96c41f4ffd2ade90244b030ee682c101c" => :el_capitan
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
