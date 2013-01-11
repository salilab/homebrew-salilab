require 'formula'

# This is based on the regular avro-c formula, and adds the avro C++ library
class AvroCpp < Formula
  homepage 'http://avro.apache.org/'
  url 'http://www.apache.org/dyn/closer.cgi?path=avro/avro-1.7.3/cpp/avro-cpp-1.7.3.tar.gz'
  sha1 '01761badfc54c77ccebe1c5b0f88c0b2f3b03790'

  depends_on 'cmake' => :build

  def install
    system "cmake", ".", *std_cmake_args
    system "make install"
  end
end
