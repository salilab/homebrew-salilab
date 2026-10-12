class Ihm < Formula
  desc "Package for handling IHM mmCIF and BinaryCIF files"
  homepage "https://github.com/ihmwg/python-ihm"
  url "https://pypi.io/packages/source/i/ihm/ihm-2.12.tar.gz"
  sha256 "1172cb95007d02dd32fdfde257806d43f63f976ddec9ffaa78265ff9e244f3ec"
  license "MIT"
  revision 1

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_golden_gate: "8553ea956058bcd02ff305d00feb2ea797bbd9376ba8efeeec4109c6c93c3b3c"
    sha256 arm64_tahoe:       "19df7e31a275d7870d47cfc359e1ce83039f0b1aa7cfa65ad9f56bc32e2b20e0"
    sha256 arm64_sequoia:     "d4cfa0c8e1272cfbcd81bf060ba9de60b1dab00450b94b5fb5e472800eab7c34"
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
