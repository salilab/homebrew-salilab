class Ihm < Formula
  desc "Package for handling IHM mmCIF and BinaryCIF files"
  homepage "https://github.com/ihmwg/python-ihm"
  url "https://pypi.io/packages/source/i/ihm/ihm-2.7.tar.gz"
  sha256 "a3b9eba5545de1e07a15d110e9e6b70369807798d8f2c45908323db2b6fde82c"
  license "MIT"
  revision 1

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_tahoe:   "5ad5d42e365b71ca6f9634d0d1e5ceb8fc340a44343bb7da46fe362bd679057e"
    sha256 arm64_sequoia: "f0c1adae9d780c6f42e73a548e4d8f464b18f2244f2602e1fb2471ef2ac6bec1"
    sha256 arm64_sonoma:  "9e76b571abae9f4fbceb0ee592aa8a564cf6b1f08c9f38bbe126aa31fa865eb4"
    sha256 tahoe:         "8692cad148d85d45c596dc2f71ad9823feef4adb60ba014f4e71164817e1a40f"
    sha256 sequoia:       "2e247f8aa33bf8d5f0222f880f49242e0e48c44037580cbf4295ab85270f2a03"
    sha256 sonoma:        "69df46636b222be2cf57623d40f4cdd55ba29bceeae20c14374dccf41e099736"
  end

  depends_on "python@3.14"

  def install
    ENV.cxx11
    pybin = Formula["python@3.14"].opt_bin/"python3.14"
    prefix_site_packages = prefix/Language::Python.site_packages(pybin)
    system pybin, "setup.py", "install",
           "--single-version-externally-managed",
           "--record=installed.txt",
           "--install-lib=#{prefix_site_packages}"
  end

  test do
    pythons = [Formula["python@3.14"].opt_bin/"python3.14"]
    (testpath/"test.py").write <<~EOS
      import ihm
      import ihm.dumper
      import ihm.reader
      # Make sure the C extension built correctly
      import ihm._format
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
