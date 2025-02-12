class Ihm < Formula
  desc "Package for handling IHM mmCIF and BinaryCIF files"
  homepage "https://github.com/ihmwg/python-ihm"
  url "https://pypi.io/packages/source/i/ihm/ihm-2.0.tar.gz"
  sha256 "50d4fbef40138c7cabe6626a2ff25fb951256738ecce1274032feea7af9604b1"
  license "MIT"

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_sequoia: "45f87759093d96f914c5ca93356ce32a35476cdf68f44b652e015b32d92b27d8"
    sha256 arm64_sonoma:  "f9818e6694b7def7aa4b24a7b41e8845247e6ff966b5d2ff3b4d4ad19c2fdf4c"
    sha256 arm64_ventura: "b6611a919f68e8439af8a9cc24ea98fe4f57c62679112d057738c1f279f0e1c9"
    sha256 sequoia:       "d8325f03a0a0f9de30525a4daebed7af5bc2cefb224bfa2c37670bfb8d630de5"
    sha256 sonoma:        "7ca7a972e3ec4e6294452ff824c037537ff32e173fe2e1591cbb7b676a8400c0"
    sha256 ventura:       "03ef8c205b1c8158f1f878226a6c0200a7af2bf4af1e76f69d559bddd18b7ec0"
  end

  depends_on "python@3.13"

  # Include upstream BinaryCIF fixes
  patch do
    url "https://github.com/ihmwg/python-ihm/commit/bca8d4f24eab38ca0925df54d6df410916aa5323.patch?full_index=1"
    sha256 "5b8bd60d5329453bb544f0a8e7aa35238661f76b57731b7dbf639b94c893f1f1"
  end
  patch do
    url "https://github.com/ihmwg/python-ihm/commit/206d96404b8cbd74a299127e86d1228f1df28210.patch?full_index=1"
    sha256 "3a142c8cd5b3901271a5f892b8d4e40e2ba67d734b4516f1348814a19d9a4b2a"
  end

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
