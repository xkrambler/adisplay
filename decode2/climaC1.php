<?

	header("Content-type: text/html; charset=UTF-8");
	
?><!doctype html>
<head>
	<title>Accord Display Climatizer BUS decode</title>
	<style>

		body {
			font-family: Dina, Pragmata, Courier;
			font-size: 14px;
		}
		h1,h2,h3,h4,h5,h6 {
			font-family: Arial;
			color: #089;
		}
		a {
			color: #046;
			text-decoration: none;
		}
		a:hover {
			text-decoration: underline;
		}
		
		.LCD {
			display:inline-block;
			color: #DDE;
			background: #222;
			padding: 8px 12px;
			border-radius: 4px;
			border: 2px solid #666;
			font-family: LCD, LLPixel, Mono, Courier New;
			font-size: 44px;
		}

	</style>
</head>
<body>
	<?
		
		$d=dir(".");
		while ($e=$d->read()) {
			if ($e=="." || $e==".." || is_dir($d->path.DIRECTORY_SEPARATOR.$e)) continue;
			if (substr($e,-4,4)==".csv") $captures[substr($e,0,-4)]=Array();
		}

		$invert=false;

		$captures=array_merge($captures,Array(
			"climaC1_23toHito22both"=>Array(
				"caption"=>"ACOFF 23 to Hi to 22",
				"ignore"=>9,
				"notes"=>Array(
					"23C - 73.4F",
					"24C - 75.2F",
					"25C - 77F",
					"26C - 78.8F",
					"27C - 80.6F",
					"28C - 80.6F",
					"MAX",
					"28C - 80.6F",
					"27C - 80.6F",
					"26C - 78.8F",
					"25C - 77F",
					"24C - 75.2F",
					"23C - 73.4F",
					"22C - 71.6F",
				),
			),
			"climaC2_22_ACOFF"=>Array("caption"=>"22C ACOFF"),
			"climaC3_23"=>Array("caption"=>"23C"),
			"climaC4_24"=>Array("caption"=>"24C"),
			"climaC5_22_24"=>Array("caption"=>"22C 24C"),
			"climaC6_24_22"=>Array("caption"=>"24C 22C","ignore"=>2),
			"climaC7_22_AUTO"=>Array("caption"=>"22C AUTO"),
			"climaC8_22_MANUAL_1"=>Array("caption"=>"","ignore"=>8),
			"climaC8_22_MANUAL_2"=>Array("caption"=>""),
			"climaC8_22_MANUAL_3"=>Array("caption"=>"","ignore"=>3),
			"climaC8_22_MANUAL_4"=>Array("caption"=>""),
			"climaC8_22_MANUAL_5"=>Array("caption"=>"","ignore"=>4),
			"climaC8_22_MANUAL_6"=>Array("caption"=>"","ignore"=>2),
			"climaC8_22_MANUAL_7MAX"=>Array("caption"=>"","ignore"=>9),
			"climaC9_22_RECIRCULACION"=>Array("caption"=>"","ignore"=>1),
			"climaC10_OFF"=>Array("caption"=>""),
			"climaC11_FRONT"=>Array("caption"=>"climaC11_FRONT AUTO"),
			"climaC11_REAR"=>Array("caption"=>"climaC11_REAR AUTO","ignore"=>3),
			"climaC12_AC_ON"=>Array("caption"=>"","ignore"=>1),
			"climaC13_MODE_1PIES_DESEPA"=>Array("caption"=>"","ignore"=>4),
			"climaC13_MODE_2PIES"=>Array("caption"=>"","ignore"=>2),
			"climaC13_MODE_3PIES_FRONT"=>Array("caption"=>"","ignore"=>3),
			"climaC13_MODE_4FRONT"=>Array("caption"=>""),
		));
		ksort($captures);
		
		// si no tengo captura, solicitar
		if (!$capture_id=$_REQUEST["c"]) {
			?><h2>Select capture</h2><?
			?><ul><?
			foreach ($captures as $capture_id=>$capture) {
				?><li><a href='?c=<?=$capture_id?>'><?=$capture_id?></a></li><?
			}
			?></ul><?
			return;
		}
		
		// obtener captura seleciconada
		$capture=$captures[$capture_id];
		//echo "<pre>";echo $capture_id."\n";print_r($capture);print_r($captures);exit;
		if (!$capture["caption"]) $capture["caption"]=$capture_id;
		
		?><h1><?=$capture["caption"]?></h1><?
		
		$f=file($capture_id.".csv");
		foreach ($f as $i=>$l)
			if ($i) {
				$v=explode(",",$l);
				$t=$v[0];
				$value=false;
				for ($j=2;$j<count($v);$j++)
					if (strlen($v[$j])) {
						$value=$v[$j];
						break;
					}
				$values[]=$value;
			}
		
		// descartar el número indicado
		if ($capture["ignore"]) for ($i=0;$i<$capture["ignore"];$i++) unset($values[$i]);
		$values=array_values($values);

		// invertir
		if ($invert) foreach ($values as $n=>$v) $values[$n]=255-$v;

		// packetizer
		$packetn=0;
		$packet="";
		$packets=Array();
		foreach ($values as $i=>$v) {
			$packet.=chr($v);
			if (!(($i+1)%10)) {
				$packetn++;
				if ($packet && $packets[count($packets)-1]!=$packet) $packets[]=$packet;
				$packetcount[$packet]++;
				$packet="";
			}
		}
		
		?><h2>Non-repetitive Packets</h2><?

		foreach ($packets as $packetn=>$packet) {
			for ($i=0;$i<strlen($packet);$i++) {
				$v=ord(substr($packet,$i,1));
				echo strtoupper(($v<0x10?"0":"").sprintf("%x",$v))." ";
			}
			echo " <span style='color:red;'>(".$packetcount[$packet]." times)</span> <span style='color:red;'>[".$capture["notes"][$packetn]."]</span><br>";
		}

		?><hr /><?

		echo ""
			."<div>"
			."0<span style='visibility:hidden;'>0000000&nbsp;</span>"
			."8<span style='visibility:hidden;'>0000000&nbsp;</span>"
			."16<span style='visibility:hidden;'>000000&nbsp;</span>"
			."24<span style='visibility:hidden;'>000000&nbsp;</span>"
			."32<span style='visibility:hidden;'>000000&nbsp;</span>"
			."40<span style='visibility:hidden;'>000000&nbsp;</span>"
			."48<span style='visibility:hidden;'>000000&nbsp;</span>"
			."56<span style='visibility:hidden;'>000000&nbsp;</span>"
			."64<span style='visibility:hidden;'>000000&nbsp;</span>"
			."72<span style='visibility:hidden;'>00000&nbsp;</span>"
			."79"
			."</div>"
		;
		foreach ($packets as $packetn=>$packet) {
			for ($i=0;$i<strlen($packet);$i++) {
				$v=ord(substr($packet,$i,1));
				$s=decbin($v);
				echo str_pad($s,8,"0",STR_PAD_LEFT)." ";
				//echo strtoupper(($v<0x10?"0":"").sprintf("%x",$v))." ";
				//echo chr($v)." ";
			}
			echo " <span style='color:red;'>(".$packetcount[$packet]." times)</span> <span style='color:red;'>[".$capture["notes"][$packetn]."]</span><br>";
			/*for ($i=0;$i<strlen($packet);$i++) {
				$v=ord(substr($packet,$i,1));
				echo "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;".strtoupper(($v<0x10?"0":"").sprintf("%x",$v))." ";
			}
			echo "<br>";*/

			// interpretación
			$display["off"]="";
			if (ord($packet[1])==0x80) $display["off"]=true;
			$display["t1"]="";
			if (ord($packet[3])==0xDC) $display["t1"]=1; // new
			if (ord($packet[3])==0xEF) $display["t1"]=19; // new
			if (ord($packet[3])==0x86) $display["t1"]=21; // new
			if (ord($packet[3])==0x9B) $display["t1"]=22;
			if (ord($packet[3])==0x8F) $display["t1"]=23;
			if (ord($packet[3])==0xE6) $display["t1"]=24;
			if (ord($packet[3])==0xAD) $display["t1"]=25;
			if (ord($packet[3])==0xFD) $display["t1"]=(ord($packet[5]) & 0x4?26:16);
			if (ord($packet[3])==0xC7) $display["t1"]=(ord($packet[5]) & 0x4?27:17);
			if (ord($packet[3])==0xBF) $display["t1"]=(ord($packet[5]) & 0x4?(ord($packet[5]) & 0x20?28:20):18);
			if (ord($packet[3])==0xD0) $display["t1"]=99;
			$display["t2"]="";
			if (ord($packet[1])==0x1C) $display["t2"]=1; // new
			if (ord($packet[1])==0x2F) $display["t2"]=19; // new
			if (ord($packet[1])==0x46) $display["t2"]=21; // new
			if (ord($packet[1])==0x5B) $display["t2"]=22;
			if (ord($packet[1])==0x4F) $display["t2"]=23;
			if (ord($packet[1])==0x26) $display["t2"]=24;
			if (ord($packet[1])==0x6D) $display["t2"]=25;
			if (ord($packet[1])==0x3D) $display["t2"]=(ord($packet[5]) & 0x10?26:16);
			if (ord($packet[1])==0x07) $display["t2"]=(ord($packet[5]) & 0x10?27:17);
			if (ord($packet[1])==0x7F) $display["t2"]=(ord($packet[5]) & 0x4?(ord($packet[5]) & 0x20?28:20):18);
			if (ord($packet[1])==0x10) $display["t2"]=99;
			$display["fan"]=0;
			if (ord($packet[6])==0xE0) $display["fan"]=1;
			if (ord($packet[6])==0xD0) $display["fan"]=2;
			if (ord($packet[6])==0xB0) $display["fan"]=3;
			if (ord($packet[6])==0xC8) $display["fan"]=4;
			if (ord($packet[6])==0xA8) $display["fan"]=5;
			if (ord($packet[6])==0x98) $display["fan"]=6;
			if (ord($packet[6])==0xF8) $display["fan"]=7;
			$display["ac_on"]=false;
			$display["ac_off"]=false;
			$display["auto"]=false;
			if ((ord($packet[6]) & 0x0F) == 0x05) $display["ac_on"]=true;
			if ((ord($packet[6]) & 0x0F) == 0x06) $display["ac_off"]=true;
			if ((ord($packet[6]) & 0x0F) == 0x00) $display["auto"]=true;
			$display["mode"]="";
			if (ord($packet[7])==0xF8) $display["mode"]="Feet+Windshield";
			if (ord($packet[7])==0xB0) $display["mode"]="Feet";
			if (ord($packet[7])==0xF4) $display["mode"]="Feet+Front";
			if (ord($packet[7])==0xA4) $display["mode"]="Front";
			echo ""
				."<span class='LCD'>"
					.($display["off"]
						?"CLIMA OFF"
						:$display["t1"]."<sup>o</sup>C ".$display["t2"]."<sup>o</sup>C "
						.str_repeat("<span style='color:#000;background:#FD4;'>❚</span>", $display["fan"]).str_repeat("❚", 7-$display["fan"])
						.($display["ac_on"]?" A/C-ON":"")
						.($display["ac_off"]?" A/C-OFF":"")
						.($display["auto"]?" AUTO":"")
						.($display["mode"]?" MODO:".$display["mode"]:"")
					)
				."</span>"
				."<br/>"
			;
		}

		?><h2>RAW Data</h2><?

		foreach ($values as $i=>$v) {
			echo strtoupper(($v<0x10?"0":"").sprintf("%x",$v))." ";
			if (!(($i+1)%10)) echo "<br>";
		}

?></body>
</html>