class Ihm < Formula
  desc "Package for handling IHM mmCIF and BinaryCIF files"
  homepage "https://github.com/ihmwg/python-ihm"
  url "https://pypi.io/packages/source/i/ihm/ihm-1.4.tar.gz"
  sha256 "2484bf82a383d25bc796280e4a456c9f4abf80e33b643a26d13566f9147f2afb"
  license "MIT"

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_sonoma:   "672e9b9995e6f1613d7ccc4754fd7b3dd15eda51b97272e1ace7f8864cba16bd"
    sha256 arm64_ventura:  "659e4ef52f8d65eb21f3b1081d3d8cce669f55e9c6c909b2a3be1822f5341967"
    sha256 arm64_monterey: "ddcfc64d0fa41880168bd8756c8dae1d82a5df30ac61f535ad6f165f632e9362"
    sha256 sonoma:         "6c30149f2f05a32459635307e817907c60c2d61fe3c549f26898dbe6f9fdf64e"
    sha256 ventura:        "633c3549de3e36d51b1beb0476c16d9b8aa3502c74cecbac44806e4561ae11a0"
    sha256 monterey:       "f65645e7852dd83e288b5384fa7c9b2ffed021d39b53320afd676ecb378ef23f"
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
