class Ihm < Formula
  desc "Package for handling IHM mmCIF and BinaryCIF files"
  homepage "https://github.com/ihmwg/python-ihm"
  url "https://pypi.io/packages/source/i/ihm/ihm-2.4.tar.gz"
  sha256 "d9cfb54190f90d2449272d581ffa183cf75503bf48f9ee0f545c327dc3fbf299"
  license "MIT"

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_sequoia: "99962885a32aad0ac73cd425e3a85c9d7440be0127d85dbed07ef6ca51a58a1a"
    sha256 arm64_sonoma:  "095dd3ebd67df38fbd44500d575765f6662b47cb6a5b9874c57ddbf775983b84"
    sha256 arm64_ventura: "fef5b7cb43b229f4f05062eae8f9060344587563ecb0d320d80f107da0d8be85"
    sha256 sequoia:       "30ef6b83684fe8c6b618afa3e4422304f537a91c5018bc9b11a2a837c2b5773b"
    sha256 sonoma:        "69df4ba2a953895105ceeceb8602c22c92e785d95c99ee2ac22e066c808a34ab"
    sha256 ventura:       "3d65bfeb38c10e76154779d2f8c27c4f51e1202d2803cbc4d4353ad72fe754d6"
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
