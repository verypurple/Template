package Template::Common;

use warnings;
use strict;

use IPC::Open2;

use Exporter qw(import);
our @EXPORT = qw(
    serialize
    unserialize
    unserialize_ref
    read_file
    write_file
    get_last_write_time
    set_last_write_time
    sha1sum
);

sub serialize
{
    my ($data, $string) = @_;

    my $i = 0;
    $string .= '[';

    for my $el (@$data) {
        if (ref($el) eq 'ARRAY') {
            $string .= serialize($el);
        }
        else {
            $el =~ s/\'/\\'/g;
            $string .= "'$el'";
        }
        $string .= ',';
    }

    $string = substr($string, 0, -1) . ']';

    return $string;
}

sub unserialize
{
    my $data = $_[0];
    my $array = unserialize_ref(\$data);

    return $array->[0];
}

sub unserialize_ref
{
    my $data = $_[0];
    my $items;

    while ($$data) {
        my $c = substr($$data, 0, 1);
        if ($c eq '[') {
            $$data = substr($$data, 1);
            push(@$items, unserialize_ref($data));
        }
        elsif ($c eq '\'') {
            my $i = 0;
            my $p;
            
            do {
                $i = index($$data, "\'", $i + 1);
                $p = substr($$data, $i - 1, 1);
            } while ($p eq '\\');

            my $s = substr($$data, 1, $i - 1);
            $s =~ s/\\\'/\'/g;
            push(@$items, $s);

            $$data = substr($$data, $i + 1);
        }
        elsif ($c =~ m/^[\s,]/) {
            $$data = substr($$data, 1);
        }
        elsif ($c eq ']') {
            $$data = substr($$data, 1);
            return $items;
        }
        else {
            my $s = substr($$data, 0, 20);
            die "Unserialize failed at '$s'";
        }
    }

    return $items;
}

sub read_file
{
	my ($path) = @_;
	my $data;

	open(my $fh, $path)
		or die "Could not read file '$path'. $!";
	while (my $row = <$fh>) {
		$data .= $row
	}
	close($fh);

	return $data;
}

sub write_file
{
	my ($path, $data) = @_;

	open(my $fh, ">$path")
		or die "Could not write file '$path'. $!";
	print $fh $data;
	close($fh);
}

sub get_last_write_time
{
    my ($path) = @_;

    my $result = `stat -c %y $path`;
    chomp($result);

    return $result;
}

sub set_last_write_time
{
    my ($path, $date) = @_;
    
    system('touch', '-d', $date, $path);
}

sub sha1sum
{
    my ($input) = @_;

    my $pid = open2(*Reader, *Writer, "sha1sum");

    print Writer $input;
    close(Writer);

    my $output = <Reader>;
    my @slices = split(' ', $output);

    return $slices[0];
}

1;