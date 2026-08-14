require "formula"

class Imp < Formula
  desc "Integrative Modeling Platform"
  homepage "https://integrativemodeling.org/"
  url "https://integrativemodeling.org/2.25.0/download/imp-2.25.0.tar.gz"
  sha256 "2f7c1403524e8fa991e8b6cb59fa6c0d5d6c2005c41c20cabb66185f07ba3c5c"
  license "LGPL/GPL"
  revision 2

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_tahoe:   "fccbe0a580a80dd1ecd8818c35c1c53660f953a195be78d4005f780ae5192e18"
    sha256 arm64_sequoia: "56d1cd2558d6705a645e3decefa7b16ecdc54208fe0e90572092843d6436393b"
    sha256 arm64_sonoma:  "99e09be219f95d529932a4c46a62e1e7e087dfbac16e80749d52caad32d35e0a"
    sha256 tahoe:         "55ce9ab0f7c6e99d4dd31ee4d65239fd61e206d4c6f14b182b3976c14ac119e0"
    sha256 sequoia:       "8e6224e4257b6cef5096b8a6da283e68a0ae95526e965a9058dca69e624d35d7"
    sha256 sonoma:        "4b09b69604a20eac77fe6dd6f52c1f0acdf3b32972c61776b2282bb17a3a9684"
  end

  depends_on "cmake" => :build
  depends_on "pkg-config" => :build
  depends_on "swig" => :build
  depends_on "cereal" => :build

  depends_on "boost"
  depends_on "salilab/salilab/rmf"
  depends_on "salilab/salilab/ihm"
  depends_on "eigen"
  depends_on "fftw"
  depends_on "hdf5"
  depends_on "open-mpi"
  depends_on "protobuf"
  depends_on "python@3.14"
  depends_on "cgal" => :recommended
  depends_on "gsl" => :recommended
  depends_on "libtau" => :recommended
  depends_on "opencv" => :recommended

  # We need C++17 support for protobuf
  fails_with gcc: "5"

  # Fix build with SWIG 4.5
  patch :DATA

  def install
    pybin = Formula["python@3.14"].opt_bin/"python3.14"
    pyver = Language::Python.major_minor_version pybin
    args = std_cmake_args
    args << "-DCMAKE_CXX_FLAGS='-std=c++17'"
    args << "-DIMP_DISABLED_MODULES=scratch"
    args << "-DIMP_USE_SYSTEM_RMF=on"
    args << "-DIMP_USE_SYSTEM_IHM=on"
    args << ".."
    args << "-DCMAKE_INSTALL_PYTHONDIR=#{lib}/python#{pyver}/site-packages"
    # Otherwise linkage of _IMP_em2d.so fails on arm64 because it can't find
    # @rpath/libgcc_s.1.1.dylib
    gcclib = Formula["gcc"].lib/"gcc/current"
    args << "-DCMAKE_MODULE_LINKER_FLAGS=-L#{gcclib}"
    # Don't install in lib64 on Linux systems
    args << "-DCMAKE_INSTALL_LIBDIR=#{lib}"
    # Don't link against gperftools, even if they were found, since then the
    # bottle won't work on systems without gperftools installed
    args << "-DGPerfTools_found=0"
    # Don't link against log4cxx, even if available, since then the
    # bottle won't work on systems without log4cxx installed
    args << "-DLog4CXX_LIBRARY=Log4CXX_LIBRARY-NOTFOUND"
    args << "-DIMP_NO_LOG4CXX=1"
    # Help cmake to find CGAL
    ENV["CGAL_DIR"] = Formula["cgal"].lib/"cmake/CGAL"
    # Make sure we use Homebrew Python
    args << "-DPython3_EXECUTABLE:FILEPATH=#{pybin}"
    mkdir "build" do
      system "cmake", *args
      imppybins = []
      cd "bin" do
        imppybins = Dir.glob("*")
      end
      system "make"
      system "make", "install"
      cd bin do
        # Make sure binaries use Homebrew Python
        inreplace imppybins, %r{^#!.*python.*$}, "#!#{pybin}"
      end
    end
  end

  test do
    pythons = [Formula["python@3.14"].opt_bin/"python3.14"]
    pythons.each do |python|
      system python, "-c", "import IMP; assert(IMP.__version__ == '#{version}')"
      system python, "-c", "import IMP.em2d; assert(IMP.em2d.__version__ == '#{version}')"
      system python, "-c", "import IMP.cgal; assert(IMP.cgal.__version__ == '#{version}')"
      system python, "-c", "import IMP.foxs; assert(IMP.foxs.__version__ == '#{version}')"
      system python, "-c", "import IMP.multifit; assert(IMP.multifit.__version__ == '#{version}')"
      system python, "-c", "import IMP.npctransport; assert(IMP.npctransport.__version__ == '#{version}')"
      system python, "-c", "import IMP.bayesianem; assert(IMP.bayesianem.__version__ == '#{version}')"
      system python, "-c", "import IMP.sampcon; assert(IMP.sampcon.__version__ == '#{version}')"
      system python, "-c", "import IMP, RMF, os; name = IMP.create_temporary_file_name('assignments', '.hdf5'); root = RMF.HDF5.create_file(name); del root; os.unlink(name)"
      system python, "-c", "import IMP.rmf, RMF; b = RMF.BufferHandle(); r = RMF.create_rmf_buffer(b); m = IMP.Model(); p = IMP.Particle(m); IMP.rmf.add_particle(r, p)"
      system python, "-c", "import IMP.mpi; assert(IMP.mpi.__version__ == '#{version}')"
    end
    system "multifit"
    system "foxs"
  end
end

__END__
diff --git a/modules/algebra/pyext/IMP_algebra.transformation2d.i b/modules/algebra/pyext/IMP_algebra.transformation2d.i
index 146ef330ff..8872b05443 100644
--- a/modules/algebra/pyext/IMP_algebra.transformation2d.i
+++ b/modules/algebra/pyext/IMP_algebra.transformation2d.i
@@ -14,8 +14,8 @@ namespace IMP {
         $action(self, *args)
         return self
   %}
-  %feature("shadow") Transformation2D::__idiv__(double) %{
-    def __idiv__(self, *args):
+  %feature("shadow") Transformation2D::__itruediv__(double) %{
+    def __itruediv__(self, *args):
         $action(self, *args)
         return self
   %}
@@ -24,18 +24,11 @@ namespace IMP {
         $action(self, *args)
         return self
   %}
-  %feature("shadow") Rotation2D::__idiv__(double) %{
-    def __idiv__(self, *args):
+  %feature("shadow") Rotation2D::__itruediv__(double) %{
+    def __itruediv__(self, *args):
         $action(self, *args)
         return self
   %}
 
  }
 }
-
-%extend IMP::algebra::Transformation2D {
-  /* Support new-style "true" division */
-  %pythoncode %{
-  __truediv__ = __div__
-  %}
-}
diff --git a/modules/algebra/pyext/IMP_algebra.transformation3d.i b/modules/algebra/pyext/IMP_algebra.transformation3d.i
index c7259dc184..ddd4fd1f8a 100644
--- a/modules/algebra/pyext/IMP_algebra.transformation3d.i
+++ b/modules/algebra/pyext/IMP_algebra.transformation3d.i
@@ -14,8 +14,8 @@ namespace IMP {
         $action(self, *args)
         return self
   %}
-  %feature("shadow") Transformation3D::__idiv__(double) %{
-    def __idiv__(self, *args):
+  %feature("shadow") Transformation3D::__itruediv__(double) %{
+    def __itruediv__(self, *args):
         $action(self, *args)
         return self
   %}
@@ -24,25 +24,11 @@ namespace IMP {
         $action(self, *args)
         return self
   %}
-  %feature("shadow") Rotation3D::__idiv__(double) %{
-    def __idiv__(self, *args):
+  %feature("shadow") Rotation3D::__itruediv__(double) %{
+    def __itruediv__(self, *args):
         $action(self, *args)
         return self
   %}
 
  }
 }
-
-%extend IMP::algebra::Rotation3D {
-  /* Support new-style "true" division */
-  %pythoncode %{
-  __truediv__ = __div__
-  %}
-}
-
-%extend IMP::algebra::Transformation3D {
-  /* Support new-style "true" division */
-  %pythoncode %{
-  __truediv__ = __div__
-  %}
-}
diff --git a/modules/kernel/pyext/IMP_kernel.vector.i b/modules/kernel/pyext/IMP_kernel.vector.i
index c471524ab2..edc0e92ff8 100644
--- a/modules/kernel/pyext/IMP_kernel.vector.i
+++ b/modules/kernel/pyext/IMP_kernel.vector.i
@@ -19,8 +19,8 @@ namespace IMP {
         $action(self, *args)
         return self
   %}
-  %feature("shadow") VectorD<D>::__idiv__(double) %{
-    def __idiv__(self, *args):
+  %feature("shadow") VectorD<D>::__itruediv__(double) %{
+    def __itruediv__(self, *args):
         $action(self, *args)
         return self
   %}
@@ -65,7 +65,7 @@ namespace IMP {
      generate a new SWIG wrapper for the return value (see above). */
   void __iadd__(const IMP::VectorD<D> &o) { self->operator+=(o); }
   void __imul__(double f) { self->operator*=(f); }
-  void __idiv__(double f) { self->operator/=(f); }
+  void __itruediv__(double f) { self->operator/=(f); }
   void __isub__(const IMP::VectorD<D> &o) { self->operator-=(o); }
   unsigned int __len__() { return self->get_dimension(); }
   const IMP::VectorD<D> __rmul__(double f) const {return self->operator*(f);}
@@ -81,12 +81,6 @@ namespace IMP {
     IMP_THROW("Geometric primitives cannot be compared",
               IMP::ValueException);
   }
-
-  /* Support new-style "true" division */
-  %pythoncode %{
-  __truediv__ = __div__
-  __itruediv__ = __idiv__
-  %}
 };
 
 IMP_SWIG_VALUE_SERIALIZE_IMPL(IMP, VectorD<D>);
commit 4d9da70a6e05abe98d328541c6b783aa803e5b34 (HEAD -> refs/heads/salilab, refs/remotes/origin/salilab)
Author: Ben Webb <benmwebb@gmail.com>
Date:   Thu Aug 6 21:31:10 2026 -0700

    Don't rely on SWIG compatibility macros
    
    SWIG 4.5 no longer adds #defines to map some
    Python 2 API functions to Python 3 equivalents.
    In order to build with this SWIG version, use
    the correct Python 3 API instead.

diff --git a/modules/bff/pyext/numpy.i b/modules/bff/pyext/numpy.i
index b126c69..68ced13 100644
--- a/modules/bff/pyext/numpy.i
+++ b/modules/bff/pyext/numpy.i
@@ -114,8 +114,8 @@
     if (py_obj == NULL          ) return "C NULL value";
     if (py_obj == Py_None       ) return "Python None" ;
     if (PyCallable_Check(py_obj)) return "callable"    ;
-    if (PyString_Check(  py_obj)) return "string"      ;
-    if (PyInt_Check(     py_obj)) return "int"         ;
+    if (PyBytes_Check(   py_obj)) return "string"      ;
+    if (PyLong_Check(    py_obj)) return "int"         ;
     if (PyFloat_Check(   py_obj)) return "float"       ;
     if (PyDict_Check(    py_obj)) return "dict"        ;
     if (PyList_Check(    py_obj)) return "list"        ;
@@ -2007,7 +2007,7 @@
   (PyObject* array = NULL)
 {
   npy_intp dims[1];
-  if (!PyInt_Check($input))
+  if (!PyLong_Check($input))
   {
     const char* typestring = pytype_string($input);
     PyErr_Format(PyExc_TypeError,
@@ -2035,7 +2035,7 @@
   (PyObject* array = NULL)
 {
   npy_intp dims[1];
-  if (!PyInt_Check($input))
+  if (!PyLong_Check($input))
   {
     const char* typestring = pytype_string($input);
     PyErr_Format(PyExc_TypeError,
diff --git a/modules/kernel/include/internal/swig_helpers_base.h b/modules/kernel/include/internal/swig_helpers_base.h
index ba20fc09f0..6435b1ca1d 100644
--- a/modules/kernel/include/internal/swig_helpers_base.h
+++ b/modules/kernel/include/internal/swig_helpers_base.h
@@ -2,7 +2,7 @@
  *  \file internal/swig_helpers_base.h
  *  \brief Functions for use in swig wrappers
  *
- *  Copyright 2007-2024 IMP Inventors. All rights reserved.
+ *  Copyright 2007-2026 IMP Inventors. All rights reserved.
  */
 
 #ifndef IMPKERNEL_INTERNAL_SWIG_HELPERS_BASE_H
@@ -863,7 +863,7 @@ struct Convert<std::string> {
                                     argtype),
                   ValueException);
       }
-      std::string s(PyString_AsString(obj));
+      std::string s(PyBytes_AsString(obj));
       Py_DECREF(obj);
       return s;
     }
@@ -910,16 +910,13 @@ struct Convert<double> : public ConvertFloatBase {
   static const int converter = 12;
 };
 
-/* with swig 2.0.6 we seem to need both the Int and Long checks */
 template <>
 struct Convert<int> {
   static const int converter = 13;
   template <class SwigData>
   static int get_cpp_object(PyObject* o, const char *symname, int argnum,
                             const char *argtype, SwigData, SwigData, SwigData) {
-    if (PyInt_Check(o)) {
-      return PyInt_AsLong(o);
-    } else if (PyLong_Check(o)) {
+    if (PyLong_Check(o)) {
       return PyLong_AsLong(o);
     } else {
       long ret = PyLong_AsLong(o);
@@ -933,12 +930,12 @@ struct Convert<int> {
   }
   template <class SwigData>
   static bool get_is_cpp_object(PyObject* o, SwigData, SwigData, SwigData) {
-    return PyLong_Check(o) || PyInt_Check(o) || PyNumber_Check(o);
+    return PyLong_Check(o) || PyNumber_Check(o);
   }
   template <class SwigData>
   static PyObject* create_python_object(int f, SwigData, int) {
     // These may or may not have a ref count
-    return PyInt_FromLong(f);
+    return PyLong_FromLong(f);
   }
 };
 
diff --git a/modules/kernel/pyext/include/IMP_kernel.streams.i b/modules/kernel/pyext/include/IMP_kernel.streams.i
index 41d0e5fb32..64014e13c6 100644
--- a/modules/kernel/pyext/include/IMP_kernel.streams.i
+++ b/modules/kernel/pyext/include/IMP_kernel.streams.i
@@ -328,9 +328,9 @@ protected:
       // Python exception will be reraised when SWIG method finishes
       throw std::ostream::failure("Python error on read");
     } else {
-      if (PyString_Check(result)) {
-        if (PyString_Size(result) == 1) {
-          int c = peeked_ = (unsigned char)(PyString_AsString(result)[0]);
+      if (PyBytes_Check(result)) {
+        if (PyBytes_Size(result) == 1) {
+          int c = peeked_ = (unsigned char)(PyBytes_AsString(result)[0]);
           Py_DECREF(result);
           return c;
         } else {
@@ -352,9 +352,9 @@ protected:
     if (!result) {
       throw std::ostream::failure("Python error on read");
     } else {
-      if (PyString_Check(result)) {
-        int len = PyString_Size(result);
-        char *str = PyString_AsString(result);
+      if (PyBytes_Check(result)) {
+        int len = PyBytes_Size(result);
+        char *str = PyBytes_AsString(result);
         if (len > n) {
           Py_DECREF(result);
           PyErr_SetString(PyExc_IOError, "Python file-like object read method "
diff --git a/modules/kernel/pyext/include/IMP_kernel.types.i b/modules/kernel/pyext/include/IMP_kernel.types.i
index 47cd125a38..c3c082013b 100644
--- a/modules/kernel/pyext/include/IMP_kernel.types.i
+++ b/modules/kernel/pyext/include/IMP_kernel.types.i
@@ -33,7 +33,7 @@
    whether it's signed or not. So we override the default here and force the
    hash value into a signed type, so it will always fit into a Python 'int'. */
 %typemap(out) std::size_t __hash__ {
-  $result = PyInt_FromLong(static_cast<long>($1));
+  $result = PyLong_FromLong(static_cast<long>($1));
 }
 
 /* Add additional IMP_CONTAINER methods for scripting languages */
