class Ihm < Formula
  desc "Package for handling IHM mmCIF and BinaryCIF files"
  homepage "https://github.com/ihmwg/python-ihm"
  url "https://pypi.io/packages/source/i/ihm/ihm-1.5.tar.gz"
  sha256 "8fc5afd3076328629835df2b5099abe067da260ece201909517eaf8abaee6197"
  license "MIT"

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_sonoma:   "267413f7ca1a7f73dad85f52a2ff7ad855b67e42a2a97f962166cbdeec578742"
    sha256 arm64_ventura:  "7c16e29a5542d40c2593326b56c73ff8cae7d449f65a2fa45b057c19fc28193b"
    sha256 arm64_monterey: "a57f02634bb64588dd5588bf76a4e7f7473c8c4591609db0e27d03bc002e3079"
    sha256 sonoma:         "dac55a267073931d9070b5e849f4ce6b757d411c3c3ded1261c97cd2f72a7e96"
    sha256 ventura:        "d68ee31fc708e1695ca428174212c944c93d458367d500ac3072609d96fb918c"
    sha256 monterey:       "8a578f1e9d882af477581f44c6966146c8d158eba4c7f8d07cc5ce4e286b026a"
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
