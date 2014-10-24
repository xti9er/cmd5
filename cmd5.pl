#!/usr/bin/perl -w
#by Xti9er
use LWP::UserAgent;
use Parallel::ForkManager;
use Encode;
use Data::Dumper;

$|=1;
my $version=2010112901;
print "\t\t\tMd5 Web Decrypter
\t\t\t\tby Xti9er
".'-'x75,"\n";
my $getmd5=shift||die 'no md5 str';

my $stime=time;
print "[Get] $getmd5\n";
my $scount=0;
if(-f $getmd5){
	open(MD5F,$getmd5) or die $!;
	open(MD5RE,"+>>$getmd5.log") or die $!;
	while(my $nowstr=<MD5RE>){
		chomp($nowstr);
		$scount++;
		my $nsinfo="\n[Search $scount] $nowstr\tResult:[";
		my $nre=webmd5($nowstr);
		$nsinfo.=$nre;
		$nsinfo.="]\n";
		print $nsinfo;
		print MD5RE $nsinfo if $nre;
	}	
	close MD5F;
	close MD5RE;
}
else{
#		my $nsinfo="[Search] $getmd5\tResult:[";
		webmd5($getmd5);
#		$nsinfo.="]\n";
#		print $nsinfo;
}

my $etime=time;

print "[*] All done at ".($etime-$stime)." seconds\n";

sub webmd5{
	my $md5str=shift;
	my($domain,$gurl,$Method,$referer,$PostData,$Searchstring1,$Searchstring2,$Enabled,@siteinfo);
	open(F,'cracker.ini') or die $!;
	while(my $nline=<F>){
		chomp($nline);
		if($nline=~/^\[(.*)\]$/){$domain=$1;}
		if($nline=~/^URL=(.*)/){$gurl=$1;$gurl=~s/\[HASH\]/$md5str/g}
		if($nline=~/^Method=(.*)/){$Method=$1;}
		if($nline=~/^Referer=(.*)/){$referer=$1;}
		if($nline=~/^PostData=(.*)/){$PostData=$1;$PostData=~s/\[HASH\]/$md5str/g}
		if($nline=~/^Searchstring1=(.*)/){$Searchstring1=$1;}
		if($nline=~/^Searchstring2=(.*)/){$Searchstring2=$1;}
		if($nline=~/^Enabled=(\d)/){
			$Enabled=$1;
			push(@siteinfo,"$domain|$gurl|$Method|$referer|$PostData|$Searchstring1|$Searchstring2|$Enabled");
		}
	}
	
	my $siteno=0;
	
	my $pm = new Parallel::ForkManager(30); 
	for(@siteinfo){
		chomp($_);
		$siteno++;
		my @nsite=split(/\|/,$_);
		
=cut
		print  $siteno%2?"+":"x";
		my $md5text=rmd5(@nsite);
		if($md5text){
			print "\b";
			return $md5text;
			last;
		}
		else{print "\b";}
=cut
		$pm->start and next;
		my $md5text=rmd5(@nsite);
		print "$nsite[0] result:[$md5text]\n";
		$pm->finish;	
		
		
	}
	$pm->wait_all_children;
	
	
	
	sub rmd5{
		my($domain,$gurl,$Method,$referer,$PostData,$Searchstring1,$Searchstring2,$Enabled)=@_;
		my $ua = LWP::UserAgent->new;
		$ua->timeout(10);
		$ua->env_proxy;
		$ua->agent('Mozilla/5.0');
		$ua->default_header('Accept-Encoding' => 'compress');
		$ua->default_header('Accept-Language' => "utf8");
		if($Method eq "GET"){
			my $response=$ua->get($gurl);
			return pstr($domain,$response,$Searchstring1,$Searchstring2);
		}
		if($Method eq "POST"){
			my $response=$ua->post($gurl,Content => $PostData);	
			#print Dumper($response);
			return pstr($domain,$response,$Searchstring1,$Searchstring2);
		}
	}
	
	sub pstr{
		my ($domain,$res,$Searchstring1,$Searchstring2)=@_;
		if ($res->is_success) {
			my $content=$res->content;
			encode('utf-8',decode("utf-8",$content));
			if($content=~/.*$Searchstring1(.*)$Searchstring2.*/){return $1;}	
		}			
	}
}
