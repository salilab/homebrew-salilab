class Ihm < Formula
  desc "Package for handling IHM mmCIF and BinaryCIF files"
  homepage "https://github.com/ihmwg/python-ihm"
  url "https://pypi.io/packages/source/i/ihm/ihm-0.40.tar.gz"
  sha256 "ef33f5c089ec6bb09ace79dd395e46e90df7641f11557b05755dbac1009e0cb7"
  license "MIT"

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_sonoma:   "6802a38fb5f9f559787fdd119fa0611e7360598e89c6a412faf5de85997d7706"
    sha256 arm64_ventura:  "9c8879cf79b60f4b1b80a907880b8ba56ec21207884c0ceb584791c96cfaa627"
    sha256 arm64_monterey: "8f06deb79b7be53aec8443a28cc71a0f41c199c95788ba16649a762672c4caf7"
    sha256 ventura:        "dd330cf39b54d09e98c11ef61fd24e77b34c488133d7b850c47444902f183c29"
    sha256 monterey:       "2bafa65a1a2aae588a9d0acd9f39298bd241c027ce5332231aa017d94c62b711"
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
