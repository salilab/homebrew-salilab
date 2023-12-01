class Ihm < Formula
  desc "Package for handling IHM mmCIF and BinaryCIF files"
  homepage "https://github.com/ihmwg/python-ihm"
  url "https://pypi.io/packages/source/i/ihm/ihm-0.42.tar.gz"
  sha256 "dc592bfef114f466b4f0ec3e3f130b2768883c5858cf28e2d0b8085b007ecc29"
  license "MIT"

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_sonoma:   "53a4705d24a62741ed97cf956435ab93c6bb0994550c4ca458daa1a4f6c0a75d"
    sha256 arm64_ventura:  "0af903171e9dfdc504cc15cd164e68aba8060def280d2a0bc31d2c94ebba79a5"
    sha256 arm64_monterey: "46e51eadd4868474ff7bba9c80179261c166490b1a283d6636cafc99a707e0c8"
    sha256 sonoma:         "5987cc0cd0e858220521c9a2dd7f25a9cbf0c80d1cd7702e0b987e3da9f48fb6"
    sha256 ventura:        "f8db389c13e84d71d65ab308ff7d3540880909f7f96221f645e1084a068568f5"
    sha256 monterey:       "b721130d517b8399af64bb73ebe9f2842ce47c3d7277053184d8c409b979bc76"
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
