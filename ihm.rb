class Ihm < Formula
  desc "Package for handling IHM mmCIF and BinaryCIF files"
  homepage "https://github.com/ihmwg/python-ihm"
  url "https://pypi.io/packages/source/i/ihm/ihm-0.39.tar.gz"
  sha256 "7f31b8e247e5a0ac0ee67783a52ec0da893932333578d490e2dac4fef058d54a"
  license "MIT"

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_ventura:  "ef9fcf55d77056be3b594c7116fcd6ffef1a2f634555afded020b72b10ebf3a9"
    sha256 arm64_monterey: "eba0ce3c578eef6cbae96f7b1b2887a899eaf98d025c7bc11ac373b55f515436"
    sha256 ventura:        "eacc98d6a25d2768038b461db92c29b5fef3236c403b068e453164c657dfa662"
    sha256 monterey:       "700314ab8785282d5176647cf73b00963bdf7cace992bc4bdc3cd485f91c90b8"
    sha256 big_sur:        "3ed50d3b4dc9b4a8cdf1aac49bfc3429a0bba74d930001f159f85316cc1079e1"
  end

  depends_on "python@3.11"

  def install
    ENV.cxx11
    pybin = Formula["python@3.11"].opt_bin/"python3.11"
    prefix_site_packages = prefix/Language::Python.site_packages(pybin)
    system pybin, "setup.py", "install",
           "--single-version-externally-managed",
           "--record=installed.txt",
           "--install-lib=#{prefix_site_packages}"
  end

  test do
    pythons = [Formula["python@3.11"].opt_bin/"python3.11"]
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
