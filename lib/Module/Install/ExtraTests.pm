use strict;
use warnings;
use 5.006;
package Module::Install::ExtraTests;
use Module::Install::Base;

BEGIN {
  our $VERSION = '0.004';
  our $ISCORE  = 1;
  our @ISA     = qw{Module::Install::Base};
}

sub extra_tests {
  my ($self) = @_;

  return unless -d 'xt';
  return unless my @content = grep { $_ =~ /^[.]/ } <xt/*>;

  die "unknown files found in ./xt" if grep { -f } @content;

  my %known   = map {; $_ => 1 } qw(author smoke release);
  my @unknown = grep { not $known{$_} } @content;
  die "unknown directories found in ./xt: @unknown" if @unknown;

  {
    no warnings qw(closure once);
    package # The newline tells PAUSE, "DO NOT INDEXING!"
    MY;
    sub test_via_harness {
      my ($self, $perl, $tests) = @_;
      my $a_str = -d 'xt/author'  ? 'xt/author'  : '';
      my $r_str = -d 'xt/release' ? 'xt/release' : '';
      my $s_str = -d 'xt/smoke'   ? 'xt/smoke'   : '';
      my $is_author = $Module::Install::AUTHOR ? 1 : 0;

      return qq{\t$perl "-Iinc" "-MModule::Install::ExtraTests" }
           . qq["-e" "Module::Install::ExtraTests::__harness('Test::Harness', (exists \\\$\$ENV{AUTHOR_TESTING} ? \\\$\$ENV{AUTHOR_TESTING} : $is_author), '$a_str', '$r_str', '$s_str', \$(TEST_VERBOSE), '\$(INST_LIB)', '\$(INST_ARCHLIB)')" $tests\n];
    }

    sub dist_test {
      my ($self, @args) = @_;
      my $text = $self->SUPER::dist_test(@args);
      my @lines = split /\n/, $text;
      $_ =~ s/ (\S*MAKE\S* test )/ RELEASE_TESTING=1 $1 / for grep { m/ test / } @lines;
      return join "\n", @lines;
    }

  }
}

sub __harness {
  my $harness_class = shift;
  my $is_author     = shift;
  my $author_tests  = shift;
  my $release_tests = shift;
  my $smoke_tests   = shift;

  eval "require $harness_class; 1" or die;
  require File::Spec;

  my $verbose = shift;
  eval "\$$harness_class\::verbose = $verbose; 1" or die;

  # Because Windows doesn't do this for us and listing all the *.t files
  # out on the command line can blow over its exec limit.
  require ExtUtils::Command;
  push @ARGV, __PACKAGE__->_deep_t($author_tests)
    if $author_tests and $is_author;

  push @ARGV, __PACKAGE__->_deep_t($release_tests)
    if $release_tests and $ENV{RELEASE_TESTING};

  push @ARGV, __PACKAGE__->_deep_t($smoke_tests)
    if $smoke_tests and $ENV{AUTOMATED_TESTING};

  my @argv = ExtUtils::Command::expand_wildcards(@ARGV);

  local @INC = @INC;
  unshift @INC, map { File::Spec->rel2abs($_) } @_;
  $harness_class->can('runtests')->(sort { lc $a cmp lc $b } @argv);
}

sub _wanted {
  my $href = shift;
  no warnings 'once';
  sub { /\.t$/ and -f $_ and $href->{$File::Find::dir} = 1 }
}

sub _deep_t {
  my ($self, $dir) = @_;
  require File::Find;

  my %test_dir;
  File::Find::find(_wanted(\%test_dir), $dir);
  return map { "$_/*.t" } sort keys %test_dir;
}

1;
__END__
=head1 NAME

Module::Install::ExtraTests - contextual tests that the harness can ignore

=head1 VERSION

0.001

=head1 COMMANDS

This plugin adds one Module::Install command:

=head2 extra_tests

  extra_tests;

This declares that the test files found in the directory F<./xt> should be run
only in certain instances:

  ./xt/author  - run when the tests are being run in an author's working copy
  ./xt/smoke   - run when the dist is being smoked (AUTOMATED_TESTING=1)
  ./xt/release - run during "make disttest"

These directories are recurisvely scanned for *.t files.  If any directories or
files exist in F<./xt> that are not recognized, the Makefile.PL will die.

B<Achtung!>  This is pretty scary, experimental code, mostly because it relies
on the pretty scary, non-experimental-but-seriously-sketchy underlying
customization system for ExtUtils::MakeMaker.  I may remove this warning when
I've decided that this is stable enough, but until then:

  HIC SUNT DRACONES

=head1 AUTHOR TESTS

"Is this being run by an author?" is determined internally by Module::Install,
but at the time of the writing of this version it's determined by the existence
of a directory called F<.author> in F<./inc>.  (On VMS, it's F<_author>.)  This
directory is created when Module::Install's F<Makefile.PL> is run in a
directory where no F<./inc> directory exists.

=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>. I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT

Copyright 2008, Ricardo SIGNES.  This program is free software;  you can
redistribute it and/or modify it under the same terms as Perl itself.

