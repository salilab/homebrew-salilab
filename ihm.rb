class Ihm < Formula
  desc "Package for handling IHM mmCIF and BinaryCIF files"
  homepage "https://github.com/ihmwg/python-ihm"
  url "https://pypi.io/packages/source/i/ihm/ihm-0.35.tar.gz"
  sha256 "8bf5afba6df19e3aed0ab9f2d1851dcf22bbf9f0fd049067f3cdbcde542f6589"
  license "MIT"

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_ventura:  "cf7b5a61e66eac73a27e95619fc4130214a993a02928663b1827bb33f6184e57"
    sha256 arm64_monterey: "f5b955bba95017e6d68b65c773bc39b3e44598c518c8b39ab112a67e15d4ab46"
    sha256 ventura:        "2f26cbab8081534d653ff0bd5389dfd97ae0c7d8c7a3480bb57f48f5d089a760"
    sha256 monterey:       "3c4542d4397bf1a4ed275562fb52fc6a9cff48b2fc681bd6bcd241cf8e1c2aab"
    sha256 big_sur:        "7e1f626d013093281ea306f60333a58132e9cd104828379788d60fca08ec12c5"
    sha256 catalina:       "35f5bfbecc4d29f381522d668434e030a4cf537ade9d539d56fefe2002c33e95"
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
