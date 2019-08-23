<?php

	header("Content-type: text/html; charset=UTF-8");

	error_reporting(E_ALL & ~E_NOTICE);

	function packetCRC($p) {
		return chr(
			ord($p[1]) ^
			ord($p[2]) ^
			ord($p[3]) ^
			ord($p[4]) ^
			ord($p[5]) ^
			ord($p[6]) ^
			ord($p[7]) ^
			0x40
		);
	}

	function decodePacket($p) {
		$a=Array();
		$a["time"]=microtime(true);
		$a["off"]=(ord($p[1])==0x80);
		$a["t1"]="";
		if (ord($p[3])==0xDC) $a["t1"]="LO";
		if (ord($p[3])==0xEF) $a["t1"]=19;
		if (ord($p[3])==0x86) $a["t1"]=21;
		if (ord($p[3])==0x9B) $a["t1"]=22;
		if (ord($p[3])==0x8F) $a["t1"]=23;
		if (ord($p[3])==0xE6) $a["t1"]=24;
		if (ord($p[3])==0xAD) $a["t1"]=25;
		if (ord($p[3])==0xFD) $a["t1"]=(ord($p[5]) & 0x4?26:16);
		if (ord($p[3])==0xC7) $a["t1"]=(ord($p[5]) & 0x4?27:17);
		if (ord($p[3])==0xBF) $a["t1"]=(ord($p[5]) & 0x4?(ord($p[5]) & 0x08?28:20):18);
		if (ord($p[3])==0xD0) $a["t1"]="HI";
		$a["t2"]="";
		if (ord($p[1])==0x1C) $a["t2"]="LO";
		if (ord($p[1])==0x2F) $a["t2"]=19;
		if (ord($p[1])==0x46) $a["t2"]=21;
		if (ord($p[1])==0x5B) $a["t2"]=22;
		if (ord($p[1])==0x4F) $a["t2"]=23;
		if (ord($p[1])==0x26) $a["t2"]=24;
		if (ord($p[1])==0x6D) $a["t2"]=25;
		if (ord($p[1])==0x3D) $a["t2"]=(ord($p[5]) & 0x10?26:16);
		if (ord($p[1])==0x07) $a["t2"]=(ord($p[5]) & 0x10?27:17);
		if (ord($p[1])==0x7F) $a["t2"]=(ord($p[5]) & 0x10?(ord($p[5]) & 0x20?28:20):18);
		if (ord($p[1])==0x10) $a["t2"]="HI";
		$a["fan"]=0;
		if ((ord($p[6]) & 0xF0) == 0xE0) $a["fan"]=1;
		if ((ord($p[6]) & 0xF0) == 0xD0) $a["fan"]=2;
		if ((ord($p[6]) & 0xF0) == 0xB0) $a["fan"]=3;
		if ((ord($p[6]) & 0xF0) == 0xC0) $a["fan"]=4;
		if ((ord($p[6]) & 0xF0) == 0xA0) $a["fan"]=5;
		if ((ord($p[6]) & 0xF0) == 0x90) $a["fan"]=6;
		if ((ord($p[6]) & 0xF0) == 0xF0) $a["fan"]=7;
		$a["acon"]=((ord($p[6]) & 0x0F) == 0x05);
		$a["acoff"]=((ord($p[6]) & 0x0F) == 0x06);
		$a["auto"]=((ord($p[6]) & 0x0F) == 0x00);
		$a["mode"]="";
		if (ord($p[7])==0xF8) $a["mode"]="FEET+DEFROST";
		if (ord($p[7])==0xB0) $a["mode"]="FEET";
		if (ord($p[7])==0xF4) $a["mode"]="FEET+FRONT";
		if (ord($p[7])==0xA4) $a["mode"]="FRONT";
		return $a;
	}

	function renderDisplayValue($e, $h) {
		return "<span".($e?" style='color:#F66;background:#800;'":"").">".$h."</span>";
	}

	function renderDisplay($capture, $a) {
		//echo $capture["fan"]."!=".$a["fan"]."<br>";
		echo "<div>"
			."<span class='LCD'>"
				.($a["off"]
					?"CLIMA OFF"
					:""
					.renderDisplayValue($capture["t1"]!=$a["t1"], $a["t1"]."<sup>".(is_numeric($a["t1"])?"o":"&nbsp;")."</sup>")." "
					.renderDisplayValue($capture["t2"]!=$a["t2"], $a["t2"]."<sup>".(is_numeric($a["t2"])?"o":"&nbsp;")."</sup>")." "
					.renderDisplayValue($capture["fan"]!=$a["fan"], str_repeat("<span style='color:#000;background:#FD4;'>❚</span>", $a["fan"]).str_repeat("❚", 7-$a["fan"]))
					.($a["acon"]?" ".renderDisplayValue(!$capture["acon"], "AC-ON"):"")
					.($a["acoff"]?" ".renderDisplayValue(!$capture["acoff"], "AC-OFF"):"")
					.($a["auto"]?" ".renderDisplayValue(!$capture["auto"], "AUTO"):"")
					.($a["mode"]?" MODO:".renderDisplayValue($capture["mode"]!=$a["mode"], $a["mode"]):"")
				)
			."</span>"
			."</div>"
		;
	}

	function tobin($p) {
		$b="";
		for ($i=0;$i<strlen($p);$i++) {
			$v=ord(substr($p,$i,1));
			$s=decbin($v);
			$b.=str_pad($s,8,"0",STR_PAD_LEFT)." ";
		}
		return trim($b);
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
			margin-top: 9px;
			margin-bottom: 3px;
		}
		a,
		a:link,
		a:visited {
			color: #046;
			text-decoration: none;
		}
		a:hover {
			text-decoration: underline;
		}
		.LCD {
			display: inline-block;
			color: #DDE;
			background: #222;
			padding: 4px 12px;
			border-radius: 4px;
			font-size: 28px;
			font-family: LCD, LLPixel, Fira Mono, Mono, Courier New, Courier;
		}

	</style>
