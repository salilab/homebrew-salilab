require "formula"

class Modeller < Formula
  desc "Homology or comparative modeling of protein structures"
  homepage "https://salilab.org/modeller/"
  url "https://salilab.org/modeller/10.0/modeller-10.0-mac-as.pax.gz" if OS.mac?
  sha256 "b8ca3019d771edf34e1d0fe0f5abf4553f0d130680f19ebb19923cc87a51df22" if OS.mac?
  url "https://salilab.org/modeller/10.0/modeller-10.0.tar.gz" if OS.linux?
  sha256 "2629a11dd07968d005c307e47496fb8fe6516d2f715ccaab1813f66dabaa0674" if OS.linux?
  revision 2

  depends_on "patchelf" => :build if OS.linux?
  depends_on "pkg-config" => :build
  depends_on "swig" => :build
  depends_on "gettext"
  depends_on "glib"
  depends_on "hdf5@1.10.6"
  depends_on "ifort-runtime" if Hardware::CPU.intel?
  depends_on "python@3.9" => :recommended

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
      exetype = "mac11arm64-gnu"
      univ_exetype = exetype
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
        if Hardware::CPU.arm?
          s.gsub! /(EXECUTABLE_TYPE\w*)=.*/, "\\1=#{exetype}"
        end
        s.gsub! /\/bin\/\$\{EXECUTABLE\}/, "/modbin/${EXECUTABLE}"
      end

      # Find _modeller.so in Python path
      s.gsub! /^exec/, "export PYTHONPATH=#{lib}/python#{pyver}/site-packages\nexec"
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

    bin.install "#{modtop}/bin/mod#{version}"
    (prefix/"modbin").install Dir["#{modtop}/bin/*"]
    if OS.mac?
      lib.install Dir["#{modtop}/lib/#{univ_exetype}/libmodeller.*dylib"]
      lib.install "#{modtop}/lib/#{univ_exetype}/libsaxs.dylib"
      # Delete non-native architecture
      if Hardware::CPU.arm?
        rm "#{prefix}/modbin/mod#{version}_mac10v4"
      else
        rm "#{prefix}/modbin/mod#{version}_mac11arm64-gnu"
      end
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

    sover = "13"
    if OS.linux?
      ifort_libs = ["ifcore.so.5", "imf.so", "intlc.so.5", "svml.so"]
    elsif OS.mac?
      ifort_libs = ["ifcore.dylib", "imf.dylib", "intlc.dylib", "irc.dylib",
                    "svml.dylib"]
      modbins = [prefix/"modbin/mod#{version}_#{univ_exetype}",
                 "#{modtop}/lib/#{univ_exetype}/_modeller.so",
                 lib/"libmodeller.#{sover}.dylib",
                 lib/"libsaxs.dylib"]
      # Our ARM dylibs have the loader path completely stripped or
      # set to @loader_path;
      # on Intel the path is set under /Library/modeller-xxx/
      if Hardware::CPU.arm?
        dprefix = ""
      else
        dprefix = "/#{modtop}/lib/mac10v4/"
      end

      modbins.each do |modbin|
        # Point Modeller binaries to Homebrew-installed HDF5
        hdf_libs = ["hdf5.103", "hdf5_hl.100"]
        hdf_libs.each do |dep|
          system "install_name_tool", "-change",
                 "#{dprefix}lib#{dep}.dylib",
                 Formula["hdf5@1.10.6"].lib/"lib#{dep}.dylib", modbin
          if Hardware::CPU.arm?
            system "install_name_tool", "-change",
                   "@loader_path/lib#{dep}.dylib",
                   Formula["hdf5@1.10.6"].lib/"lib#{dep}.dylib", modbin
          end
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
        libs.each do |dep|
          system "install_name_tool", "-change",
                 "#{dprefix}lib#{dep}.dylib",
                 lib/"lib#{dep}.dylib", modbin
          if Hardware::CPU.arm?
            system "install_name_tool", "-change",
                   "@loader_path/lib#{dep}.dylib",
                   lib/"lib#{dep}.dylib", modbin
          end
        end
      end

      # install_name_tool invalidates signatures, so resign
      # cp && mv is needed to work around a MacOS bug:
      # "the codesign_allocate helper tool cannot be found or used"
      if Hardware::CPU.arm?
        modbins.each do |modbin|
          cp modbin, "#{modbin}.new"
          mv "#{modbin}.new", modbin
          system "codesign", "-f", "-s", "-", modbin
        end
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
        File.symlink(".", "#{prefix}/dynlib/mac11arm64-gnu")
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
      File.symlink(Formula["hdf5@1.10.6"].lib/"lib#{l}.#{dylib}",
                   "#{prefix}/dynlib/lib#{l}.#{dylib}")
    end

    if build.with? "python@3.9"
      pyver = Language::Python.major_minor_version Formula["python@3.9"].opt_bin/"python3"
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
      lib1 = Formula["hdf5@1.10.6"].lib
      lib2 = Formula["ifort-runtime"].lib
      modbins.each do |modbin|
        system "patchelf", "--set-rpath", "#{lib1}:#{lib2}:#{HOMEBREW_PREFIX}/lib", modbin
      end
    end

    # Build Python 3.9 extension from SWIG inputs
    if build.with? "python@3.9"
      pyver = Language::Python.major_minor_version Formula["python@3.9"].opt_bin/"python3"
      Dir.chdir("#{prefix}/src/swig/") do
        system "swig", "-python", "-keyword", "-nodefaultctor",
               "-nodefaultdtor", "-noproxy", "modeller.i"
        # Avoid possible confusion between Python 2 and Python 3 site modules
        ENV.delete("PYTHONPATH")
        system Formula["python@3.9"].opt_bin/"python3", "setup.py", "build"
        (lib/"python#{pyver}/site-packages").install Dir["build/lib.*#{pyver}/_modeller.*so"]
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
    if ENV["KEY_MODELLER"] != nil
      inreplace "#{prefix}/modlib/modeller/config.py" do |s|
        s.gsub! /XXXX/, ENV["KEY_MODELLER"]
      end
    end
  end

  def caveats
    if ENV["KEY_MODELLER"] == nil
      <<~EOS
        Edit #{prefix}/modlib/modeller/config.py
        and replace XXXX with your Modeller license key
        (or set the KEY_MODELLER environment variable before running "brew install").
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
