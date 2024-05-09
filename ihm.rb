class Ihm < Formula
  desc "Package for handling IHM mmCIF and BinaryCIF files"
  homepage "https://github.com/ihmwg/python-ihm"
  url "https://pypi.io/packages/source/i/ihm/ihm-1.1.tar.gz"
  sha256 "69b592b11b5e0fb85f17d8b12d060d24a16dcc8df8e2148032b472d5e8381e57"
  license "MIT"
  revision 1

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_sonoma:   "caef2083ca8f38ef60e05b07e695865986f0cda3238fbd3fe65568e4e240dbc8"
    sha256 arm64_ventura:  "0fededa987a4d5b5efcd400ae55f609f1a9fb65386f44acdaeb5638374d0af21"
    sha256 arm64_monterey: "83b289ad2952e683452c0b0202dda30fbf29ae02c1d4611f346b3acbc442eee1"
    sha256 sonoma:         "cb64c4ec1503d99baba3c1bd221316d429cdb5a35a10aa0b42f54948d3839968"
    sha256 ventura:        "48e58d2fa25b0f43a90e60836a9cc7fc96417e0a8ce1140cd6d5a223fc427d2d"
    sha256 monterey:       "1daf8e8dcf0364b450fd7c7d4fbe7b7ae5ee3501ca929fea146ed2c8d0dc3158"
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
