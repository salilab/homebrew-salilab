class Ihm < Formula
  desc "Package for handling IHM mmCIF and BinaryCIF files"
  homepage "https://github.com/ihmwg/python-ihm"
  url "https://pypi.io/packages/source/i/ihm/ihm-1.8.tar.gz"
  sha256 "6c19813642487a5af3603beb51a1854559e55ccaa8fddd10986c3026a11b948f"
  license "MIT"

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_sequoia: "026181636ef48f034cd4c166ea6e298667d1f46acd5aebb62930cc0a58930066"
    sha256 arm64_sonoma:  "873d3a723ca795ed3320eadd1aa70ff0faf8f6972a256667663b8a753a831cef"
    sha256 arm64_ventura: "e9d432c7f01491a4a655cadbf07bda0ec3d747d6566a4384a8ef4a1cdc759fd3"
    sha256 sequoia:       "662220cb0d0cc3dfd3b5a957fcd74410204fcae46ab9ac4c2b056cbf5c35bcdd"
    sha256 sonoma:        "f94965dbf6c31d81fb75838d9b3226b2af82259423ed9ff34104a96238284ef4"
    sha256 ventura:       "cd52483fe80736da052b366cfbb02b4db50b20ba7f9e0a24145fb538390162d7"
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
