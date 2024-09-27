class Ihm < Formula
  desc "Package for handling IHM mmCIF and BinaryCIF files"
  homepage "https://github.com/ihmwg/python-ihm"
  url "https://pypi.io/packages/source/i/ihm/ihm-1.6.tar.gz"
  sha256 "d718c942bb1636ffbcec047863e21af4d647e5af2cf3efdfc3b19423c033f535"
  license "MIT"

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_sequoia: "d464a856f43d73f81c6cda56185b34a9cbdddf173d4491b3356f5f3a82610120"
    sha256 arm64_sonoma:  "a0a8d3c227eeb5be5f87dc308eb95987f189eb15721905869a577524aaa560dc"
    sha256 arm64_ventura: "3d6b6917f8ffa9dc324dd392548463a86b6e0d5cf6c08b66b83f44f73d64b1c1"
    sha256 sequoia:       "9ad77058af751419558640e0e6a476c4eb4084f5c308747e7f579ea8f42973c2"
    sha256 sonoma:        "a0697d4aa25b6938a72d0cc80f15998700728d8fa39e4dee08798ffd1fa231bb"
    sha256 ventura:       "2b33fcbc056949e18069889ce04db90923ee42fcc195da83963d9157be6ec10b"
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
