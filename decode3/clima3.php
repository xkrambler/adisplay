<?php

	header("Content-type: text/html; charset=UTF-8");

	error_reporting(E_ALL & ~E_NOTICE);

	function tobin($p) {
		for ($i=0;$i<strlen($p);$i++) {
			$v=ord(substr($p,$i,1));
			$s=decbin($v);
			echo str_pad($s,8,"0",STR_PAD_LEFT)." ";
		}
	}

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

		$capture=$_REQUEST["c"];
		$name=$_REQUEST["n"];

		// si no tengo captura, solicitar
		if (!$capture) {

			$captures=Array();
			$f=file("clima3.txt");
			foreach ($f as $i=>$n) {
				$n=str_replace(array("\n","\r"),"",$n);
				if ($i%2) $captures[$c]=str_replace(array("CMD[SPI] DATA[","]"," "),"",$n);
				else $c=$n;
			}
			
			?><h2>Select SPI capture</h2><?
			?><ul><?
			foreach ($captures as $n=>$c) {
				?><li><a href='?c=<?=$c?>&amp;n=<?=urlencode($n)?>'><?=$n?></a></li><?
				?><li><?=tobin(hex2bin($c))?></li><?
			}
			?></ul><?
			return;
		}
		
		// mostrar nombre de captura seleciconada
		?><h1><?=($name?$name:"Captura")?></h1><?

		// pasar captura hex a paquete bin
		$p=hex2bin($capture);

		// devolver captura
		$c=strtoupper(bin2hex($p));
		for ($i=0;$i<strlen($c);$i+=2)
			echo substr($c,$i,2)." ";
		
		?><hr style='height:2px;border:0;background:#5AA;' /><?

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
		for ($i=0;$i<strlen($p);$i++) {
			$v=ord(substr($p,$i,1));
			$s=decbin($v);
			echo str_pad($s,8,"0",STR_PAD_LEFT)." ";
			//echo strtoupper(($v<0x10?"0":"").sprintf("%x",$v))." ";
			//echo chr($v)." ";
		}

		// interpretación
		$a["off"]="";
		if (ord($p[1])==0x80) $a["off"]=true;
		$a["t1"]="";
		if (ord($p[3])==0xDC) $a["t1"]=1; // new
		if (ord($p[3])==0xEF) $a["t1"]=19; // new
		if (ord($p[3])==0x86) $a["t1"]=21; // new
		if (ord($p[3])==0x9B) $a["t1"]=22;
		if (ord($p[3])==0x8F) $a["t1"]=23;
		if (ord($p[3])==0xE6) $a["t1"]=24;
		if (ord($p[3])==0xAD) $a["t1"]=25;
		if (ord($p[3])==0xFD) $a["t1"]=(ord($p[4]) & 0x4?26:16);
		if (ord($p[3])==0xC7) $a["t1"]=(ord($p[4]) & 0x4?27:17);
		if (ord($p[3])==0xBF) $a["t1"]=(ord($p[4]) & 0x1?(ord($p[5]) & 0x40?28:20):18);
		//if (ord($p[3])==0xBF) $a["t1"]=(ord($p[5]) & 0x4?20:18);
		if (ord($p[3])==0xD0) $a["t1"]=99;
		$a["t2"]="";
		if (ord($p[1])==0x1C) $a["t2"]=1; // new
		if (ord($p[1])==0x2F) $a["t2"]=19; // new
		if (ord($p[1])==0x46) $a["t2"]=21; // new
		if (ord($p[1])==0x5B) $a["t2"]=22;
		if (ord($p[1])==0x4F) $a["t2"]=23;
		if (ord($p[1])==0x26) $a["t2"]=24;
		if (ord($p[1])==0x6D) $a["t2"]=25;
		if (ord($p[1])==0x3D) $a["t2"]=(ord($p[5]) & 0x10?26:16);
		if (ord($p[1])==0x07) $a["t2"]=(ord($p[5]) & 0x10?27:17);
		if (ord($p[1])==0x7F) $a["t2"]=(ord($p[5]) & 0x4?20:(ord($p[5]) & 0x10?28:18));
			//(ord($p[5]) & 0x4?(ord($p[5]) & 0x20?28:20):18);
		if (ord($p[1])==0x10) $a["t2"]=99;
		$a["fan"]=0;
		if (ord($p[6])==0xE0) $a["fan"]=1;
		if (ord($p[6])==0xD0) $a["fan"]=2;
		if (ord($p[6])==0xB0) $a["fan"]=3;
		if (ord($p[6])==0xC8) $a["fan"]=4;
		if (ord($p[6])==0xA8) $a["fan"]=5;
		if (ord($p[6])==0x98) $a["fan"]=6;
		if (ord($p[6])==0xF8) $a["fan"]=7;
		$a["ac_on"]=false;
		$a["ac_off"]=false;
		$a["auto"]=false;
		if ((ord($p[6]) & 0x0F) == 0x05) $a["ac_on"]=true;
		if ((ord($p[6]) & 0x0F) == 0x06) $a["ac_off"]=true;
		if ((ord($p[6]) & 0x0F) == 0x00) $a["auto"]=true;
		$a["mode"]="";
		if (ord($p[7])==0xF8) $a["mode"]="Feet+Windshield";
		if (ord($p[7])==0xB0) $a["mode"]="Feet";
		if (ord($p[7])==0xF4) $a["mode"]="Feet+Front";
		if (ord($p[7])==0xA4) $a["mode"]="Front";
		echo "<div>"
			."<span class='LCD'>"
				.($a["off"]
					?"CLIMA OFF"
					:$a["t1"]."<sup>o</sup>C ".$a["t2"]."<sup>o</sup>C "
					.str_repeat("<span style='color:#000;background:#FD4;'>❚</span>", $a["fan"]).str_repeat("❚", 7-$a["fan"])
					.($a["ac_on"]?" A/C-ON":"")
					.($a["ac_off"]?" A/C-OFF":"")
					.($a["auto"]?" AUTO":"")
					.($a["mode"]?" MODO:".$a["mode"]:"")
				)
			."</span>"
			."</div>"
		;

?></body>
</html>
