package Test::Without::Module;
use strict;
use File::Temp;
use Carp qw( croak );

use vars qw( $VERSION );
$VERSION = 0.02;

use constant SLOT => "Test::Without::Module::scope";

use vars qw( %forbidden );

sub get_forbidden_list {
  #warn "Called from ",caller,"\n";
  #warn "Creating new list"
  #  unless exists $^H{SLOT()};
  #exists $^H{SLOT()} 
  #  ? { $^H{SLOT()} }
  #  : { }
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

  # Move our handler to the front of the list
  @INC = grep { $_ ne \&fake_module } @INC;
  unshift @INC, \&fake_module;
};

sub fake_module {
    my ($self,$module_file,$member_only) = @_;
    warn $@ if $@;

    my $forbidden = get_forbidden_list;
    
    my $modulename = file2module($module_file);

    # Deliver a faked, nonworking module
    if (grep { $modulename =~ $_ } keys %$forbidden) {

      my $fh = File::Temp::tmpfile();
      print $fh <<MODULE;
package $modulename;

=head1 NAME

$modulename

=head1 SYNOPSIS

!!! THIS IS A FAKED VERSION OF $modulename !!!
!!! IT WAS CREATED BY Test::Without::Module          !!!
!!! IT SHOULD NEVER END UP IN YOUR lib/ OR site/lib/ !!!

=cut

sub import { undef };
0;
MODULE
      seek $fh, 0,0;
      return $fh;
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
  use Test::Without::Module qw( File::Temp );

  # Now, loading of File::Temp fails :
  eval { require File::Temp; };
  warn $@ if $@;

  # Now it works again
  eval q{ no Test::Without::Module qw( File::Temp ) };
  eval { require File::Temp; };
  print "Found File::Temp" unless $@;

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

=head1 BUGS

=over 4

=item * There is no lexicalic scoping (yet)

=back

=head1 AUTHOR

Max Maischein, E<lt>corion@cpan.orgE<gt>

=head1 SEE ALSO

L<Acme::Intraweb>, L<PAR>, L<perlfunc>

=cut

__END__