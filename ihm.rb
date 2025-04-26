class Ihm < Formula
  desc "Package for handling IHM mmCIF and BinaryCIF files"
  homepage "https://github.com/ihmwg/python-ihm"
  url "https://pypi.io/packages/source/i/ihm/ihm-2.5.tar.gz"
  sha256 "de0723c8fa9039e5b752f02dfaa24b6eff02baeada57f5f44e953a4e6abb7b3a"
  license "MIT"

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_sequoia: "79b35013e16af710268f8795af55c7ff146e45ba4148a9d8675da0ad01cff58b"
    sha256 arm64_sonoma:  "fbea70cadfdcbc5f802be83e7351b6c111db4b86e659f2f3c4a23bfb3da75f9a"
    sha256 arm64_ventura: "c6a254a12d4fdea376e1d25fc897241772369ad930e347d94cacac05909f1ad7"
    sha256 sequoia:       "b0b7da1540f6f7cf9767c74a6882ffc24972ee5917d53bcc82d562a673356518"
    sha256 sonoma:        "0c3be17bcf4360ea43c9ed2d342ee932efc3b0d8a140e030cecd9c9bc53b6947"
    sha256 ventura:       "bc2f4edcc03946f9dff3dabad5e84820a4043d3acdecb1faee53534cc4939af0"
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
