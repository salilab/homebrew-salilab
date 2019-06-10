require 'formula'

class Imp < Formula
  desc "The Integrative Modeling Platform"
  homepage 'https://integrativemodeling.org/'
  url 'https://integrativemodeling.org/2.10.1/download/imp-2.10.1.tar.gz'
  sha256 '53a99ae24c3c2bdabfcfa04a94df42b5f034ef689284351034bc82105daea5ec'
  revision 6

  # Add support for SWIG 4
  patch :DATA

  bottle do
    root_url "https://dl.bintray.com/salilab/homebrew"
    sha256 "18ef638f277618b81f2e14747aee75a1d239315623327790ba5632697a94f950" => :sierra
    sha256 "8f7f7b0b63c0e824d16e01cd8277ce2407470a73507447d509f71bd7b9641cfa" => :high_sierra
   sha256 "38c146df609ce56dd8b3e2d239a2f715157fcfaaeca3f31aa8fe31eac6c53dbf" => :mojave
  end

  depends_on 'cmake' => :build
  depends_on 'swig' => :build

  depends_on 'python@2' => :recommended
  depends_on 'python' => :recommended

  depends_on 'boost'
  depends_on 'hdf5'
  depends_on 'fftw'
  depends_on 'eigen'
  depends_on 'protobuf'
  depends_on 'open-mpi'
  depends_on 'libtau' => :recommended
  depends_on 'cgal' => :recommended
  depends_on 'gsl' => :recommended
  depends_on 'opencv' => :recommended

  def install
    ENV.cxx11
    pyver = Language::Python.major_minor_version "python2.7"
    args = std_cmake_args
    args << "-DIMP_DISABLED_MODULES=scratch"
    args << ".."
    # Don't install in lib64 on Linux systems
    args << "-DCMAKE_INSTALL_LIBDIR=#{lib}"
    args << "-DCMAKE_INSTALL_PYTHONDIR=#{lib}/python#{pyver}/site-packages"
    # Don't link against gperftools, even if they were found, since then the
    # bottle won't work on systems without gperftools installed
    args << "-DGPerfTools_found=0"
    # Help cmake to find CGAL
    ENV["CGAL_DIR"] = Formula["cgal"].lib/"cmake/CGAL"
    mkdir "build" do
      system "cmake", *args
      pybins = []
      cd "bin" do
        pybins = Dir.glob("*")
      end
      system "make"
      system "make", "install"
      cd bin do
        # Make sure binaries use Homebrew Python, not some other Python in PATH
        inreplace pybins, %r{^#!.*python.*$},
                          "#!#{Formula["python@2"].opt_bin}/python2"
      end
      if build.with? 'python'
        version = Language::Python.major_minor_version "python3"
        python_framework = (Formula["python"].opt_prefix)/"Frameworks/Python.framework/Versions/#{version}"
        py3_lib = "#{python_framework}/lib/libpython#{version}.dylib"
        py3_inc = "#{python_framework}/Headers"
        args = ["..",
                "-DCMAKE_INSTALL_PYTHONDIR=#{lib}/python#{version}/site-packages",
                "-DSWIG_PYTHON_LIBRARIES=#{py3_lib}",
                "-DPYTHON_LIBRARIES=#{py3_lib}",
                "-DPYTHON_INCLUDE_DIRS=#{py3_inc}",
                "-DPYTHON_INCLUDE_PATH=#{py3_inc}"]
        system "cmake", *args
        system "make", "install"
        cd bin do
          # Make sure binaries use Homebrew Python
          inreplace pybins, %r{^#!.*python.*$},
                            "#!#{Formula["python"].opt_bin}/python3"
        end
      end
    end
  end

  test do
    Language::Python.each_python(build) do |python, pyver|
      system python, "-c", "import IMP; assert(IMP.__version__ == '#{version}')"
      system python, "-c", "import IMP.em2d; assert(IMP.em2d.__version__ == '#{version}')"
      system python, "-c", "import IMP.cgal; assert(IMP.cgal.__version__ == '#{version}')"
      system python, "-c", "import IMP.foxs; assert(IMP.foxs.__version__ == '#{version}')"
      system python, "-c", "import IMP.multifit; assert(IMP.multifit.__version__ == '#{version}')"
      system python, "-c", "import IMP.npctransport; assert(IMP.npctransport.__version__ == '#{version}')"
      system python, "-c", "import IMP, RMF, os; name = IMP.create_temporary_file_name('assignments', '.hdf5'); root = RMF.HDF5.create_file(name); del root; os.unlink(name)"
      system python, "-c", "import IMP.mpi; assert(IMP.mpi.__version__ == '#{version}')"
    end
    system "multifit"
    system "foxs"
  end

end

__END__
diff --git a/modules/atom/pyext/swig.i-in b/modules/atom/pyext/swig.i-in
index f9f1c50fdd..383c783dff 100644
--- a/modules/atom/pyext/swig.i-in
+++ b/modules/atom/pyext/swig.i-in
@@ -295,9 +295,17 @@ namespace IMP {
 %include "IMP/atom/HelixRestraint.h"
 %include "IMP/atom/alignment.h"
 
+%inline %{
+  // SWIG 4.0 doesn't like %template here, so provide a little
+  // wrapper function instead
+  std::ostream &show_molecular_hierarchy(
+              IMP::atom::Hierarchy h, std::ostream &out = std::cout) {
+    return IMP::core::show<IMP::atom::Hierarchy>(h, out);
+  }
+%}
+
 namespace IMP {
   namespace atom {
-   %template(show_molecular_hierarchy) IMP::core::show<IMP::atom::Hierarchy>;
    %template(CHARMMBond) CHARMMConnection<2>;
    %template(CHARMMAngle) CHARMMConnection<3>;
    %template(_get_native_overlap_cpp) get_native_overlap<IMP::Vector<algebra::VectorD<3> >, IMP::Vector<algebra::VectorD<3> > >;
diff --git a/tools/build/setup_swig_deps.py b/tools/build/setup_swig_deps.py
index b776be9988..77cdfe5ec2 100755
--- a/tools/build/setup_swig_deps.py
+++ b/tools/build/setup_swig_deps.py
@@ -47,7 +47,7 @@ def setup_one(module, ordered, build_system, swig):
     swigpath = get_dep_merged([module], "swigpath", ordered)
 
     depf = open("src/%s_swig.deps.in" % module, "w")
-    cmd = [swig, "-MM", "-Iinclude", "-Iswig", "-ignoremissing"]\
+    cmd = [swig, "-python", "-MM", "-Iinclude", "-Iswig", "-ignoremissing"]\
         + ["-I" + x for x in swigpath] + ["-I" + x for x in includepath]\
         + ["swig/IMP_%s.i" % module]
 
diff --git a/tools/build/setup_swig_wrappers.py b/tools/build/setup_swig_wrappers.py
index 2b67d1f998..83f591587c 100755
--- a/tools/build/setup_swig_wrappers.py
+++ b/tools/build/setup_swig_wrappers.py
@@ -49,7 +49,8 @@ def build_wrapper(module, module_path, source, sorted, info, target, datapath):
     contents = []
     swig_module_name = "IMP" if module == 'kernel' else "IMP." + module
 
-    contents.append("""%%module(directors="1", allprotected="1") "%s"
+    contents.append(
+"""%%module(directors="1", allprotected="1", moduleimport="import $module") "%s"
 %%feature("autodoc", 1);
 // Warning 314: 'lambda' is a python keyword, renaming to '_lambda'
 %%warnfilter(321,302,314);
