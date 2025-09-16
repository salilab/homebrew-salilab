class Ihm < Formula
  desc "Package for handling IHM mmCIF and BinaryCIF files"
  homepage "https://github.com/ihmwg/python-ihm"
  url "https://pypi.io/packages/source/i/ihm/ihm-2.7.tar.gz"
  sha256 "a3b9eba5545de1e07a15d110e9e6b70369807798d8f2c45908323db2b6fde82c"
  license "MIT"

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_tahoe:   "50e5ef38a86bfe80d528dbf5cc696822638e3fcfd412f262ad7ee5b3b82766aa"
    sha256 arm64_sequoia: "ef4d4bc3b91f0d1be1e3197aee1708bd2526dc865ea556816f3b842e3b3c9159"
    sha256 arm64_sonoma:  "08e9c039e0956f633905dc75e29640f3a325b4130c9db4864679701b019a1d10"
    sha256 arm64_ventura: "978af999d7f250cb9a7f7fba488987e8858eb43238d0ee9c24817edee9467d40"
    sha256 tahoe:         "7e2075be0cc2f4fc0e280f0ed52847a4ae91cfd667025187c1196bb782417c1f"
    sha256 sequoia:       "99d5c89efef5e442a355772e6cc9039d9aa454147316a7e3ef99b8c714187e1f"
    sha256 sonoma:        "78867823e74756686abbcdcfcf8d9318b553c4a8afc1523cbffef111809e967c"
    sha256 ventura:       "98714f6a2c07ced517a4a69f0f71d109257177cc11f06e8cf12e5eacb3c60d14"
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
