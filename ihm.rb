class Ihm < Formula
  desc "Package for handling IHM mmCIF and BinaryCIF files"
  homepage "https://github.com/ihmwg/python-ihm"
  url "https://pypi.io/packages/source/i/ihm/ihm-1.0.tar.gz"
  sha256 "d6b76b5d32c0a7034a6bb3b424df858dc5cc1e42424b57512db155ff073a89b4"
  license "MIT"

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_sonoma:   "d0b31e6fbe18be30d0ef2daf4464c2e0e294b1afb0fc9008287347670d33ca41"
    sha256 arm64_ventura:  "5d0ce7ba8714f1de66562205afc9d103448e20b75c91956ea2ab11c3baf57ef0"
    sha256 arm64_monterey: "38ad7e6b36db1bb7dd117f645f6ffca4c7393909a29ff9d99409af32f4d20267"
    sha256 sonoma:         "8f0a188098ed0e7ea1f4942cffbc83dbf72bbd593f235fb7f0b5e95ea568595a"
    sha256 ventura:        "c79941fb0bf8fd791c351439027980a40ab5de02cecba2cf0e6e13f8ba4579c5"
    sha256 monterey:       "2650e12a52fe09e066677ddc9b74ffd72045cacc847af9b98887686ea0793a4a"
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
