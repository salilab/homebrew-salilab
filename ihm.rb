class Ihm < Formula
  desc "Package for handling IHM mmCIF and BinaryCIF files"
  homepage "https://github.com/ihmwg/python-ihm"
  url "https://pypi.io/packages/source/i/ihm/ihm-2.10.tar.gz"
  sha256 "d77923a7e1c852fa0a8fe3a96054432febdc9ff4e629e5aa85477be541ceae24"
  license "MIT"

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_tahoe:   "3d83a9b52774ec32dac329beb76a46e775de0f7d369acb01fc32d5289eafb0c8"
    sha256 arm64_sequoia: "a861b8e307551cf8c0eb43cc1f7c425e62437e220151058e56ac9fe81b8945e6"
    sha256 arm64_sonoma:  "7652bf6b5991b2d9f96f3cab4a4b7d53b4dbe3cf0a5a1b5d59f0770b02a4a4dd"
    sha256 tahoe:         "48b8fa203a950259dc41c79f3f590ad4eff127a651205abdf7c811a07b78c0e8"
    sha256 sequoia:       "fb5917e11fcf1e4ed05f4b47973179dd21da5cbc629e8d13f62b231f22f39f0d"
    sha256 sonoma:        "93db7cc9d769c24651aa1206be1a4bac3695d42de735cf730042f80f2f2033ee"
  end

  depends_on "python@3.14"

  def install
    ENV.cxx11
    pybin = Formula["python@3.14"].opt_bin/"python3.14"
    prefix_site_packages = prefix/Language::Python.site_packages(pybin)
    system pybin, "setup.py", "install",
           "--single-version-externally-managed",
           "--record=installed.txt",
           "--install-lib=#{prefix_site_packages}"
  end

  test do
    pythons = [Formula["python@3.14"].opt_bin/"python3.14"]
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
