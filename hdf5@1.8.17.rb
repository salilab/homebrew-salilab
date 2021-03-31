require 'formula'

# This is just the regular hdf5 formula, but held at 1.8.17, to be consistent
# with the version that Modeller uses. We also disable the questionably-licensed
# szip compression.
class Hdf5AT1817 < Formula
  desc "File format designed to store large amounts of data"
  homepage 'http://www.hdfgroup.org/HDF5'
  url 'https://www.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8.17/src/hdf5-1.8.17.tar.bz2'
  sha256 'fc35dd8fd8d398de6b525b27cc111c21fc79795ad6db1b1f12cb15ed1ee8486a'

  keg_only "Don't interfere with the regular HDF5 formula if installed."

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 "38c800df7c38554ace63dd0b725c633362c8abeb522124c0631c3ddc1e16a242" => :yosemite
    sha256 "25a78331e42be52f9af7db72e3a05053d7291ab5c502f9863bbd70fc5a58ddb2" => :el_capitan
    sha256 "6f80ff24e2accd94048d47f4e141b990fc347e3aca3448044f6c8630a6597c4d" => :sierra
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
