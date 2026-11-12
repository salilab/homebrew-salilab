class Ihm < Formula
  desc "Package for handling IHM mmCIF and BinaryCIF files"
  homepage "https://github.com/ihmwg/python-ihm"
  url "https://pypi.io/packages/source/i/ihm/ihm-2.13.tar.gz"
  sha256 "71c9e30f4ded27f8985961ecb51fd1b932a9bf5ced17eff4069f1f5fc22093af"
  license "MIT"

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_golden_gate: "81589627e305452ad7a032ceeb71644beabd7cd486b4dfc504485c1534e41431"
    sha256 arm64_tahoe:       "3a01969b3d339ddf73eef58bb237ba7fd07b4e9a54e511323b4ddf2c9406e5a7"
    sha256 arm64_sequoia:     "b41d950d126bda807b442bbf5ccafe6a0ef437d200dbe2ed41bac47d52f2f9b7"
  end

  depends_on "python@3.15"

  def install
    ENV.cxx11
    pybin = Formula["python@3.15"].opt_bin/"python3.15"
    prefix_site_packages = prefix/Language::Python.site_packages(pybin)
    system pybin, "setup.py", "install",
           "--single-version-externally-managed",
           "--record=installed.txt",
           "--install-lib=#{prefix_site_packages}"
  end

  test do
    pythons = [Formula["python@3.15"].opt_bin/"python3.15"]
    (testpath/"test.py").write <<~EOS
      import ihm
      import ihm.dumper
      import ihm.reader
      # Make sure the C extension built correctly
      import ihm._format
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
