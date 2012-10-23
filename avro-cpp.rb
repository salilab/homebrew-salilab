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

  def patches
    DATA
  end
end


__END__
--- orig/impl/Compiler.cc	2012-05-20 09:51:44.000000000 -0700
+++ patched/impl/Compiler.cc	2012-10-17 14:18:21.376910023 -0700
@@ -300,6 +300,11 @@
         ::strlen(input));
 }
 
+AVRO_DECL ValidSchema compileJsonSchemaFromString(const std::string& input)
+{
+  return compileJsonSchemaFromString(input.c_str());
+}
+
 static ValidSchema compile(std::istream& is)
 {
     std::auto_ptr<InputStream> in = istreamInputStream(is);
