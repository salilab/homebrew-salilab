class Ihm < Formula
  desc "Package for handling IHM mmCIF and BinaryCIF files"
  homepage "https://github.com/ihmwg/python-ihm"
  url "https://pypi.io/packages/source/i/ihm/ihm-0.37.tar.gz"
  sha256 "5ffab3ed3a983b594379de7968bbd42f7ce3b7908142e9552c7f10ed070e7db3"
  license "MIT"
  revision 1

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_ventura:  "5fe51aac44364e5dec96b0e2490b41d8d51cadc4515c9391bb1d718ac75028bf"
    sha256 arm64_monterey: "80c7779c95ac32209ac2d4eea4c99b6237b5ec326ac4fd49f46034938579da53"
    sha256 ventura:        "9cab9d05c6ee66a7ec4720d1d4684254a1f1fafee89a29d5974979085fa11242"
    sha256 monterey:       "13b1afae575994c306fe6f5a0a12ec719e9b3cfbd84486de1ab97e9d81bef9b9"
    sha256 big_sur:        "46dc3873fd3d7ea8750aa37c5b5927b1a407f4d13a3830d846e17234e94d044a"
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
