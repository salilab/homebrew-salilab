class Ihm < Formula
  desc "Package for handling IHM mmCIF and BinaryCIF files"
  homepage "https://github.com/ihmwg/python-ihm"
  url "https://pypi.io/packages/source/i/ihm/ihm-2.8.tar.gz"
  sha256 "528a6efe9c6576ace3b33cfde531f177a17e791ff365039582620b6ad9fbe441"
  license "MIT"

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_tahoe:   "4cf39981866a14f52296709fe0098e7821efbf1915ec80bc26b813cda9eeb695"
    sha256 arm64_sequoia: "b5af84db6618b330bb5055ecb6045e1ef74361e320829860cd0aa125dc6977c5"
    sha256 arm64_sonoma:  "3b4211aca8833113a4664a06c22d744aa4b5dd5a330f475aeced326c7111690a"
    sha256 tahoe:         "ce78521a57f4ae88db1505c216b2b321eaedbd2cbfb436ab61298838f1fa40b6"
    sha256 sequoia:       "f440d5fad35bca99d8bf9ace5ff997ee97fc8bcc0da4a9804992c5651d140667"
    sha256 sonoma:        "dfb5e93a10cb57f7bf39607abd6a82fafddf59057b45b68e611ed71a033232ac"
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
