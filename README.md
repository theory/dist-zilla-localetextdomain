Dist/Zilla/Plugin/LocaleTextDomain version 0.001
================================================

Dist::Zilla::Plugin::LocaleTextDomain compiles GNU gettext language files and
adds them into the distribution for use by L<Locale::TextDomain>. This is
useful if your distribution maintains gettext language files in a directory,
with each file named for a language.

Installation
------------

To install this module, type the following:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

Or, if you don't have Module::Build installed, type the following:

    perl Makefile.PL
    make
    make test
    make install

Dependencies
------------

This module requires the following modules:

* Capture::Tiny
* Carp
* Dist::Zilla::File::InMemory
* Dist::Zilla::Role::FileGatherer
* IPC::Cmd
* Moose
* Moose::Util::TypeConstraints
* MooseX::Types::Path::Class
* Path::Class
* namespace::autoclean

Copyright and License
---------------------

This software is copyright (c) 2012 by David E. Wheeler.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.
