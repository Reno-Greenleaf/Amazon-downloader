#!/usr/bin/perl

# Amazon reviews downloader
# Copyright (C) 2015  Andrea Esuli
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# usage: ./downloadAmazonReviews.pl <domain> <list of IDs of amazon products>
# example: ./downloadAmazonReviews.pl com B0040JHVC2 B004CG4CN4
# output: a directory ./amazonreviews/<domain>/<ID> is created for each product ID; HTML files containing reviews are downloaded and saved in each directory.

use strict;
use LWP::UserAgent; 
use HTTP::Request;

$| = 1; #autoflush

my $ua = LWP::UserAgent->new;
$ua->timeout(10);
$ua->env_proxy;
$ua->agent('Mozilla/5.0 (X11; Linux i686) AppleWebKit/534.30 (KHTML, like Gecko) Ubuntu/11.04 Chromium/12.0.742.91 Chrome/12.0.742.91 Safari/534.30');

mkdir "amazonreviews";

my $sleepTime = 1;

my $domain = shift;
mkdir "amazonreviews/$domain";

my $id = "";
while($id = shift) { # loop over product IDs.

	my $dir = "amazonreviews/$domain/$id";
	mkdir $dir;

	my $urlPart1 = "http://www.amazon.".$domain."/product-reviews/";
	my $urlPart2 = "/?ie=UTF8&showViewpoints=0&pageNumber=";
	my $urlPart3 = "&sortBy=bySubmissionDateDescending";

	my $referer = $urlPart1.$id.$urlPart2."1".$urlPart3;

	my $page = 1;
	my $lastPage = 1;

	while($page<=$lastPage) {

		if ($page == $lastPage && $page == 1) {
			print "Getting first page of product $id\t";
		}
		else {
			print "Getting page $page/$lastPage of product $id\t";
		}

		my $url = $urlPart1.$id.$urlPart2.$page.$urlPart3;

		my $request = HTTP::Request->new(GET => $url);
		$request->referer($referer);

		my $response = $ua->request($request);

		if(contentObtained($response)) {
			print "Saving HTML\t";
			my $content = $response->decoded_content;

			while($content =~ m#cm_cr_arp_d_paging_btm_(\d+)#gs ) {
				my $val = $1+0;

				if($val>$lastPage) {
					$lastPage = $val;
				}

			}
		
			if(open(CONTENTFILE, ">./$dir/$page")) {
				binmode(CONTENTFILE, ":utf8");
				print CONTENTFILE $content;
				close(CONTENTFILE);
				print "Saved\n";
			}
			else {
				print "Can't save!\n";
			}
		
			if ($sleepTime > 7) {
				$sleepTime -= 4;
			}
			elsif ($sleepTime > 60) { # too big
				$sleepTime = 10;
			}

		}
		else {
			--$page;
			++$sleepTime;
			print "Retrying (new timeout $sleepTime)…\n";
		}

		++$page;
		sleep($sleepTime);
	}
}

sub contentObtained {
	my $response = $_[0];

	if ($response->is_success) {
		my $content = $response->decoded_content;

		if ($content =~ /action="\/errors\/validateCaptcha"/) {
			print "CAPTCHA!\t";
		}

		return $content !~ /action="\/errors\/validateCaptcha"/
	}
	else {
		print "Error " . $response->code ."\t";
		return $response->is_success;
	}

}
