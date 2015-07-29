require 'formula'

class Modeller < Formula
  homepage 'http://salilab.org/modeller/'
  url 'http://salilab.org/modeller/9.15/modeller-9.15-mac.pax.gz'
  sha1 '046492cbd7894100d2a55efaca98db9a74e73142'

  depends_on 'hdf5-1813'
  depends_on 'glib'
  depends_on 'gettext'
  depends_on 'ifort-runtime'

  def install
    modtop = "Library/modeller-#{version}"
    inreplace "#{modtop}/bin/mod#{version}" do |s|
      s.gsub! /^(MODINSTALL.*)=.*/, "\\1=#{prefix}"
      s.gsub! /\/bin\/\$\{EXECUTABLE\}/, "/modbin/${EXECUTABLE}"
    end

    inreplace "#{modtop}/modlib/libs.lib" do |s|
      s.gsub! /^(BIN_MODELLER.*)\/bin/, "\\1/modbin"
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

    sover = "10"
    modbins = [prefix/"modbin/mod#{version}_mac10v4",
               "#{modtop}/lib/mac10v4/_modeller.so",
               lib/"libmodeller.#{sover}.dylib",
               lib/"libsaxs.dylib"]

    modbins.each do |modbin|
      libs = ["hdf5.8", "hdf5_hl.8"]
      libs.each do |dep|
        system "install_name_tool", "-change",
               "/#{modtop}/lib/mac10v4/lib#{dep}.dylib",
               Formula["hdf5-1813"].lib/"lib#{dep}.dylib", modbin
      end
      system "install_name_tool", "-change",
             "/#{modtop}/lib/mac10v4/libintl.8.dylib",
             Formula["gettext"].lib/"libintl.8.dylib", modbin

      system "install_name_tool", "-change",
             "/#{modtop}/lib/mac10v4/libglib-2.0.0.dylib",
             Formula["glib"].lib/"libglib-2.0.0.dylib", modbin

      libs = ["ifcore", "imf", "intlc", "irc", "svml"]
      libs.each do |dep|
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

    pyver = Language::Python.major_minor_version "python"
    File.open('modeller.pth', 'w') do |file|
      file.puts "#{prefix}/modlib"
    end
    (lib/"python#{pyver}/site-packages").install "modeller.pth",
                                       "#{modtop}/lib/mac10v4/_modeller.so"

  end

end
