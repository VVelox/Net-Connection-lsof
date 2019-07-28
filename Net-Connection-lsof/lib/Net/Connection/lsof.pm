package Net::Connection::lsof;

use 5.006;
use strict;
use warnings;
use Net::Connection;
require Exporter;

our @ISA = qw(Exporter);
our @EXPORT=qw(lsof_to_nc_objects);

=head1 NAME

Net::Connection::lsof - This uses lsof to generate a array of Net::Connection objects.

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';


=head1 SYNOPSIS

    use Net::Connection::lsof;

    my @objects = lsof_to_nc_objects;

=head1 SUBROUTINES

=head2 lsof_to_nc_objects

This runs 'lsof -i UDP -i TCP -n -l +c 19 -P' and parses the output
returns a array of Net::Connection objects.

=cut

sub lsof_to_nc_objects{
	my %func_args;
	if(defined($_[0])){
		%func_args= %{$_[0]};
	};

	if ( !defined( $func_args{ptrs} ) ){
		$func_args{ptrs}=1;
	}
	if ( !defined( $func_args{ports} ) ){
		$func_args{ports}=1;
	}

	my $output_raw=`lsof -i UDP -i TCP -n -l +c 19 -P`;
	my @output_lines=split(/\n/, $output_raw);

	my @nc_objects;

	my $line_int=1;
	while ( defined( $output_lines[$line_int] ) ){
		my $command=substr $output_lines[$line_int], 0, 19;
		my $line=substr $output_lines[$line_int], 19;

		my @line_split=split(/[\ \t]+/, $line );

		my $args={
				  pid=>$line_split[0],
				  uid=>$line_split[1],
				  ports=>$func_args{ports},
				  ptrs=>$func_args{ptrs},
				  };

		my $type=$line_split[2];
		my $mode=$line_split[6];
		my $name=$line_split[7];

		# Use the name and type to build the proto.
		my $proto='';
		if ( $type =~ /6/ ){
			$proto='6';
		}elsif( $type =~ /4/ ){
			$proto='6';
		}
		if ( $mode =~ /[Uu][Dd][Pp]/ ){
			$proto='udp'.$proto;
		}elsif( $mode =~ /[Tt][Cc][Pp]/ ){
			$proto='tcp'.$proto;
		}
		$args->{proto}=$proto;

		my ( $local, $foreign )=split( /\-\>/, $name );

		my $ip;
		my $port;

		if ( ! defined( $foreign ) ){
			$args->{foreign_host}='*';
			$args->{foreign_port}='*';
		}else{
			if ( $foreign =~ /\]/ ){
				( $ip, $port ) = split( /\]/, $foreign );
				$ip=~s/^\[//;
				$port=~s/\://;
			}else{
				( $ip, $port ) = split( /\:/, $foreign );
			}

			$args->{foreign_host}=$ip;
			$args->{foreign_port}=$port;
		}

		if ( $local =~ /\]/ ){
			( $ip, $port ) = split( /\]/, $local );
			$ip=~s/^\[//;
			$port=~s/\://;
		}else{
			( $ip, $port ) = split( /\:/, $local );
		}
		$args->{local_host}=$ip;
		$args->{local_port}=$port;

		push( @nc_objects, Net::Connection->new( $args ) );

		$line_int++;
	}

	return @nc_objects;
}

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-connection-lsof at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Connection-lsof>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Connection::lsof


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Connection-lsof>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Connection-lsof>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Net-Connection-lsof>

=item * Search CPAN

L<https://metacpan.org/release/Net-Connection-lsof>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2019 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Net::Connection::lsof