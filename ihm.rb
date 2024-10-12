class Ihm < Formula
  desc "Package for handling IHM mmCIF and BinaryCIF files"
  homepage "https://github.com/ihmwg/python-ihm"
  url "https://pypi.io/packages/source/i/ihm/ihm-1.6.tar.gz"
  sha256 "d718c942bb1636ffbcec047863e21af4d647e5af2cf3efdfc3b19423c033f535"
  license "MIT"
  revision 1

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_sequoia: "b09d1d7ba7c6abd12c5d3dad6ce51a7b56dd5810ddf98bdd40c0057c56b36efe"
    sha256 arm64_sonoma:  "6c1b81cb539991ea852220a78f38b0fc0774661301da37794e1c4ce0766e23ba"
    sha256 arm64_ventura: "23fd1f9e7863d60e65aa34133ab74e47dd89c3e7eeb0645939aee0e10f60a0f2"
    sha256 sequoia:       "a358f22e42ace8edeccff07a409968c9ce415176cb1bc0ecf10762a0b3153c46"
    sha256 sonoma:        "9b236d17c92b73a52d34de8bd656d99b2d9297ca926a75f29d336d2902e9e097"
    sha256 ventura:       "6cb16cd53f0b672276cc39579d74feeb3e343af77ea7e02197c27656537e974a"
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
