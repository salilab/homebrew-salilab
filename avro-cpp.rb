require 'formula'

# This is based on the regular avro-c formula, and adds the avro C++ library
class AvroCpp < Formula
  homepage 'http://avro.apache.org/'
  url 'http://www.apache.org/dyn/closer.cgi?path=avro/avro-1.7.2/cpp/avro-cpp-1.7.2.tar.gz'
  sha1 'f9116583e4f230288317410404b066664722f9e4'

  depends_on 'cmake' => :build

  def install
    system "cmake", ".", *std_cmake_args
    system "make install"
  end
end
