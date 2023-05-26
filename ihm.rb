class Ihm < Formula
  desc "Package for handling IHM mmCIF and BinaryCIF files"
  homepage "https://github.com/ihmwg/python-ihm"
  url "https://pypi.io/packages/source/i/ihm/ihm-0.38.tar.gz"
  sha256 "571fe11fc7cd7eca9011e9c3bed9f5f9aceb11db155d07678fb678a204fb88ad"
  license "MIT"

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_ventura:  "5720919c2ed5fb0a5b62b0b23b2e497f250f283b7b274784fd2ee5d8f6d222c5"
    sha256 arm64_monterey: "529849565d11950dfcb2b7fdd07dc008b098d9b4556233728a9eef512536e1f8"
    sha256 ventura:        "f3d5720a0c7f2bae72683f49181d70f4df80a5035fed7d0cd0835454fe8fbb0e"
    sha256 monterey:       "930e7e2ec319cbd0b8b2c36465fd6eb504a2b328e8258c67692ca98ac0906437"
    sha256 big_sur:        "8264f150989cc40c5e18d3f434ac50425d1d385dd3f68de1558adbeeaae9d34a"
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
