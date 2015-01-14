package Module::Build::Dump;

# DATE
# VERSION

use 5.010;
use strict;
use warnings;

use Scalar::Util qw(blessed);

use Exporter qw(import);
our @EXPORT_OK = qw(dump_build_pl_script);

our %SPEC;

$SPEC{dump_build_pl_script} = {
    v => 1.1,
    summary => 'Run a Build.PL script but only to '.
        'dump the object content',
    description => <<'_',

This function runs `Build.PL` script that uses `Module::Build` but
monkey-patches beforehand so that `create_build_script()` will dump the object
content and then exit. The goal is to get the argument without actually running
the script to produce a build script.

This is used for example in `App::lcpan` project. When a release file does not
contain any `META.json` or `META.yml` file, the next best thing to try is to
extract this information from `Makefile.PL` or `Build.PL`. Since this is an
executable script, we'll need to run it, but we don't want to actually produce a
build script, hence this patch. (Another alternative would be to do a static
analysis of the script.)

_
    args => {
        filename => {
            summary => 'Path to the script',
            req => 1,
            schema => 'str*',
        },
        libs => {
            summary => 'Libraries to unshift to @INC when running script',
            schema  => ['array*' => of => 'str*'],
        },
    },
};
sub dump_build_pl_script {
    require Capture::Tiny;
    require UUID::Random;

    my %args = @_;

    my $filename = $args{filename} or return [400, "Please specify filename"];
    (-f $filename) or return [404, "No such file: $filename"];

    my $libs = $args{libs} // [];

    my $tag = UUID::Random::generate();
    my @cmd = (
        $^X, (map {"-I$_"} @$libs),
        "-MTimeout::Self=30", # to defeat scripts that prompts for stuffs
        "-MModule::Build::Base::Patch::DumpAndExit=-tag,$tag",
        $filename,
        "--version",
    );
    my ($stdout, $stderr, $exit) = Capture::Tiny::capture(
        sub { system @cmd },
    );

    my $obj;
    if ($stdout =~ /^# BEGIN DUMP $tag\s+(.*)^# END DUMP $tag/ms) {
        $obj = eval $1;
        if ($@) {
            return [500, "Error in eval-ing captured ".
                        "object: $@, raw capture: <<<$1>>>"];
        }
        if (!blessed($obj)) {
            return [500, "Didn't get an object, ".
                        "raw capture: stdout=<<$stdout>>"];
        }
    } else {
        return [500, "Can't capture object, raw capture: ".
                    "stdout=<<$stdout>>, stderr=<<$stderr>>"];
    }

    [200, "OK", $obj];
}

1;
# ABSTRACT:

=head1 SEE ALSO

L<Module::Build::Dump>
