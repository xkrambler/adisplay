// ver si una variable está establecida
function isset(v) { return (typeof(v)!="undefined"?true:false); }

// volcar el árbol de una variable JavaScript
function adump(arr,level) {
	if (!level) level=0;
	var s="";
	var t=""; for (var j=0;j<level;j++) t+="\t";
	try {
		if (typeof(arr)=='object') {
			if (arr.nextSibling) return t+"{*}\n"; // NO devolver elementos internos del navegador
			for (var item in arr) {
				var value=arr[item];
				if (typeof(value)=='object') {
					var size=0; for (var none in value) size++;
					s+=t+'"' + item + '" = '+typeof(value)+'('+size+'):\n';
					s+=adump(value,level+1);
				} else {
					s+=t+'"' + item + '" = '+typeof(value)+'("' + value + '")\n';
				}
			}
		} else {
			s="("+typeof(arr)+") "+arr;
		}
	} catch(e) {}
	return s;
}

// devuelve las claves de un hash en un nuevo array
function array_keys(a) {
	var b=[];
	for (var i in a)
		b.push(i);
	return b;
}

// convierte un hash/array para devolver siempre un array
function array_values(h) {
	var a=[];
	for (var i in h) a.push(h[i]);
	return a;
}
