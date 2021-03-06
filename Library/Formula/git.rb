require 'formula'

class GitManuals < Formula
  url 'http://kernel.org/pub/software/scm/git/git-manpages-1.7.6.1.tar.bz2'
  md5 'cae559424a62507cb2c15252d85a158e'
end

class GitHtmldocs < Formula
  url 'http://kernel.org/pub/software/scm/git/git-htmldocs-1.7.6.1.tar.bz2'
  md5 'f698e0abbf1555582e30320930391c59'
end

class Git < Formula
  url 'http://kernel.org/pub/software/scm/git/git-1.7.6.1.tar.bz2'
  md5 'd1e00772cc9dc6c571999feb9e8771ab'
  homepage 'http://git-scm.com'

  def options
    [['--with-blk-sha1', 'compile with the optimized SHA1 implementation']]
  end

  def install
    # If these things are installed, tell Git build system to not use them
    ENV['NO_FINK']='1'
    ENV['NO_DARWIN_PORTS']='1'
    # If local::lib is used you get a 'Only one of PREFIX or INSTALL_BASE can be given' error
    ENV['PERL_MM_OPT']=''
    # Build verbosely.
    ENV['V']='1'

    # Clean XCode 4.x installs don't include Perl MakeMaker
    ENV['NO_PERL_MAKEMAKER']='1' if MacOS.lion?

    ENV['BLK_SHA1']='YesPlease' if ARGV.include? '--with-blk-sha1'

    inreplace "Makefile" do |s|
      s.remove_make_var! %w{CFLAGS LDFLAGS}
    end

    system "make", "prefix=#{prefix}", "install"

    # Install the Git bash completion file.
    # Put it into the Cellar so that it gets upgraded along with git upgrades.
    (prefix+'etc/bash_completion.d').install 'contrib/completion/git-completion.bash'

    # Install emacs support.
    (share+'doc/git-core/contrib').install 'contrib/emacs'
    # Some people like the stuff in the contrib folder
    (share/:git).install 'contrib'

    # These files are exact copies of the git binary, so like the contents
    # of libexec/git-core lets hard link them.
    # I am assuming this is an overisght by the git devs.
    git_md5 = (bin+'git').md5
    %w[git-receive-pack git-upload-archive].each do |fn|
      fn = bin + fn
      next unless git_md5 == fn.md5
      fn.unlink
      fn.make_link bin+'git'
    end

    # We could build the manpages ourselves, but the build process depends
    # on many other packages, and is somewhat crazy, this way is easier.
    GitManuals.new.brew { man.install Dir['*'] }
    GitHtmldocs.new.brew { (share+'doc/git-doc').install Dir['*'] }
  end

  def caveats; <<-EOS.undent
    Bash completion has been installed to:
      #{etc}/bash_completion.d

    Emacs support has been installed to:
      #{HOMEBREW_PREFIX}/share/doc/git-core/contrib/emacs

    The rest of the "contrib" is installed to:
      #{HOMEBREW_PREFIX}/share/git/contrib
    EOS
  end
end
