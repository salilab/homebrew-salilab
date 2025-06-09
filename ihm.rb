class Ihm < Formula
  desc "Package for handling IHM mmCIF and BinaryCIF files"
  homepage "https://github.com/ihmwg/python-ihm"
  url "https://pypi.io/packages/source/i/ihm/ihm-2.6.tar.gz"
  sha256 "260b73c5299bbf02cfbc49ff4ebe55983b3ffb624bcf916af1391b23bc10bd72"
  license "MIT"

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_sequoia: "25aa5a2737c2994550f85d47eec2ca053d875cc219a054d86214b8896db01399"
    sha256 arm64_sonoma:  "d4c312ebfc72237d5c77efd74da5eba6ea6e33ba70bf5c1946d8055c5f711cde"
    sha256 arm64_ventura: "97eefefd46c7c6983a5cfa145eae0bc6a16bcea52066eabe2d0e8058c59cbf7f"
    sha256 sequoia:       "a72bef4338e5bd93088acc97815105d94277e093d05534f3000a07991d89b3d4"
    sha256 sonoma:        "f55764e49b7d789b8232ba9ec2192bf6eea4c157a58ba2d8a81b16902278d5af"
    sha256 ventura:       "beaa805cc48cd55aaba17082112512a6f0b44ebd1be89d470c5fc7ca988c06fe"
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