</head>
<body>

	<h1>Accord Climatizador Decoder v4 (final)</h1>

	<?

		// cargar fichero de tramas
		$f=file("clima4.txt");
		$captures=Array();
		foreach ($f as $i=>$n) {
			$n=str_replace(array("\n","\r"),"",$n);
			if ($i%2) {
				$manual=strpos($c, "MANUAL");
				$captures[$c]=Array(
					"t1"=>substr($c, 0, 2),
					"t2"=>substr($c, 3, 2),
					"auto"=>(strpos($c, "AUTO")?true:false),
					"acoff"=>(strpos($c, "ACOFF")?true:false),
					"acon"=>(strpos($c, "ACON")?true:false),
					"fan"=>($manual?intval(substr($c, $manual+6, 1)):false),
					"capture"=>str_replace(array("CMD[SPI] DATA[","]"," "),"",$n),
				);
				foreach ($modes=Array("FEET+DEFROST","FEET+FRONT","FEET","FRONT") as $m)
					if (strpos($c, $m)) { $captures[$c]["mode"]=$m; break; }
			} else {
				$c=$n;
			}
		}

		// limitar vista
		//$only=Array("17 17 AUTO","LO 17 AUTO","LO 27 AUTO");
		if ($only) {
			$c=Array();
			foreach ($only as $n)
				$c[$n]=$captures[$n];
			$captures=$c;
		}

		// iterar todas las capturas
		foreach ($captures as $name=>$capture) {

			// mostrar nombre de captura seleciconada
			?><h2><?=$name?></h2><?

			// pasar captura hex a paquete bin
			$p=hex2bin($capture["capture"]);

			// calcular CRC
			$crc=packetCRC($p);

			// devolver captura
			$c=strtoupper(bin2hex($p));
			echo "<div style='position:absolute;'>";
			echo "&nbsp;&nbsp;&nbsp;";
			for ($i=0;$i<strlen($c);$i+=2)
				echo "<b style='color:#F30;background:#FF0;'>".substr($c,$i,2)."</b>"
						.($i==18?"":"<span style='visibility:hidden;'>000000&nbsp;</span>")
				;
			echo " CRC: <b>".strtoupper(bin2hex($crc))."</b> "
					.($p[9]==$crc?"<b style='color:#690;'>OK</b>":"<b style='color:#F44;'>ERROR</b>")
					."</div>"
			;

			// renderizar posiciones de los bits
			echo "<div style='color:#888;'>";
			for ($i=0;$i<10;$i++)
				echo $i."<span style='visibility:hidden;'>".str_repeat("0", 8-strlen($i))."&nbsp;</span>";
			echo "</div>";

			// renderizar bits del paquete
			echo "<div><b>".tobin($p)."</b></div>";

			// visualizar
			renderDisplay($capture, decodePacket($p));

		}

?></body>
</html>
