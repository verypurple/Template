package Template::Engine;

use warnings;
use strict;

use Template::Lexer;
use Template::Parser;
use Template::Common;
use File::Path;

use Exporter qw(import);
our @EXPORT = qw(render);

my $i_funcs = {
	'if-then' => \&i_stmt_if_then,
	'if-then-else' => \&i_stmt_if_then_else,
	'for' => \&i_stmt_for,
	'html' => \&i_stmt_html,
	'identifier' => \&i_stmt_identifier,
};

my $cache_dir = "/var/tmp/tplengine/parser-cache";

my $output;
my $tree;

sub render 
{
	my ($template_path, $context) = @_;

	$output = '';

	my $cache_path = get_cache_from_template($template_path);
	my $template_modified = get_last_write_time($template_path);

	if (-e $cache_path) {
		my $cache_modified = get_last_write_time($cache_path);

		if ($template_modified eq $cache_modified) {
			my $data = read_file($cache_path);

			$tree = unserialize($data);
		}
	}

	if (!$tree) {
		my $input = read_file($template_path);
		my $tokens = lex_template($input);
		my $stack = parse_template($tokens);

		if (!$stack) {
			return "Parsing failed, template contains syntax error(s).";
		}

		$tree = parse_stack($stack, $tokens);

		my $data = serialize($tree);
		write_file($cache_path, $data);
		set_last_write_time($cache_path, $template_modified);
	}

	interpret($tree, $context);

	return $output;
}

sub get_cache_from_template {
	my ($template_path) = @_;

	my $hash = sha1sum($template_path);
	chomp($hash);
	my $cache_path = "$cache_dir/$hash";
	mkpath($cache_dir);

	return $cache_path;
}

sub interpret
{
	my ($tree, $context) = @_;

	for my $node (@$tree) {
		if (exists($i_funcs->{$node->[0]})) {
			$i_funcs->{$node->[0]}(@$node[1..$#$node], $context);
		}
		else {
			interpret($node, $context);
		}
	}
}

sub evaluate
{
	my ($exp, $context) = @_;
	my ($type, $value) = @$exp;

	if ($type eq 'identifier') {
		if (exists($context->{$value})) {
			return $context->{$value};
		}
		else {
			warn("Identifier '$value' not found in current context");
			return;
		}
	}
	if ($type eq 'string') {
		return $value;
	}
	if ($type eq 'integer') {
		return int($value);
	}
	if ($type eq 'unop') {
		my $op = $exp->[1];

		if ($op eq 'not') {
			return !evaluate($exp->[2], $context);
		}
	}
	if ($type eq 'binop') {
		my $op = $exp->[2];
		my $lv = evaluate($exp->[1], $context);
		my $rv = evaluate($exp->[3], $context);

		if ($op eq 'eq') {
			return $lv eq $rv;
		}
		if ($op eq 'gt') {
			return $lv gt $rv;
		}
		if ($op eq 'ge') {
			return $lv ge $rv;
		}
		if ($op eq 'lt') {
			return $lv lt $rv;
		}
		if ($op eq 'le') {
			return $lv le $rv;
		}
	}
}

sub i_stmt_if_then
{
	my ($condition, $then, $context) = @_;

	i_stmt_if_then_else($condition, $then, [], $context);
}


sub i_stmt_if_then_else
{
	my ($condition, $then, $else, $context) = @_;

	if (evaluate($condition, $context)) {
		interpret($then, $context);
	}
	elsif ($else) {
		interpret($else, $context);
	}
}

sub i_stmt_for
{
	my ($identifier, $stmts, $context) = @_;

	for my $el (@{$context->{$identifier}}) {
		interpret($stmts, $el);
	}
}

sub i_stmt_html
{
	$output .= $_[0];
}

sub i_stmt_identifier
{
	my ($value, $context) = @_;

	if (ref($context) eq 'HASH') {
		if (exists($context->{$value})) {
			$output .= $context->{$value};
		}
	}
	else {
		$output .= $context;
	}
}

1;
