class Ihm < Formula
  desc "Package for handling IHM mmCIF and BinaryCIF files"
  homepage "https://github.com/ihmwg/python-ihm"
  url "https://pypi.io/packages/source/i/ihm/ihm-2.2.tar.gz"
  sha256 "07967f323d1df12f81246b51b75e5910e54e8588e680be82709f0d347215a1f7"
  license "MIT"

  bottle do
    root_url "https://salilab.org/homebrew/bottles"
    sha256 arm64_sequoia: "ce0c14dff5250174608435bbb04e179b6dc5f67d3cfab02b3ca1c58592e4286f"
    sha256 arm64_sonoma:  "682959023698c645f2f7b2210d192c89c7b93ff6510c004f54889a462a9c40be"
    sha256 arm64_ventura: "66eda3c85cac23b00a03e06fb0451b47b84776b55f5fc4343be496ddd5c2d49f"
    sha256 sequoia:       "f4fdc3dc076d299dfe0f57cc9d48d889c44d9e47d1497769d6cee3914c143065"
    sha256 sonoma:        "26f3e80f6e78c7828f4f8d417e6fdea8e2cd9c3cb90cd112c79436224be8206a"
    sha256 ventura:       "dd33aead6bffb07d399a8b79f1e33e096de1f7c190803dfca12362e7b14c83d8"
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
