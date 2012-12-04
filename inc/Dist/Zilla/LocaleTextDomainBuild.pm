package Dist::Zilla::LocaleTextDomainBuild;

use strict;
use warnings;
use Module::Build 0.35;
use base 'Module::Build';

sub new {
    my $self = shift->SUPER::new(@_);
    my $gettext = 'gettext' . ($^O eq 'MSWin32' ? '.exe' : '');
    my $version = $self->_backticks($gettext, '--version');
    if (!$version || $version =~ /--version/) {
        print STDERR '#' x 64, "\n",
        "# Cannot find compatible GNU gettext in PATH; Download it from:\n",
        "#     http://www.gnu.org/software/gettext/gettext.html\n",
        "# Aborting build.\n",
        '#' x 64, "\n\n";
        exit 255;
    }
    return $self;
}

1;
