class Ihm < Formula
  desc "Package for handling IHM mmCIF and BinaryCIF files"
  homepage "https://github.com/ihmwg/python-ihm"
  url "https://pypi.io/packages/source/i/ihm/ihm-1.2.tar.gz"
  sha256 "6608897b60ae4986ad98328756781e080818d651448570748712d4c5ae4a4a98"
  license "MIT"

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_sonoma:   "287038cfed45d8bc9f8054058deebbef63c61d4898a804aea9ea4489496d58de"
    sha256 arm64_ventura:  "ec4bd3bc245d8369abf364c1a58c45745d0b2b5bf65af82c88544d503e5de185"
    sha256 arm64_monterey: "0e35620d1470aec2dda2592d657ee4d0dca92116ac8a9844d11f5c4f7791881f"
    sha256 sonoma:         "077af3b2d311cc94c6f9aa517910894c79bd02307657dcbb70d78c829a756a21"
    sha256 ventura:        "5715891e10c6798dcdeb74390595a3954a9eeda720c80c11ea5ad9efa7699c29"
    sha256 monterey:       "7416e5d6130329fc8bd804c96fead14c2642c120ad6424be3d6b400f46853bba"
  end

  depends_on "python@3.12"

  def install
    ENV.cxx11
    pybin = Formula["python@3.12"].opt_bin/"python3.12"
    prefix_site_packages = prefix/Language::Python.site_packages(pybin)
    system pybin, "setup.py", "install",
           "--single-version-externally-managed",
           "--record=installed.txt",
           "--install-lib=#{prefix_site_packages}"
  end

  test do
    pythons = [Formula["python@3.12"].opt_bin/"python3.12"]
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
