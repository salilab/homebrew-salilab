class Ihm < Formula
  desc "Package for handling IHM mmCIF and BinaryCIF files"
  homepage "https://github.com/ihmwg/python-ihm"
  url "https://pypi.io/packages/source/i/ihm/ihm-2.11.tar.gz"
  sha256 "cb1bc75af04c5a7271f788f8018f30ee747a4d73fc45ab23f05d094ca44c0f0c"
  license "MIT"

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_tahoe:   "be5b45e288ba14ffd661a5603d8c30741dc3434ea6dfc01ab3f7955f4a686a30"
    sha256 arm64_sequoia: "16178ee06f5a2cfe08eadd98a9867837dc3a9f966e559c9dab6695fdadf1d698"
    sha256 arm64_sonoma:  "aaf0b12b067bbffcca004709542608deff6ce6bc0d137810ae0fc02bdd38d2fc"
    sha256 tahoe:         "8e01a1b9584f64f5f1c0165c3a74e1d4a99c209cfc648cb964351393c48d68d5"
    sha256 sequoia:       "612ac36248d39e3fd336a9e4e9fa9f4014b761393cfc29a29f446227896a2775"
    sha256 sonoma:        "521c557f043fa8152a98304dcac859553d0af9e0395814552c635049fe12c629"
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
