#!/usr/bin/perl
# tcx2csv.pl Data.tcx | sort > RunningData.csv
#
# GarminのtcxファイルからLap毎のデータをSTDOUTにCSVデータとして書き出す
# LapID, TotalTimeSeconds, DistanceMeters, AverageHeartRateBpm, AvgSpeed, AvgRunCadence
# ID     時間(秒)          距離(m)         平均心拍数(bpm)      平均ペース ステップ
#
# manontanto
# 2016-08-03
# 2017-4-30($spd km/hを書き出す追加)
# 2020-4-12(push to github)

use strict;
my $arg = @ARGV;
my $usage = "Usage: ./tcx2csv.pl DataFile.tcx";
my $fh;
my ($all_data, $element) = "";
my @running;
my ($Id, $Ttime, $Dmeter, $Hr, $Pace, $Step) = "";
die "$usage\n" if ($arg != 1);
open($fh, "<$ARGV[0]") || die "Can't open file.\n$usage\n";

sub delete_element {
# エレメントを削除する
	my $string = shift;
	my $tag = shift;

	$string =~ s|\t* *<$tag.+?/$tag>.||sg;
	return $string;
}

sub extract_element {
# エレメントを抜き出す
	my $string = shift;
	my $tag = shift;
	my @list;
	my $etag = $tag =~ /(.+) .+/ ? $1 : $tag;
	@list = $string =~ m|\t* *<$tag.+?/$etag>|smg;
	return @list;
}

while(<$fh>) {
    $all_data .= $_;
}
$all_data = delete_element($all_data, "Track");
@running = extract_element($all_data, 'Activity Sport="Running"');
foreach $element ( extract_element( join("",@running), "Lap") ) {
#$Id, $Ttime, $Dmeter, $Hr, $spd, $Pace, $Step
	$Id = $1 if $element =~ /Lap StartTime="(.+Z)">/;
	$Ttime = sprintf("%d", $1 + 0.5) if $element =~ /TotalTimeSeconds>(.+)</;
	$Dmeter = sprintf("%d", $1 + 0.5) if $element =~ /DistanceMeters>(.+)</;
	$Hr = $1 if $element =~ m|<AverageHeartRateBpm .+?<Value>(.+?)</Value>|smg;
	my $spd = $1 * 3.6 if $element =~ /AvgSpeed>(.+)</;
	my ($sec, $min) = gmtime(1 / $spd * 1000);
	$Pace = sprintf("00:%02d:%02d",$min,$sec);
	$Step = $1 * 2 if $element =~ /AvgRunCadence>(.+)</;
	print "$Id,$Ttime,$Dmeter,$Hr,$spd,$Pace,$Step\n";
}
close($fh);

