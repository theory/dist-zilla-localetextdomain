package Dist::Zilla::LocaleTextDomainBuild;

use strict;
use warnings;
use Module::Build 0.35;
use base 'Module::Build';

sub new {
    my $self = shift->SUPER::new(@_);
    die "Cannot find compatible GNU gettext in PATH\n"
        unless $self->_backticks(qw(gettext --version));
    return $self;
}

1;
