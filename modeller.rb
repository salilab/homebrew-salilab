require "formula"

class Modeller < Formula
  desc "Homology or comparative modeling of protein structures"
  homepage "https://salilab.org/modeller/"
  url "https://salilab.org/modeller/10.5/modeller-10.5-mac.pax.gz" if OS.mac?
  sha256 "188fc3dac9fec39418b356dcf9d78203d17ee8578e03f9b95367e874639d5e6d" if OS.mac?
  url "https://salilab.org/modeller/10.5/modeller-10.5.tar.gz" if OS.linux?
  sha256 "acbee4481d79e669dd0251d5e075902dbe0a7dfeb13f8777c8d602cae64a28ad" if OS.linux?
  revision 2

  depends_on "patchelf" => :build if OS.linux?
  depends_on "pkg-config" => :build
  depends_on "swig" => :build
  depends_on "python-setuptools" => :build
  depends_on "gettext"
  depends_on "glib"
  depends_on "hdf5@1.10.7"
  depends_on "ifort-runtime" if Hardware::CPU.intel?
  depends_on "python@3.13" => :recommended

  # Python 3.13 support
  patch :DATA

  # otherwise python3 setup.py build cannot find pkg-config
  env :std

  def install
    dylib = "dylib" if OS.mac?
    dylib = "so" if OS.linux?
    modtop = "Library/modeller-#{version}" if OS.mac?
    if OS.linux?
      mv "bin/modscript", "bin/mod#{version}"
      modtop = "."
    end

    if Hardware::CPU.arm?
      exetype = "mac12arm64-gnu"
      univ_exetype = "mac10v4"
    else
      if `uname -m` == "x86_64\n"
        exetype = "mac10v4-intel64" if OS.mac?
        exetype = "x86_64-intel8" if OS.linux?
      else
        exetype = "mac10v4-intel"
      end
      univ_exetype = "mac10v4" if OS.mac?
      univ_exetype = "x86_64-intel8" if OS.linux?
    end

    pyver = Language::Python.major_minor_version "python"
    inreplace "#{modtop}/bin/mod#{version}" do |s|
      s.gsub! /^(MODINSTALL.*)=.*/, "\\1=#{prefix}"
      if OS.linux?
        s.gsub! /(EXECUTABLE_TYPE\w+)=.*;/, "\\1=#{exetype};"
        s.gsub! /ARCHBINDIR=bin/, "ARCHBINDIR=modbin"
      else
        s.gsub! /\/bin\/\$\{EXECUTABLE\}/, "/modbin/${EXECUTABLE}"
      end

      # Find _modeller.so in Python path
      s.gsub! /^# run the/, "export PYTHONPATH=#{lib}/python#{pyver}/site-packages\n\n#run the"
    end

    # Rename Modeller's 'bin' directory to 'modbin', since the contents are
    # (mostly) not binaries (and otherwise Homebrew will link them into
    # /usr/local/bin). Also, point DYNLIB to a different location (see below)
    inreplace "#{modtop}/modlib/libs.lib" do |s|
      s.gsub! /^(BIN_MODELLER.*)\/bin/, "\\1/modbin"
      s.gsub! /^(DYNLIB.*)\/lib/, "\\1/dynlib"
    end

    inreplace "#{modtop}/src/swig/setup.py" do |s|
      s.gsub! /^exetype =.*$/, "exetype = \"#{exetype}\""
      s.gsub! /\/lib\//, "/dynlib/"
    end

    sover = "13"

    bin.install "#{modtop}/bin/mod#{version}"
    (prefix/"modbin").install Dir["#{modtop}/bin/*"]
    if OS.mac?
      # Otherwise the Python 3 _modeller extension uses the
      # old location (in /Library)
      system "install_name_tool", "-id",
             lib/"libmodeller.#{sover}.dylib",
             "#{modtop}/lib/#{univ_exetype}/libmodeller.#{sover}.dylib"
      lib.install Dir["#{modtop}/lib/#{univ_exetype}/libmodeller.*dylib"]
      lib.install "#{modtop}/lib/#{univ_exetype}/libsaxs.dylib"
      if Hardware::CPU.arm?
        lib.install "#{modtop}/lib/#{univ_exetype}/libquadmath.0.dylib"
      end
      (prefix/"py2_compat").install "#{modtop}/py2_compat/Python"
      (prefix/"py2_compat").install "#{modtop}/py2_compat/site.py"
    elsif OS.linux?
      lib.install Dir["#{modtop}/lib/#{exetype}/libmodeller.so*"]
      lib.install "#{modtop}/lib/#{exetype}/libsaxs.so"
      lib.install "#{modtop}/lib/#{exetype}/libpython2.3.so.1.0"
    end
    doc.install "#{modtop}/ChangeLog"
    doc.install "#{modtop}/doc"
    doc.install "#{modtop}/examples"
    prefix.install "#{modtop}/modlib"
    prefix.install "#{modtop}/src"

    if OS.linux?
      ifort_libs = ["ifcore.so.5", "imf.so", "intlc.so.5", "svml.so"]
    elsif OS.mac?
      ifort_libs = ["ifcore.dylib", "imf.dylib", "intlc.dylib", "irc.dylib",
                    "svml.dylib"]
      modbins = [prefix/"modbin/mod#{version}_#{univ_exetype}",
                 "#{modtop}/lib/#{univ_exetype}/_modeller.so",
                 lib/"libmodeller.#{sover}.dylib",
                 lib/"libsaxs.dylib"]
      dprefix = "/#{modtop}/lib/mac10v4/"

      # Get only the native arch for Modeller dylibs to work around
      # Homebrew thinking we have broken dependencies (arm64 version links
      # to libquadmath; Intel version does not)
      if Hardware::CPU.arm?
        exargs = ["-extract", "arm64"]
      else
        exargs = ["-extract", "i386", "-extract", "x86_64"]
      end
      ["modeller.#{sover}", "saxs"].each do |l|
        system "lipo", *exargs, "-output", lib/"lib#{l}.dylib.new",
               lib/"lib#{l}.dylib"
        mv lib/"lib#{l}.dylib.new", lib/"lib#{l}.dylib"
      end

      modbins.each do |modbin|
        # Point Modeller binaries to Homebrew-installed HDF5
        hdf_libs = ["hdf5.103", "hdf5_hl.100"]
        hdf_libs.each do |dep|
          system "install_name_tool", "-change",
                 "#{dprefix}lib#{dep}.dylib",
                 Formula["hdf5@1.10.7"].lib/"lib#{dep}.dylib", modbin
        end

        # Point Modeller binaries to Homebrew-installed libintl
        system "install_name_tool", "-change",
               "#{dprefix}libintl.8.dylib",
               Formula["gettext"].lib/"libintl.8.dylib", modbin

        # Point Modeller binaries to Homebrew-installed glib2
        system "install_name_tool", "-change",
               "#{dprefix}libglib-2.0.0.dylib",
               Formula["glib"].lib/"libglib-2.0.0.dylib", modbin

        # Point Modeller binaries to Homebrew-installed ifort runtime libraries
        if Hardware::CPU.intel?
          ifort_libs.each do |dep|
            system "install_name_tool", "-change",
                   "/#{modtop}/lib/mac10v4/lib#{dep}",
                   Formula["ifort-runtime"].lib/"lib#{dep}", modbin
          end
        end

        libs = ["modeller.#{sover}", "saxs"]
        if Hardware::CPU.arm?
          libs << "quadmath.0"
        end
        libs.each do |dep|
          system "install_name_tool", "-change",
                 "#{dprefix}lib#{dep}.dylib",
                 lib/"lib#{dep}.dylib", modbin
        end
      end

      # Make py2_compat binary that pulls in bundled Python
      cp prefix/"modbin/mod#{version}_#{univ_exetype}",
         prefix/"py2_compat/mod#{version}_#{univ_exetype}"
      system "install_name_tool", "-change",
             "/System/Library/Frameworks/Python.framework/Versions/2.6/Python",
             prefix/"py2_compat/Python",
             prefix/"py2_compat/mod#{version}_#{univ_exetype}"
      system "install_name_tool", "-change",
             "/System/Library/Frameworks/Python.framework/Versions/2.7/Python",
             prefix/"py2_compat/Python",
             prefix/"py2_compat/mod#{version}_#{univ_exetype}"

      # install_name_tool invalidates signatures, so resign
      # cp && mv is needed to work around a MacOS bug:
      # "the codesign_allocate helper tool cannot be found or used"
      if Hardware::CPU.arm?
        modbins.each do |modbin|
          cp modbin, "#{modbin}.new"
          mv "#{modbin}.new", modbin
          system "codesign", "-f", "-s", "-", modbin
        end
        modbin = prefix/"py2_compat/mod#{version}_#{univ_exetype}"
        cp modbin, "#{modbin}.new"
        mv "#{modbin}.new", modbin
        system "codesign", "-f", "-s", "-", modbin
      end
    end

    File.open("#{prefix}/modlib/modeller/config.py", "w") do |file|
      file.puts "install_dir = r'#{prefix}'"
      file.puts "license = r'XXXX'"
    end

    # Make dynlib directory and symlinks so modXXX --libs works
    Dir.mkdir("#{prefix}/dynlib")
    if OS.mac?
      if Hardware::CPU.arm?
        File.symlink(".", "#{prefix}/dynlib/mac12arm64-gnu")
      else
        ["mac10v4-intel64", "mac10v4-intel"].each do |arch|
          File.symlink(".", "#{prefix}/dynlib/#{arch}")
        end
      end
    elsif OS.linux?
      File.symlink(".", "#{prefix}/dynlib/x86_64-intel8")
    end
    File.open("#{prefix}/dynlib/README", "w") do |file|
      file.puts %Q("mod#{version} --libs" outputs a single directory containing the Modeller
libraries and its HDF5 and Fortran runtime dependencies. Since the Homebrew
package moves things around a little, the regular lib/ directory isn't
suitable for this purpose. This directory contains symlinks to the necessary
libraries.
)
    end
    ["modeller", "saxs"].each do |l|
      File.symlink("../lib/lib#{l}.#{dylib}",
                   "#{prefix}/dynlib/lib#{l}.#{dylib}")
    end
    if Hardware::CPU.intel?
      ifort_libs.each do |l|
        File.symlink(Formula["ifort-runtime"].lib/"lib#{l}",
                     "#{prefix}/dynlib/lib#{l}")
      end
    end
    ["hdf5", "hdf5_hl"].each do |l|
      File.symlink(Formula["hdf5@1.10.7"].lib/"lib#{l}.#{dylib}",
                   "#{prefix}/dynlib/lib#{l}.#{dylib}")
    end

    if build.with? "python@3.13"
      pyver = Language::Python.major_minor_version Formula["python@3.13"].opt_bin/"python3.13"
      File.open("modeller.pth", "w") do |file|
        file.puts "#{prefix}/modlib"
      end
      (lib/"python#{pyver}/site-packages").install "modeller.pth"
    end

    pyver = Language::Python.major_minor_version "python2"
    if OS.mac?
      (lib/"python#{pyver}/site-packages").install "#{modtop}/lib/#{univ_exetype}/_modeller.so"
    elsif OS.linux?
      # Most likely we are using the Python 2.5 ABI, not 2.3
      (lib/"python#{pyver}/site-packages").install "#{modtop}/lib/#{univ_exetype}/python2.5/_modeller.so"
    end

    File.symlink("#{prefix}/modlib/modeller",
                 lib/"python#{pyver}/site-packages/modeller")

    if OS.linux?
      modbins = [prefix/"modbin/mod#{version}_#{exetype}",
                 "#{modtop}/lib/#{exetype}/_modeller.so",
                 lib/"libmodeller.so.#{sover}",
                 lib/"libsaxs.so",
                 lib/"python#{pyver}/site-packages/_modeller.so"]
      lib1 = Formula["hdf5@1.10.7"].lib
      lib2 = Formula["ifort-runtime"].lib
      modbins.each do |modbin|
        system "patchelf", "--set-rpath", "#{lib1}:#{lib2}:#{HOMEBREW_PREFIX}/lib", modbin
      end
    end

    # Build Python 3.13 extension from SWIG inputs
    if build.with? "python@3.13"
      pyver = Language::Python.major_minor_version Formula["python@3.13"].opt_bin/"python3.13"
      Dir.chdir("#{prefix}/src/swig/") do
        system "swig", "-python", "-keyword", "-nodefaultctor",
               "-nodefaultdtor", "-noproxy", "modeller.i"
        # Avoid possible confusion between Python 2 and Python 3 site modules
        ENV.delete("PYTHONPATH")
        system Formula["python@3.13"].opt_bin/"python3.13", "setup.py", "build"
        (lib/"python#{pyver}/site-packages").install Dir["build/lib.*/_modeller.*so"]
        File.delete("modeller_wrap.c")
        rm_rf("build")
      end
    end

    # Add pkg-config support
    Dir.mkdir(lib/"pkgconfig")
    if OS.mac?
      if Hardware::CPU.intel?
        pkgconfig_extras = " -lhdf5 -lhdf5_hl -lsaxs -limf -lsvml -lifcore -lirc"
      else
        pkgconfig_extras = " -lhdf5 -lhdf5_hl -lsaxs"
      end
    else
      pkgconfig_extras = " -Wl,-rpath-link,#{prefix}/dylib/#{exetype}"
    end
    File.open(lib/"pkgconfig/modeller.pc", "w") do |file|
      file.puts %Q(prefix=/usr
exec_prefix=/usr

Name: Modeller
Description: Comparative modeling by satisfaction of spatial restraints
Version: #{version}
Libs: -L#{prefix}/dynlib/#{exetype} -lmodeller#{pkgconfig_extras}
Cflags: -I#{prefix}/src/include -I#{prefix}/src/include/#{exetype}
)
    end
  end

  def post_install
    if FileTest.exist?("#{etc}/modeller/license")
      lines = File.readlines("#{etc}/modeller/license")
      if lines.size >= 1
        inreplace "#{prefix}/modlib/modeller/config.py" do |s|
          s.gsub! /XXXX/, lines[0].chomp
        end
      end
    end
  end

  def caveats
    unless FileTest.exist?("#{etc}/modeller/license")
      <<~EOS
        Edit #{prefix}/modlib/modeller/config.py
        and replace XXXX with your Modeller license key
        (or write your license key into #{etc}/modeller/license before
        running "brew install").
      EOS
    end
  end

  test do
    Language::Python.each_python(build) do |python, _version|
      system python, "-c", "import modeller"
    end
    system "mod#{version}", "--cflags", "--libs"
  end
