require 'formula'

# This is just the regular hdf5 formula, but held at 1.8.20, to be consistent
# with the version that Modeller uses. We also disable the questionably-licensed
# szip compression.
class Hdf5AT1820 < Formula
  desc "File format designed to store large amounts of data"
  homepage 'http://www.hdfgroup.org/HDF5'
  url 'https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8/hdf5-1.8.20/src/hdf5-1.8.20.tar.bz2'
  sha256 'a4f2db7e0a078aa324f64e0216a80731731f73025367fa94d158c9b1d3fbdf6f'

  keg_only "Don't interfere with the regular HDF5 formula if installed."

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 "c88e7d45af823e170f75d1bc62243eec1f271f30e8c06b1c8c4d4f4a965afc2e" => :mojave
    sha256 "31d2b9759a7bc5f27b13319e174f9b11a8cbca1eae4e8debbe663106513c45c8" => :high_sierra
    sha256 "3cf349fb25eb7a5db64043ba31b82fa9cacc210fb5b4c74832210d276cbc6d78" => :yosemite
    sha256 "82ed2b5574d0f23e03053bdc1ee9dbcaba8db08e5a96d3dd3b7f73b996275786" => :el_capitan
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
