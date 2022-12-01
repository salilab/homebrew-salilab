require "formula"

class Imp < Formula
  desc "Integrative Modeling Platform"
  homepage "https://integrativemodeling.org/"
  url "https://integrativemodeling.org/2.17.0/download/imp-2.17.0.tar.gz"
  sha256 "2667f7a4f7b4830ba27e0d41e2cab0fc21ca22176625bfd8b2f353b283dfc8af"
  license "LGPL/GPL"
  revision 6

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
  end

  depends_on "cmake" => :build
  depends_on "pkg-config" => :build
  depends_on "swig" => :build

  depends_on "boost"
  depends_on "rmf"
  depends_on "ihm"
  depends_on "eigen"
  depends_on "fftw"
  depends_on "hdf5"
  depends_on "open-mpi"
  depends_on "protobuf"
  depends_on "python@3.10"
  depends_on "cgal" => :recommended
  depends_on "gsl" => :recommended
  depends_on "libtau" => :recommended
  depends_on "opencv" => :recommended

  # Fix build with newer CGAL
  patch do
    url "https://github.com/salilab/imp/commit/c1522b37fb8bcf53c1d9738e30519a0a5c2b0831.patch?full_index=1"
    sha256 "6b5bc748a393b006dcd76bda02163d5b80b573cfb07a944d50bb49ef7dc8851f"
  end
  patch do
    url "https://github.com/salilab/imp/commit/806d3f182b4e8f23420f5cc6687a48836099b0c7.patch?full_index=1"
    sha256 "c10fc7b3913725f7123cbdbd14eec57a4126e11aaf0a5e53f541e02ad36937cf"
  end

  # Fix build with SWIG 4.1
  patch :DATA

  def install
    ENV.cxx11
    pybin = Formula["python@3.10"].opt_bin/"python3.10"
    pyver = Language::Python.major_minor_version pybin
    args = std_cmake_args
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
    # Force Python 3
    args << "-DUSE_PYTHON2=off"
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
    pythons = [Formula["python@3.10"].opt_bin/"python3.10"]
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
      system python, "-c", "import IMP.mpi; assert(IMP.mpi.__version__ == '#{version}')"
    end
    system "multifit"
    system "foxs"
  end
end

__END__
diff --git a/modules/npctransport/include/ParticleTransportStatisticsOptimizerState.h b/modules/npctransport/include/ParticleTransportStatisticsOptimizerState.h
index f02476df0cd5b7daec3027ff9b21c5b48478cf87..f46c88d71b5e948483fcfde7e4ce9b701bc5ce5b 100644
--- a/modules/npctransport/include/ParticleTransportStatisticsOptimizerState.h
+++ b/modules/npctransport/include/ParticleTransportStatisticsOptimizerState.h
@@ -72,7 +72,12 @@ class IMPNPCTRANSPORTEXPORT ParticleTransportStatisticsOptimizerState
   //! returns the simulator that was declared in the constructor or by
   //set_owner()
   //! to moves this particle, and provide simulation time information about it.
+#ifdef SWIG
+  // Help out SWIG 4.1, which gets confused by the WeakPointer here
+  IMP::atom::Simulator* get_owner() const { return owner_; }
+#else
   WeakPointer<IMP::atom::Simulator> get_owner() const { return owner_; }
+#endif
 
   /**
       Returns the number of times the particle crossed the channel
