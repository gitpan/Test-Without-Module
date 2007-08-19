package Test::Without::Module;
use strict;
use Carp qw( croak );

use vars qw( $VERSION );
$VERSION = 0.11;

use constant SLOT => "Test::Without::Module::scope";
use constant REQUIRE_ERROR => q/Can't locate %s.pm in @INC (@INC contains: %s)/;

use vars qw( %forbidden );

sub get_forbidden_list {
  \%forbidden
};

sub import {
  my ($self,@forbidden_modules) = @_;

  # First, create a local copy of the active scope
  my $forbidden = get_forbidden_list;
  $forbidden->{$_} = $_
    for @forbidden_modules;

  # Scrub %INC, so that loaded modules disappear
  for my $module (@forbidden_modules) {
    scrub( $module );
  };

  unshift @INC, \&fake_module ;
};

sub fake_module {
    my ($self,$module_file,$member_only) = @_;
    warn $@ if $@;

    my $forbidden = get_forbidden_list;

    my $modulename = file2module($module_file);

    # Deliver a faked, nonworking module
    if (grep { $modulename =~ $_ } keys %$forbidden) {
      my @faked_module = ("package $modulename;","0;");
      return sub { defined ( $_ = shift @faked_module ) };
    };
};

sub unimport {
  my ($self,@list) = @_;
  my $module;
  my $forbidden = \%forbidden;
  for $module (@list) {
    if (exists $forbidden->{$module}) {
      delete $forbidden->{$module};
      scrub( $module );
    } else {
      croak "Can't allow non-forbidden module $module";
    };
  };
};

sub file2module {
  my ($mod) = @_;
  $mod =~ s!/!::!g;
  $mod =~ s!\.pm$!!;
  $mod;
};

sub scrub {
  my ($module) = @_;
  my $key;
  for $key (keys %INC) {
    delete $INC{$key}
      if (file2module($key) =~ $module);
  };
};

1;

=head1 NAME

Test::Without::Module - Test fallback behaviour in absence of modules

=head1 SYNOPSIS

=for example begin

  use Test::Without::Module qw( My::Module );

  # Now, loading of My::Module fails :
  eval { require My::Module; };
  warn $@ if $@;

  # Now it works again
  eval q{ no Test::Without::Module qw( My::Module ) };
  eval { require My::Module; };
  print "Found My::Module" unless $@;

=for example end

=head1 DESCRIPTION

This module allows you to deliberately hide modules from a program
even though they are installed. This is mostly useful for testing modules
that have a fallback when a certain dependency module is not installed.

=head2 EXPORT

None. All magic is done via C<use Test::Without::Module LIST> and
C<no Test::Without::Module LIST>.

=head2 Test::Without::Module::get_forbidden_list

This function returns a reference to a copy of the current hash of forbidden
modules or an empty hash if none are currently forbidden. This is convenient
if you are testing and/or debugging this module.

=cut

=head1 ONE LINER

A neat trick for using this module from the command line
was mentioned to me by NUFFIN:

  perl -MTest::Without::Module=Some::Module -w -Iblib/lib t/SomeModule.t

That way, you can easily see how your module or test file behaves
when a certain module is unavailable.

=head1 BUGS

=over 4

=item * There is no lexicalic scoping

=back

=head1 CREDITS

Much improvement must be thanked to Aristotle from PerlMonks, he pointed me
to a much less convoluted way to fake a module at
L<http://www.perlmonks.org/index.pl?node=192635>.

I also discussed with him an even more elegant way of overriding
CORE::GLOBAL::require, but the parsing of the overridden subroutine
didn't work out the way I wanted it - CORE::require didn't recognize
barewords as such anymore.

NUFFIN and Jerrad Pierce pointed out the convenient
use from the command line to interactively watch the
behaviour of the test suite and module in absence
of a module.

=head1 AUTHOR

Max Maischein, E<lt>corion@cpan.orgE<gt>

=head1 SEE ALSO

L<Acme::Intraweb>, L<PAR>, L<perlfunc>

=cut

__END__
