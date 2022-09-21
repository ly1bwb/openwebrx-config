
         var hamlib_settings = {
           "async": true,
           "crossDomain": true,
//           "url": "http://sdr.vhf.lt:8073/static/rotator.json",
           "url": "/static/rotator.json",
           "method": "GET",
	    "cache" : false
         }
	function updateRotatorInfo(){
	    $.ajax(hamlib_settings).done(function (response) {
        	console.log(response);
        	var azimuth = response.azimuth;
		var elevation = response.elevation;
    		    document.getElementById("rotator-azimuth").innerHTML = azimuth
    		    document.getElementById("rotator-elevation").innerHTML = elevation
//        	$("#rotator-azimuth").append(azimuth);
//        	$("#rotator-elevation").append(elevation);
	    });
	};

    $(document).ready(function(){
	var rotatorUpdateTimer = setInterval(updateRotatorInfo, 5000);
//	updateRotatorInfo();
});
