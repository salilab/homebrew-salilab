class Ihm < Formula
  desc "Package for handling IHM mmCIF and BinaryCIF files"
  homepage "https://github.com/ihmwg/python-ihm"
  url "https://pypi.io/packages/source/i/ihm/ihm-1.3.tar.gz"
  sha256 "09f69809fd81509cc26b60253c55b02ce79fc01fc8f4a068bca2953a7dfd33be"
  license "MIT"

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_sonoma:   "ad92220b343944d188bb18c4cb2577c12a14271f097f92e578ca22c84d0b08f5"
    sha256 arm64_ventura:  "4b5c907d7058d8e712172044167eded4367606120d87a45167aeea1f5697a7aa"
    sha256 arm64_monterey: "480ee93f05445873953aa8e4546ff96ed42e30ff0cebcfadc7e415c6422e19ee"
    sha256 sonoma:         "db1c7930afbdc94106c39a0aa85daeadfd9c8b937385026c9b2867e1b8e6de40"
    sha256 ventura:        "5069334f30513203f065a5999b62fd8790b6be85d4328065f7b514c74be91d3f"
    sha256 monterey:       "19b311dd251509c45ac64c7144238257215e57271d3642561691ba0611f70524"
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
