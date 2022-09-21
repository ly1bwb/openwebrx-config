#!/usr/bin/perl
#
# Script gets data form mqtt server and generates rotator.json file. For use with modified OpenWebRX
# Vilius LY3FF, 2021
#
# mqttrig service must be running
#
use strict;
#use warnings;

use lib '.';

use Net::MQTT::Simple;

# mosquitto server
my $mqtt_host = "mqtt.vurk";
my $output_file = "rotator.json";
my $output_interval = 10;	# in seconds

my $old_azimuth;
my $old_elevation;

# MQTT topikai
my $radio_topic_path="VURK/radio/FT847/";
my $rotator_topic_path="VURK/rotator/vhf/";

# rigctl -h
my $radio_type = 2; 			# 2 - network
my $radio_path = "127.0.0.1:4532"; 	# path or host

#rotctl -h
my $rotator_type = 2; 			# 2 - network
my $rotator_path = "127.0.0.1:4533"; 	# path or host

# limits for set command
my $min_azimuth = 0;
my $max_azimuth = 360;

my $min_elevation = 0;
my $max_elevation = 90;

my $loop = 1;
my $rig_update_interval = 5; # in seconds
my $rot_update_interval = 2; # in seconds
my $print_interval      = 1; # print stats every n seconds

# do not output anything - for use as a service
my $quiet = 1; 
my $is_a_service = 0; # die if something disconnects

my $rig_in_use = 1;
my $rot_in_use = 1;

if ($radio_type   < 1) {$rig_in_use = 0;}
if ($rotator_type < 1) {$rot_in_use = 0;}

if ($rig_in_use == 0 && $rot_in_use == 0){
    die "no point to continue when rig and rotator is not in use";
}

my $mqtt = Net::MQTT::Simple->new($mqtt_host);


$SIG{INT} = sub { 
    print "interrupted..\n";
    exit 0;
};

my ($freq, $mode, $passband, $ptt, $azimuth, $elevation, $direction);
my $rotator_connected = 0;
my $rig_connected 	  = 0;
my $counter=0;

# subscribe to "set" topic
$mqtt->subscribe($rotator_topic_path . "azimuth",  \&set_azimuth);
$mqtt->subscribe($rotator_topic_path . "elevation", \&set_elevation);

while($loop){
    $counter++;
    $mqtt->tick();	# check if there are waiting subscribed messages 


    if (!$quiet && ($counter % $print_interval == 0)) {
        print "Connection states:\n";
	print "Azimuth/el    : $azimuth ($direction) / $elevation\n";
    }

    if (($counter % $output_interval == 0) && (($azimuth ne $old_azimuth ) || ($elevation ne $old_elevation))){ 	#generate json file, write only if smth changed
	my $timestamp = time;
	open (OUTPUT, ">", $output_file) or die "can't open $output_file for writing";
	print OUTPUT 
"{
    \"name\": \"vhf\",
    \"azimuth\": \"$azimuth\",
    \"elevation\": \"$elevation\",
    \"timestamp\": \"$timestamp\"
}
";
	close OUTPUT;
	$old_azimuth = $azimuth;
	$old_elevation = $elevation;
	if ($quiet == 0) {print "updating\n";}
    }

sleep 1;
}


exit;

#{
#    "name": "vhf",
#    "azimuth": 224,
#    "elevation": 0,
#    "timestamp": "2021-06-16T12:01:23"
#}



#
# Functions

sub set_azimuth{
    my ($topic, $message) = @_;
#    print "$topic: $message\n";
    $azimuth=$message;
}

sub set_elevation{
    my ($topic, $message) = @_;
#    print "$topic: $message\n";
    $elevation=$message;
}

# simple azimuth to direction conversion
sub azimuth_to_direction{
    my $angle = shift;
    my @angles=    (  0,   45,  90,  135, 180,  225, 270,  315, 360);
    my $puse  =  ($angles[1] / 2);
    my @directions=("N", "NE", "E", "SE", "S", "SW", "W", "NW", "N");
    my $direction;
    for (my $i = 0; $i<@angles; $i++){
	if (($angle >= ($angles[$i] - $puse) ) && ( $angle <= ($angles[$i] + $puse) )) { $direction = $directions[$i]; last}
    }
    return $direction;
}



sub test_directions{
    my $step=shift;
    if ($step == 0) {$step =1};
    for (my $i = 0; $i <= 360; $i+=$step){
        my $n = $i;
        my $dir = &azimuth_to_direction($n);
        print "$n \t= ". $dir . "\n";
    }
}
