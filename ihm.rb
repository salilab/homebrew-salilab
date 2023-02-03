class Ihm < Formula
  desc "Package for handling IHM mmCIF and BinaryCIF files"
  homepage "https://github.com/ihmwg/python-ihm"
  url "https://pypi.io/packages/source/i/ihm/ihm-0.37.tar.gz"
  sha256 "5ffab3ed3a983b594379de7968bbd42f7ce3b7908142e9552c7f10ed070e7db3"
  license "MIT"

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_ventura:  "f6d60adb4cea6713751ccd4a93c911991e9fae0f214a97ec0b6cfb3507e8938b"
    sha256 arm64_monterey: "d9319964b3aa11405f5dc008c19cd050dfe44a4d1ba3240ea36e2a4dfac9cbb2"
    sha256 ventura:        "a93d2420ea8bcacccfd3f583e77481dbac816e68402520ffdc08104dd523aa17"
    sha256 monterey:       "603f19c5e7dd300e71fe204e82193868c017a23e2cca237e0354870fb0759f8c"
    sha256 big_sur:        "d132dfab1db9d34af85186f8b008da50a07d7f469e32825eb4f00190d66793e1"
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
