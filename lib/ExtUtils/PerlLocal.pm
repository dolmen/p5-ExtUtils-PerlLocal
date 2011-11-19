use strict;
use warnings;

package ExtUtils::PerlLocal;

use File::Spec ();

sub new
{
    my $class = shift;
    my %args = @_;

    my $file = $args{perllocal};
    unless (defined $file) {
	SEARCH: {
	    foreach my $dir (@INC) {
		last SEARCH if -f ($file = File::Spec->catfile($dir, 'perllocal.pod'));
	    }
	    require Carp;
	    Carp::croak('perllocal.pod not found in @INC')
	}
    } elsif (! -f $file) {
	require Carp;
	Carp::croak("$file not found")
    }

    open my $f, '<', $file or do {
	require Carp;
	Carp::croak("can't open $file: $!")
    };

    my (%modules, $mod);

    while (<$f>) {
	if (/^=head2 (.{3} .{3} .[0-9] [0-2][0-9]:[0-5][0-9]:[0-5][0-9] [0-9]{4}): C<Module> L<([^|]+)/) {
	    $mod = $modules{$2};
	    $mod = $modules{$2} = bless [ $2, undef, undef, [], [] ], 'ExtUtils::PerlLocal::Module' unless defined $mod;
	    push @{$mod->[3]}, $1;
	} elsif (/^C<installed into: (.*)>$/) {
	    $mod->[1] = $1;
	} elsif (/^C<VERSION: (.*)>$/) {
	    $mod->[2] = $1;
	    push @{$mod->[3]}, $1;
	} elsif (/^C<EXE_FILES: ([^>]+)>$/) {
	    $mod->[4] = [ split / /, $1 ];
	}
    }
    close $f;

    bless {
	file => $file,
	modules => \%modules,
    }, $class
}

sub file
{
    $_[0]->{file}
}

sub modules
{
    $_[0]->{modules}
}

sub module
{
    $_[0]->{modules}{$_[1]}
}

package ExtUtils::PerlLocal::Module;

use Scalar::Util ();
use HTTP::Date ();
use POSIX ();

sub name
{
    $_[0]->[0];
}

sub dir
{
    $_[0]->[1];
}

sub version
{
    $_[0]->[2]
}

sub history
{
    my $history = $_[0]->[3];

    # The date parsing is delayed to the time someone requires the history
    # for that module

    unless (Scalar::Util::looks_like_number($history->[0])) {
	# TODO rewrite the look with map and benefit of variable aliasing
	for(my $i = $#{$history}-1; $i >= 0; $i -= 2) {
	    $history->[$i] =
		POSIX::mktime(localtime(
		    HTTP::Date::str2time($history->[$i])
		));
	}
    }
    return $history;
}

sub exe_files
{
    @{$_[0]->[4]}
}

1;
