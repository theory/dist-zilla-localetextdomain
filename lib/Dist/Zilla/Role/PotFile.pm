package Dist::Zilla::Role::PotFile;

# ABSTRACT: Something that writes gettext langauge translation template file

use Moose::Role;
use strict;
use warnings;
use Carp;
use Path::Class;
use namespace::autoclean;

with 'Dist::Zilla::Role::PotWriter';
requires 'zilla';

our $VERSION = '0.11';

has plugin => (
    is      => 'ro',
    isa     => 'Dist::Zilla::Plugin::LocaleTextDomain',
    lazy    => 1,
    default => sub {
        shift->zilla->plugin_named('LocaleTextDomain')
            or croak 'LocaleTextDomain plugin not found in dist.ini!';
    }
);

sub pot_file {
    my ( $self, %p ) = @_;
    my $dzil = $self->zilla;
    my $pot  = $p{pot_file};
    if ($pot) {
        die "Template file $pot does not exist\n" unless -e $pot;
        return $pot;
    }

    # Look for a template in the default location used by `msg-scan`.
    $pot = file $self->plugin->lang_dir, $dzil->name . '.pot';
    return $pot if -e $pot;

    # Create a temporary template file.
    require File::Temp;
    my $tmp = $self->{tmp} = File::Temp->new(SUFFIX => '.pot', OPEN => 0);
    $pot = file $tmp->filename;
    $self->log('extracting gettext strings');
    $self->write_pot(
        to               => $pot,
        xgettext         => $p{xgettext},
        encoding         => $p{encoding},
        copyright_holder => $p{copyright_holder},
        bugs_email       => $p{bugs_email},
    );
    return $self->{potfile} = $pot;
}

1;
__END__

=head1 Name

Dist::Zilla::Plugin::PotFile - Something that writes gettext langauge translation template file

=head1 Synopsis

  with 'Dist::Zilla::Role::PotFile';

  # ...

  sub execute {
      my $self = shift;
      my $pot_file = $self->pot_file(%params);
  }


=head1 Description

This role provides a utilty method for finding or creating a
L<GNU gettext|http://www.gnu.org/software/gettext/>-style language translation
template.

=head2 Instance Methods

=head3 C<pot_file>

  $self->pot_file(%params);

Finds or creates a temporary
L<GNU gettext|http://www.gnu.org/software/gettext/>-style language translation
file. The supported parameters are:

=over

=item C<pot_file>

A path to an existing translation template file.

=item C<to>

L<Path::Class::File> object representing the file to write to. Required.

=item C<scan_files>

Array reference listing the files to scan. Defaults to all F<*.pm> files
gathered by L<Dist::Zilla>.

=item C<xgettext>

Path to the C<xgettext> application. Defaults to just C<xgettext>
(C<xgettext.exe> on Windows), which should work if it's in your path.

=item C<encoding>

Encoding to assume when scanning for localizable strings. Defaults to
C<UTF-8>.

=item C<package>

The name of the localization package. Defaults to the distribution name as
configured for L<Dist::Zilla>.

=item C<version>

The version of the package. Defaults to the version as configured for
L<Dist::Zilla>.

=item C<copyright_holder>

The name of the translation copyright holder. Defaults to the copyright holder
configured for L<Dist::Zilla>.

=item C<bugs_email>

Email address for reporting translation bugs. Defaults to the email address of
the first author known to L<Dist::Zilla>, if availale and parseable by
L<Email::Address>.

=back

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 Copyright and License

This software is copyright (c) 2012 by David E. Wheeler.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut
