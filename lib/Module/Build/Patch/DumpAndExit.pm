package Module::Build::Patch::DumpAndExit;

# DATE
# VERSION

use 5.010001;
use strict;
no warnings;

use Data::Dump;
use Module::Patch 0.19 qw();
use base qw(Module::Patch);

our %config;

sub _dump {
    print "# BEGIN DUMP $config{-tag}\n";
    dd @_;
    print "# END DUMP $config{-tag}\n";
}

sub _create_build_script {
    _dump(shift);
    $config{-exit_method} eq 'exit' ? exit(0) : die;
}

sub patch_data {
    return {
        v => 3,
        patches => [
            {
                action      => 'replace',
                sub_name    => 'create_build_script',
                code        => \&_create_build_script,
            },
        ],
        config => {
            -tag => {
                schema  => 'str*',
                default => 'TAG',
            },
            -exit_method => {
                schema  => 'str*',
                default => 'exit',
            },
        },
   };
}

1;
# ABSTRACT: Patch Module::Build's create_build_script to dump object and exit

=for Pod::Coverage ^(patch_data)$

=head1 DESCRIPTION

This patch can be used to extract object content from `Build.PL` script
without actually producing a Build script.


=head1 SEE ALSO

L<ExtUtils::MakeMaker::Dump>
