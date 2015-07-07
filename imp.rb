require 'formula'

class Imp < Formula
  homepage 'http://integrativemodeling.org/'
  url 'http://integrativemodeling.org/2.5.0/download/imp-2.5.0.tar.gz'
  sha1 '6d4b2547bcc53cd2d704d874be8fddf75a33a601'

  depends_on 'cmake' => :build
  depends_on 'swig' => :build

  depends_on :python => :recommended
  depends_on :python3 => :optional

  depends_on 'boost'
  depends_on 'hdf5'
  depends_on 'fftw'
  depends_on 'libtau' => :recommended
  depends_on 'cgal' => :recommended
  depends_on 'gsl' => :recommended

  def install
    args = std_cmake_args
    args << ".."
    mkdir "build" do
      system "cmake", *args
      system "make"
      system "make", "install"
    end
  end
end
