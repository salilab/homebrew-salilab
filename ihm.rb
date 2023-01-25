class Ihm < Formula
  desc "Package for handling IHM mmCIF and BinaryCIF files"
  homepage "https://github.com/ihmwg/python-ihm"
  url "https://pypi.io/packages/source/i/ihm/ihm-0.36.tar.gz"
  sha256 "c5abad1962d8acf61ae509995da2bf19222d239bd3726b967f20a76fe0bb1c33"
  license "MIT"

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_ventura:  "cd97e2940a2afad5dfc1885dab04f639a42ca1ca8789a8a8c64b63cdf4b449e6"
    sha256 arm64_monterey: "d96ebd5ae38e144f6ad5d6e29525d0eea10beecf091e999cd5745cf5ca0ea25f"
    sha256 ventura:        "c1e209249bdf40f767d2e0108d51be24b7e805d6c48fb61416cece4c440b23db"
    sha256 monterey:       "f1368e6f4a8fc14e9f769faae15d6f421af1af940640d45ec8c669da27d602c3"
    sha256 big_sur:        "14c17caca3890dc48ced67b6f7445bdbf7d099139af9b2457ddc005abe3771b6"
  end

  depends_on "python@3.10"

  def install
    ENV.cxx11
    pybin = Formula["python@3.10"].opt_bin/"python3.10"
    prefix_site_packages = prefix/Language::Python.site_packages(pybin)
    system pybin, "setup.py", "install",
           "--single-version-externally-managed",
           "--record=installed.txt",
           "--install-lib=#{prefix_site_packages}"
  end

  test do
    pythons = [Formula["python@3.10"].opt_bin/"python3.10"]
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
