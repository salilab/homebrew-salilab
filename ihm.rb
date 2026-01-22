class Ihm < Formula
  desc "Package for handling IHM mmCIF and BinaryCIF files"
  homepage "https://github.com/ihmwg/python-ihm"
  url "https://pypi.io/packages/source/i/ihm/ihm-2.9.tar.gz"
  sha256 "2efc460217c66b4d359c1eb7509ffa417568c2e59e04c0e2609995db99fc937f"
  license "MIT"

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_tahoe:   "a04ff102cd8ebde35628e7714033a9f00c7231a9093f93abc50575e48efe41cf"
    sha256 arm64_sequoia: "364bf57fc0da50b8e0b60f1716e1877a5572a8537d97770733e27079a056125f"
    sha256 arm64_sonoma:  "23590ab10397316fd8e648c05856ba60dfe16b3a37c22b929ed57c03095f9a01"
    sha256 tahoe:         "430e5c7203bd2b4ca820d79b5bc2f618e0fc011b2b96c922ead080e2ff291be8"
    sha256 sequoia:       "2bfc2aead7e76e1dea62c470bcd32e310ffc96df174d5c001319e46dd5b230b0"
    sha256 sonoma:        "cb2d1fce005dcf3852b027d9acf5dbffe816f74c68cf944041957b3b11dee00a"
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
