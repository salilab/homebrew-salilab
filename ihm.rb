class Ihm < Formula
  desc "Package for handling IHM mmCIF and BinaryCIF files"
  homepage "https://github.com/ihmwg/python-ihm"
  url "https://pypi.io/packages/source/i/ihm/ihm-1.7.tar.gz"
  sha256 "f7d3b9a76d9652f7091bbd1c6bea044a1d40b35bcba9b64c8e51a061fc2463de"
  license "MIT"

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_sequoia: "8b889965e2945bed7c8d3261b184aa52b3a4e414f267dc4470d2c6250345ddaf"
    sha256 arm64_sonoma:  "bc66b136fff134cb43d61554f0611d1b95c4d8adc27a74695845de909fa325f9"
    sha256 arm64_ventura: "bb342dd724e03e0cfb979891297e4f51472f3342f7de5c3938b09c4e86675f00"
    sha256 sequoia:       "9e12dab67325ab3338fc70da658e061e41177ef2f6a83ad0a585936d35a0c366"
    sha256 sonoma:        "02a75a2d62c5d4ac2a81f0d4ef979d00d6431da77e7e8da81a302d3eb8f81d57"
    sha256 ventura:       "0eacb2687ddacd70bc852405bfb5e4611b3010d307146d5c3302441a545131d5"
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
