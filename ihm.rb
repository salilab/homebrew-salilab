class Ihm < Formula
  desc "Package for handling IHM mmCIF and BinaryCIF files"
  homepage "https://github.com/ihmwg/python-ihm"
  url "https://pypi.io/packages/source/i/ihm/ihm-0.41.tar.gz"
  sha256 "74b6c7ed1742571ee0241efbe56cc14fab8a84febc45a6275d55a0d258273ab0"
  license "MIT"

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_sonoma:   "49f234feff10f7fa8ef4b9d50c374b666d7533e85af7f7e8ff080193f5f37110"
    sha256 arm64_ventura:  "6ec4d6fa505d4df0913b49fdc4959dcb01502e62c083e3161511091ecb9da42d"
    sha256 arm64_monterey: "eed1ba552a7162d5e3924eeab7f19e6781b840e17bbe96d5fd992cdb3b634e74"
    sha256 sonoma:         "4bee7518e7f3aa6cbfbd0f4f32314348ef3d1561cfb11ed646924a013e74839b"
    sha256 ventura:        "6920a2bc7324c82db18b8db3f2f73b6b880e77da7b115bd8cc9f1fbb5adbc644"
    sha256 monterey:       "7d9f9a93a910af6920a78a54774ba745ed7ee6d03768de3232138f04088f45ca"
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
