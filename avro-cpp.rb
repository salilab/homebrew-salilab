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
diff -Nur orig/api/DataFile.hh patched/api/DataFile.hh
--- orig/api/DataFile.hh	2012-07-04 02:10:24.000000000 -0700
+++ patched/api/DataFile.hh	2012-11-19 17:25:30.854758012 -0800
@@ -93,7 +93,7 @@
      * Constructs a data file writer with the given sync interval and name.
      */
     DataFileWriterBase(const char* filename, const ValidSchema& schema,
-        size_t syncInterval);
+                       size_t syncInterval, bool append=false);
 
     ~DataFileWriterBase();
     /**
@@ -124,8 +124,8 @@
      * Constructs a new data file.
      */
     DataFileWriter(const char* filename, const ValidSchema& schema,
-        size_t syncInterval = 16 * 1024) :
-        base_(new DataFileWriterBase(filename, schema, syncInterval)) { }
+                   size_t syncInterval = 16 * 1024, bool append=false) :
+      base_(new DataFileWriterBase(filename, schema, syncInterval, append)) { }
 
     /**
      * Writes the given piece of data into the file.
diff -Nur orig/api/Stream.hh patched/api/Stream.hh
--- orig/api/Stream.hh	2012-05-16 01:21:01.000000000 -0700
+++ patched/api/Stream.hh	2012-11-19 17:25:30.854758012 -0800
@@ -148,7 +148,8 @@
  * If there is no file with the given name, it is created.
  */
 AVRO_DECL std::auto_ptr<OutputStream> fileOutputStream(const char* filename,
-    size_t bufferSize = 8 * 1024);
+                                                       size_t bufferSize = 8 * 1024,
+                                                       bool append=false);
 
 /**
  * Returns a new InputStream whose contents come from the given file.
diff -Nur orig/impl/Compiler.cc patched/impl/Compiler.cc
--- orig/impl/Compiler.cc	2012-05-20 09:51:44.000000000 -0700
+++ patched/impl/Compiler.cc	2012-11-19 17:25:26.767724243 -0800
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
@@ -324,7 +329,11 @@
         error = e.what();
         return false;
     }
+}
 
+AVRO_DECL ValidSchema compileJsonSchemaFromFile(const char* filename) {
+  std::auto_ptr<InputStream> is= fileInputStream(filename);
+  return compileJsonSchemaFromStream(*is);
 }
 
 } // namespace avro
diff -Nur orig/impl/DataFile.cc patched/impl/DataFile.cc
--- orig/impl/DataFile.cc	2012-07-04 02:10:24.000000000 -0700
+++ patched/impl/DataFile.cc	2012-11-19 17:25:30.854758012 -0800
@@ -50,10 +50,11 @@
 }
 
 DataFileWriterBase::DataFileWriterBase(const char* filename,
-    const ValidSchema& schema, size_t syncInterval) :
+                                       const ValidSchema& schema,
+                                       size_t syncInterval, bool append) :
     filename_(filename), schema_(schema), encoderPtr_(binaryEncoder()),
     syncInterval_(syncInterval),
-    stream_(fileOutputStream(filename)),
+    stream_(fileOutputStream(filename, 8 * 1024, append)),
     buffer_(memoryOutputStream()),
     sync_(makeSync()), objectCount_(0)
 {
@@ -66,7 +67,7 @@
 
     setMetadata(AVRO_SCHEMA_KEY, toString(schema));
 
-    writeHeader();
+    if (!append) writeHeader();
     encoderPtr_->init(*buffer_);
 }
 
diff -Nur orig/impl/FileStream.cc patched/impl/FileStream.cc
--- orig/impl/FileStream.cc	2012-08-26 21:53:02.000000000 -0700
+++ patched/impl/FileStream.cc	2012-11-19 17:25:30.855758079 -0800
@@ -203,6 +203,24 @@
 };
 
 namespace {
+#ifdef _WIN32
+  HANDLE get_out_file(const char *filename, bool append) {
+    if (!append) {
+      return ::CreateFile(filename, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL)
+    } else {
+      return ::CreateFile(filename, FILE_APPEND_DATA , FILE_SHARE_WRITE & FILE_SHARE_READ,
+                          NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
+    }
+#else
+  int get_out_mode(bool append) {
+    if (!append) {
+      return  O_WRONLY | O_CREAT | O_TRUNC | O_BINARY;
+    } else {
+      return  O_WRONLY | O_APPEND | O_BINARY;
+    }
+  }
+#endif
+
 struct BufferCopyOut {
     virtual ~BufferCopyOut() { }
     virtual void write(const uint8_t* b, size_t len) = 0;
@@ -211,8 +229,8 @@
 struct FileBufferCopyOut : public BufferCopyOut {
 #ifdef _WIN32
     HANDLE h_;
-    FileBufferCopyOut(const char* filename) :
-        h_(::CreateFile(filename, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL)) {
+  FileBufferCopyOut(const char* filename, bool append) :
+    h_(get_out_file(filename, append)) {
         if (h_ == INVALID_HANDLE_VALUE) {
             throw Exception(boost::format("Cannot open file: %1%") % ::GetLastError());
         }
@@ -235,8 +253,8 @@
 #else
     const int fd_;
 
-    FileBufferCopyOut(const char* filename) :
-        fd_(::open(filename, O_WRONLY | O_CREAT | O_TRUNC | O_BINARY, 0644)) {
+  FileBufferCopyOut(const char* filename, bool append) :
+    fd_(::open(filename, get_out_mode(append), 0644)) {
 
         if (fd_ < 0) {
             throw Exception(boost::format("Cannot open file: %1%") %
@@ -337,9 +355,9 @@
 }
 
 auto_ptr<OutputStream> fileOutputStream(const char* filename,
-    size_t bufferSize)
+                                        size_t bufferSize, bool append)
 {
-    auto_ptr<BufferCopyOut> out(new FileBufferCopyOut(filename));
+  auto_ptr<BufferCopyOut> out(new FileBufferCopyOut(filename, append));
     return auto_ptr<OutputStream>(new BufferCopyOutputStream(out, bufferSize));
 }
 
