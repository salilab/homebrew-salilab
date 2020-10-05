require 'formula'

class DoxygenAT186 < Formula
  homepage 'http://www.doxygen.org/'
  url 'http://ftp.stack.nl/pub/users/dimitri/doxygen-1.8.6.src.tar.gz'
  mirror 'http://downloads.sourceforge.net/project/doxygen/rel-1.8.6/doxygen-1.8.6.src.tar.gz'
  sha256 '6a718625f0c0c1eb3dee78ec1f83409b49e790f4c6c47fd44cd51cb92695535f'
  license "GPL-2.0-only"

  head 'https://doxygen.svn.sourceforge.net/svnroot/doxygen/trunk'

  option 'with-dot', 'Build with dot command support from Graphviz.'
  option 'with-libclang', 'Build with libclang support.'

  depends_on 'graphviz' if build.with? 'dot'
  depends_on 'llvm' => 'with-clang' if build.with? 'libclang'

  def install
    args = ["--prefix", prefix]
    args << '--with-libclang' if build.with? 'libclang'
    system "./configure", *args
    # Per Macports:
    # https://trac.macports.org/browser/trunk/dports/textproc/doxygen/Portfile#L92
    inreplace %w[ libmd5/Makefile.libmd5
                  src/Makefile.libdoxycfg
                  tmake/lib/macosx-c++/tmake.conf
                  tmake/lib/macosx-intel-c++/tmake.conf
                  tmake/lib/macosx-uni-c++/tmake.conf ] do |s|
      # makefiles hardcode both cc and c++
      s.gsub! /cc$/, ENV.cc
      s.gsub! /c\+\+$/, ENV.cxx
    end

    # This is a terrible hack; configure finds lex/yacc OK but
    # one Makefile doesn't get generated with these, so pull
    # them out of a known good file and cram them into the other.
    lex = ''
    yacc = ''

    inreplace 'src/libdoxycfg.t' do |s|
      lex = s.get_make_var 'LEX'
      yacc = s.get_make_var 'YACC'
    end

    inreplace 'src/Makefile.libdoxycfg' do |s|
      s.change_make_var! 'LEX', lex
      s.change_make_var! 'YACC', yacc
    end

    system "make"
    # MAN1DIR, relative to the given prefix
    system "make", "MAN1DIR=share/man/man1", "install"
  end
end
