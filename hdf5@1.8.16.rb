require 'formula'

# This is just the regular hdf5 formula, but held at 1.8.16, to be consistent
# with the version that Modeller uses. We also disable the questionably-licensed
# szip compression.
class Hdf5AT1816 < Formula
  desc "File format designed to store large amounts of data"
  homepage 'http://www.hdfgroup.org/HDF5'
  url 'https://www.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8.16/src/hdf5-1.8.16.tar.bz2'
  sha256 '13aaae5ba10b70749ee1718816a4b4bfead897c2fcb72c24176e759aec4598c6'

  keg_only "Don't interfere with the regular HDF5 formula if installed."

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 yosemite:      "fd02fbf80666597ea629f59894078a54d55153fa28162cca33782b4bd20938cd"
    sha256 el_capitan:    "25ee40e7471f959dbe0fe2cb99aeceaf148dcd281b992c44b63ba20436d7935a"
    sha256 sierra:        "ef1fd3b94b697ecc060c5aa5973f9af4a8292ca4af3ca2403d1bd86b101b5bd9"
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
