class Ihm < Formula
  desc "Package for handling IHM mmCIF and BinaryCIF files"
  homepage "https://github.com/ihmwg/python-ihm"
  url "https://pypi.io/packages/source/i/ihm/ihm-2.3.tar.gz"
  sha256 "5a9955d7378da7670814972f3d6312a998e417371dbf433694d8295b9cf25796"
  license "MIT"

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_sequoia: "470dd3f290cad5b5c0a2af64d24a9fce322683b7f48a04d263a2f52576d039d2"
    sha256 arm64_sonoma:  "bd41be0d5d7fb97246542f873a9509954d2bbc4f83c37ca1c4716f17321c9fc1"
    sha256 arm64_ventura: "de74f4625936334a460a2d3bf13222a96fd1d0beebf95ca2aa834e2682cf99a9"
    sha256 sequoia:       "337e4d3dbe2abbe1a318c1deb65b446d9d6993a37fcf6bd8e5c6d027da396dd0"
    sha256 sonoma:        "0d62ac1e47ad5d2edc0220f658ae51ffdfefe8908a7243bbf3c884a8f0dc56b2"
    sha256 ventura:       "563eabcfac1abc6aa39ed9f2c5699f0184ff4741fe2a9d7322b287d8e5e6cb6f"
  end

  depends_on "python@3.13"

  def install
    ENV.cxx11
    pybin = Formula["python@3.13"].opt_bin/"python3.13"
    prefix_site_packages = prefix/Language::Python.site_packages(pybin)
    system pybin, "setup.py", "install",
           "--single-version-externally-managed",
           "--record=installed.txt",
           "--install-lib=#{prefix_site_packages}"
  end

  test do
    pythons = [Formula["python@3.13"].opt_bin/"python3.13"]
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
