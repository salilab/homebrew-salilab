require 'formula'

class Modeller < Formula
  desc "Homology or comparative modeling of protein structures"
  homepage 'http://salilab.org/modeller/'
  url 'http://salilab.org/modeller/9.16/modeller-9.16-mac.pax.gz'
  sha256 'f75c274abde04fe6d558cb92fc5637df8a740f80ed7c545f628b9ff92bbda3aa'

  depends_on :python => :recommended
  depends_on :python3 => :optional

  depends_on 'swig' => :build
  depends_on 'hdf5-1814'
  depends_on 'glib'
  depends_on 'gettext'
  depends_on 'ifort-runtime'

  # otherwise python3 setup.py build cannot find pkg-config
  env :std

  def install
    modtop = "Library/modeller-#{version}"
    pyver = Language::Python.major_minor_version "python"
    inreplace "#{modtop}/bin/mod#{version}" do |s|
      s.gsub! /^(MODINSTALL.*)=.*/, "\\1=#{prefix}"
      s.gsub! /\/bin\/\$\{EXECUTABLE\}/, "/modbin/${EXECUTABLE}"
      # Find _modeller.so
      s.gsub! /^exec/, "export PYTHONPATH=#{lib}/python#{pyver}/site-packages\nexec"
    end

    # Rename Modeller's 'bin' directory to 'modbin', since the contents are
    # (mostly) not binaries (and otherwise Homebrew will link them into
    # /usr/local/bin). Also, point DYNLIB to a different location (see below)
    inreplace "#{modtop}/modlib/libs.lib" do |s|
      s.gsub! /^(BIN_MODELLER.*)\/bin/, "\\1/modbin"
      s.gsub! /^(DYNLIB.*)\/lib/, "\\1/dynlib"
    end

    if `uname -m` == "x86_64\n"
      exetype = "mac10v4-intel64"
    else
      exetype = "mac10v4-intel"
    end

    inreplace "#{modtop}/src/swig/setup.py" do |s|
      s.gsub! /^exetype =.*$/, "exetype = \"#{exetype}\""
      s.gsub! /\/lib\//, "/dynlib/"
    end

    bin.install "#{modtop}/bin/mod#{version}"
    (prefix/"modbin").install Dir["#{modtop}/bin/*"]
    lib.install Dir["#{modtop}/lib/mac10v4/libmodeller.*dylib"]
    lib.install "#{modtop}/lib/mac10v4/libsaxs.dylib"
    doc.install "#{modtop}/ChangeLog"
    doc.install "#{modtop}/doc"
    doc.install "#{modtop}/examples"
    prefix.install "#{modtop}/modlib"
    prefix.install "#{modtop}/src"

    sover = "11"
    ifort_libs = ["ifcore", "imf", "intlc", "irc", "svml"]
    modbins = [prefix/"modbin/mod#{version}_mac10v4",
               "#{modtop}/lib/mac10v4/_modeller.so",
               lib/"libmodeller.#{sover}.dylib",
               lib/"libsaxs.dylib"]

    modbins.each do |modbin|
      # Point Modeller binaries to Homebrew-installed HDF5
      libs = ["hdf5.9", "hdf5_hl.9"]
      libs.each do |dep|
        system "install_name_tool", "-change",
               "/#{modtop}/lib/mac10v4/lib#{dep}.dylib",
               Formula["hdf5-1814"].lib/"lib#{dep}.dylib", modbin
      end

      # Point Modeller binaries to Homebrew-installed libintl
      system "install_name_tool", "-change",
             "/#{modtop}/lib/mac10v4/libintl.8.dylib",
             Formula["gettext"].lib/"libintl.8.dylib", modbin

      # Point Modeller binaries to Homebrew-installed glib2
      system "install_name_tool", "-change",
             "/#{modtop}/lib/mac10v4/libglib-2.0.0.dylib",
             Formula["glib"].lib/"libglib-2.0.0.dylib", modbin

      # Point Modeller binaries to Homebrew-installed ifort runtime libraries
      ifort_libs.each do |dep|
        system "install_name_tool", "-change",
               "/#{modtop}/lib/mac10v4/lib#{dep}.dylib",
               Formula["ifort-runtime"].lib/"lib#{dep}.dylib", modbin
      end

      libs = ["modeller.#{sover}", "saxs"]
      libs.each do |dep|
        system "install_name_tool", "-change",
               "/#{modtop}/lib/mac10v4/lib#{dep}.dylib",
               lib/"lib#{dep}.dylib", modbin
      end
    end

    File.open("#{prefix}/modlib/modeller/config.py", 'w') do |file|
      file.puts "install_dir = r'#{prefix}'"
      file.puts "license = r'XXXX'"
    end

    # Make dynlib directory and symlinks so modXXX --libs works
    Dir.mkdir("#{prefix}/dynlib")
    ["mac10v4-intel64", "mac10v4-intel"].each do |arch|
      File.symlink('.', "#{prefix}/dynlib/#{arch}")
    end
    File.open("#{prefix}/dynlib/README", 'w') do |file|
      file.puts %Q("mod#{version} --libs" outputs a single directory containing the Modeller
libraries and its HDF5 and Fortran runtime dependencies. Since the Homebrew
package moves things around a little, the regular lib/ directory isn't
suitable for this purpose. This directory contains symlinks to the necessary
libraries.
)
    end
    ["modeller", "saxs"].each do |l|
      File.symlink("../lib/lib#{l}.dylib", "#{prefix}/dynlib/lib#{l}.dylib")
    end
    ifort_libs.each do |l|
      File.symlink(Formula["ifort-runtime"].lib/"lib#{l}.dylib",
                   "#{prefix}/dynlib/lib#{l}.dylib")
    end
    ["hdf5", "hdf5_hl"].each do |l|
      File.symlink(Formula["hdf5-1814"].lib/"lib#{l}.dylib",
                   "#{prefix}/dynlib/lib#{l}.dylib")
    end

    Language::Python.each_python(build) do |python, version|
      File.open('modeller.pth', 'w') do |file|
        file.puts "#{prefix}/modlib"
      end
      (lib/"python#{version}/site-packages").install "modeller.pth"
    end

    pyver = Language::Python.major_minor_version "python"
    (lib/"python#{pyver}/site-packages").install "#{modtop}/lib/mac10v4/_modeller.so"

    # Build Python 3 extension from SWIG inputs (todo: make universal)
    if build.with? 'python3'
      pyver = Language::Python.major_minor_version "python3"
      Dir.chdir("#{prefix}/src/swig/") do
        system "swig", "-python", "-keyword", "-nodefaultctor",
               "-nodefaultdtor", "-noproxy", "modeller.i"
        # Avoid possible confusion between Python 2 and Python 3 site modules
        ENV.delete("PYTHONPATH")
        system "python3", "setup.py", "build"
        (lib/"python#{pyver}/site-packages").install Dir["build/lib.*#{pyver}/_modeller.*so"]
        File.delete("modeller_wrap.c")
        FileUtils.rm_rf("build")
      end
    end

    # Add pkg-config support
    Dir.mkdir(lib/"pkgconfig")
    File.open(lib/"pkgconfig/modeller.pc", 'w') do |file|
      file.puts %Q(prefix=/usr
exec_prefix=/usr

Name: Modeller
Description: Comparative modeling by satisfaction of spatial restraints
Version: #{version}
Libs: -L#{prefix}/dynlib/#{exetype} -lmodeller -lhdf5 -lhdf5_hl -lsaxs -limf -lsvml -lifcore -lirc
Cflags: -I#{prefix}/src/include -I#{prefix}/src/include/#{exetype}
)
    end

  end

  def post_install
    if ENV['KEY_MODELLER'] != nil
      inreplace "#{prefix}/modlib/modeller/config.py" do |s|
        s.gsub! /XXXX/, ENV['KEY_MODELLER']
      end
    end
  end

  def caveats
    if ENV['KEY_MODELLER'] == nil
      <<-EOS.undent
      Edit #{prefix}/modlib/modeller/config.py
      and replace XXXX with your Modeller license key
      (or set the KEY_MODELLER environment variable before running 'brew install').
      EOS
    end
  end

  test do
    Language::Python.each_python(build) do |python, version|
      system python, "-c", "import modeller"
    end
  end

end
