class Ihm < Formula
  desc "Package for handling IHM mmCIF and BinaryCIF files"
  homepage "https://github.com/ihmwg/python-ihm"
  url "https://pypi.io/packages/source/i/ihm/ihm-0.43.tar.gz"
  sha256 "bbfcbbd3f15509b5e3d3e88b49385aa00ca861259960443f41d12f39d5111af2"
  license "MIT"

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_sonoma:   "639389ba40469bd590902c0a681072fd1771791db5874f3409275dee4df40f85"
    sha256 arm64_ventura:  "5bf23401b044a6aba90794a04be9db945f5c2bf8274244e7acd712cb601ad82a"
    sha256 arm64_monterey: "35408c1603b1c311b1588acd91299f42250c683da45575df1dcd7d3b3569a069"
    sha256 sonoma:         "9196e687a096ab318e73dba0eddb10d4ce444a7eeb4de8038afe3b8253b49faf"
    sha256 ventura:        "68398853fb49366244925bf4b0e68183a44ee79ce8e8a71dd33ba6377626e053"
    sha256 monterey:       "edadb0fdef75ca8a500ac15c45fe00ff69965dc8ee4998012e8624475cb48c49"
  end

  depends_on "python@3.11"

  def install
    ENV.cxx11
    pybin = Formula["python@3.11"].opt_bin/"python3.11"
    prefix_site_packages = prefix/Language::Python.site_packages(pybin)
    system pybin, "setup.py", "install",
           "--single-version-externally-managed",
           "--record=installed.txt",
           "--install-lib=#{prefix_site_packages}"
  end

  test do
    pythons = [Formula["python@3.11"].opt_bin/"python3.11"]
    (testpath/"test.py").write <<~EOS
      import ihm
      import ihm.dumper
      import ihm.reader
      import os

      system = ihm.System(title='test system')

      entityA = ihm.Entity('AAA', description='Subunit A')
      entityB = ihm.Entity('AAAAAA', description='Subunit B')
      system.entities.extend((entityA, entityB))

      with open('output.cif', 'w') as fh:
          ihm.dumper.write(fh, [system])

      with open('output.cif') as fh:
          sys2, = ihm.reader.read(fh)
      assert sys2.title == 'test system'
      os.unlink('output.cif')
    EOS

    pythons.each do |python|
      system python, "test.py"
    end
  end
end
