class Ihm < Formula
  desc "Package for handling IHM mmCIF and BinaryCIF files"
  homepage "https://github.com/ihmwg/python-ihm"
  url "https://pypi.io/packages/source/i/ihm/ihm-1.0.tar.gz"
  sha256 "d6b76b5d32c0a7034a6bb3b424df858dc5cc1e42424b57512db155ff073a89b4"
  license "MIT"
  revision 1

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_sonoma:   "075a4c048fa043b532d2acf9ba57a7d72435cafa8ba5e791e9a8710cef1fc427"
    sha256 arm64_ventura:  "a96da4fa5abad9558eb1161b6aed18194cafa1b923a28d291f5d8849a59558ea"
    sha256 arm64_monterey: "fe62457f6be291775310992f79ecb8e5f9d2d386c8a7a34963a32953360eb30e"
    sha256 sonoma:         "6e0aa47a6155d1b589e3b539b0597938322b6f000a2aca50aa9f0dbeb63907cc"
    sha256 ventura:        "c2c71520b6fcec825a6ca03da1d2cf51b2589b7eab3845fef1a121e034897647"
    sha256 monterey:       "a3d9a49fe6b7326493c35bddf0cff40fe6a964aa22e00f5c57c8f65cccb50ab3"
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