end

__END__
--- a/Library/modeller-10.5/src/swig/helperfuncs/python-callbacks.i
+++ b/Library/modeller-10.5/src/swig/helperfuncs/python-callbacks.i
@@ -13,7 +13,7 @@
   if (!(arglist = Py_BuildValue("()"))) {
     return 1;
   }
-  result = PyEval_CallObject(func, arglist);
+  result = PyObject_Call(func, arglist, NULL);
   Py_DECREF(arglist);
   if (result && PyBool_Check(result)) {
     *out1 = PyInt_AsLong(result);
@@ -42,7 +42,7 @@
   if (!arglist) {
     return 1;
   }
-  result = PyEval_CallObject(func, arglist);
+  result = PyObject_Call(func, arglist, NULL);
   Py_DECREF(arglist);
   if (result && PyNumber_Check(result)) {
     *out1 = PyFloat_AsDouble(result);
@@ -72,7 +72,7 @@
   if (!arglist) {
     return 1;
   }
-  result = PyEval_CallObject(func, arglist);
+  result = PyObject_Call(func, arglist, NULL);
   Py_DECREF(arglist);
   if (result && PySequence_Check(result) && PySequence_Size(result) == 3) {
     PyObject *o1, *o2, *o3;
@@ -116,7 +116,7 @@
   if (!arglist) {
     return 1;
   }
-  result = PyEval_CallObject(func, arglist);
+  result = PyObject_Call(func, arglist, NULL);
   Py_DECREF(arglist);
   if (result && deriv && PySequence_Check(result)
       && PySequence_Size(result) == 4) {
@@ -174,7 +174,7 @@
   if (!arglist) {
     return 1;
   }
-  result = PyEval_CallObject(func, arglist);
+  result = PyObject_Call(func, arglist, NULL);
   Py_DECREF(arglist);
   if (result && PyFloat_Check(result)) {
     *val = PyFloat_AsDouble(result);
@@ -212,7 +212,7 @@
   if (!arglist) {
     return 1;
   }
-  result = PyEval_CallObject(func, arglist);
+  result = PyObject_Call(func, arglist, NULL);
   Py_DECREF(arglist);
   if (result && deriv && PySequence_Check(result)
       && PySequence_Size(result) == 2) {
@@ -261,7 +261,7 @@
   if (!arglist) {
     return 1;
   }
-  result = PyEval_CallObject(func, arglist);
+  result = PyObject_Call(func, arglist, NULL);
   Py_DECREF(arglist);
 
   if (result && PySequence_Check(result) && PySequence_Size(result) == 2) {
@@ -310,7 +310,7 @@
   if (!arglist) {
     return 1;
   }
-  result = PyEval_CallObject(func, arglist);
+  result = PyObject_Call(func, arglist, NULL);
   Py_DECREF(arglist);
   if (result && PyNumber_Check(result)) {
     *val = PyFloat_AsDouble(result);
@@ -346,7 +346,7 @@
   if (!arglist) {
     return 1;
   }
-  result = PyEval_CallObject(func, arglist);
+  result = PyObject_Call(func, arglist, NULL);
   Py_DECREF(arglist);
   if (result) {
     int ret = !python_to_float_array(result, n_feat, NULL, val, "val");
@@ -366,7 +366,7 @@
   if (!(arglist = Py_BuildValue("(O)", optobj))) {
     return 1;
   }
-  result = PyEval_CallObject(func, arglist);
+  result = PyObject_Call(func, arglist, NULL);
   Py_DECREF(arglist);
   if (result && result != Py_None) {
     PyErr_SetString(PyExc_ValueError,
@@ -390,7 +390,7 @@
   if (!arglist) {
     return 1;
   }
-  result = PyEval_CallObject(func, arglist);
+  result = PyObject_Call(func, arglist, NULL);
   Py_DECREF(arglist);
   if (result && result != Py_None) {
     PyErr_SetString(PyExc_ValueError,
