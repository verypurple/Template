package Template::Common;

use warnings;
use strict;

use Exporter qw(import);
our @EXPORT = qw(
    serialize
    unserialize
    unserialize_ref
    read_file
    write_file
    get_last_write_time
    set_last_write_time
);

sub serialize
{
    my ($data, $string) = @_;

    my $i = 0;
    $string .= '[';

    # TODO: escape single quotes

    for my $el (@$data) {
        if (ref($el) eq 'ARRAY') {
            $string .= serialize($el);
        }
        else {
            $string .= "'$el'";
        }

        if ($i++ < $#$data) {
            $string .= ',';
        }
    }

    $string .= ']';

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
            my $i = index($$data, '\'', 2);
            my $s = substr($$data, 1, $i-1);
            $$data = substr($$data, $i+1);
            push(@$items, $s);
        }
        elsif ($c =~ m/^[\s,]/) {
            $$data = substr($$data, 1);
        }
        elsif ($c eq ']') {
            $$data = substr($$data, 1);
            return $items;
        }
        else {
            die "Unserialize failed at character '$c' full string '$$data'";
        }
    }

    return $items;
}

sub read_file {
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

sub write_file {
	my ($path, $data) = @_;

	open(my $fh, ">$path")
		or die "Could not write file '$path'. $!";
	print $fh $data;
	close($fh);
}

sub get_last_write_time {
    my ($path) = @_;

    my $result = `stat -c %y $path`;
    chomp($result);

    return $result;
}

sub set_last_write_time {
    my ($path, $date) = @_;
    
    system("touch -d '$date' $path");
}

1;