					/*
						var _spis=[
							"80 5B 1B 9B 9B BF 80 C2 80 FD",
							"80 46 1B 86 9B 97 80 C2 80 D5",
							"80 7F 1B BF 9B 97 80 C2 80 D5",
							"80 2F 06 EF 86 AB 80 C2 80 E9",
							"80 7F 06 BF 86 AB 80 C2 80 E9",
							"80 07 06 C7 86 83 80 C2 80 C1",
							"80 3D 06 FD 86 AB 80 C2 80 E9",
							"80 1C 78 DC F8 AB 80 C2 80 E9",
							"80 3D 06 DC F8 AB 80 C2 80 B6",
							"80 07 06 DC F8 CB 80 C2 80 EC",
							"80 7F 06 DC F8 AB 80 C2 80 F4",
							"80 2F 06 DC F8 AB 80 C2 80 A4",
							"80 7F 1B DC F8 9B 80 C2 80 D9",
							"80 46 1B DC F8 9B 80 C2 80 E0",
							"80 5B 1B DC F8 FB 80 C2 80 9D",
							"80 4F 1B DC F8 FB 80 C2 80 89",
							"80 26 1B DC F8 FB 80 C2 80 E0",
							"80 6D 1B DC F8 FB 80 C2 80 AB",
							"80 3D 1B DC F8 FB 80 C2 80 FB",
							"80 07 1B DC F8 9B 80 C2 80 A1",
							"80 7F 1B DC F8 FB 80 C2 80 B9",
							"80 26 1B 9B 9B BF 80 C2 80 80",
							"80 5B 1B E6 9B BF 80 C2 80 80",
							"80 5B 1B E6 9B BF 86 80 80 C4",
							"80 26 1B 9B 9B BF 86 80 80 C4",
							"80 5B 1B 9B 9B BF E6 80 80 D9",
							"80 5B 1B 9B 9B BF D6 80 80 E9",
							"80 5B 1B 9B 9B BF B6 80 80 89",
							"80 5B 1B 9B 9B BF CE 80 80 F1",
							"80 5B 1B 9B 9B BF AE 80 80 91",
							"80 5B 1B 9B 9B BF 9E 80 80 A1",
							"80 5B 1B 9B 9B BF FE 80 80 C1",
							"80 4F 1B 86 9B F7 B6 80 80 C8",
							"80 4F 1B 86 9B F7 B5 80 80 CB",
							"80 2F 06 BF 9B A7 B5 80 80 DF",
							"80 2F 06 BF 86 AB B5 80 80 CE",
							"80 2F 06 BF 9B EF B5 80 80 97",
							"80 5B 1B 9B 9B BF 80 B0 80 8F",
							"80 5B 1B 9B 9B BF 80 F8 80 C7",
							"80 5B 1B 9B 9B BF 80 F4 80 CB",
							"80 5B 1B 9B 9B BF 80 A4 80 9B",
							"80 1C 78 DC F8 AB 86 80 80 AD",
							"80 3D 06 FD 86 AB 86 80 80 AD",
							"80 07 06 C7 86 83 86 80 80 85",
							"80 7F 06 BF 86 AB 86 80 80 AD",
							"80 2F 06 EF 86 AB 86 80 80 AD",
							"80 7F 1B BF 9B 97 86 80 80 91",
							"80 46 1B 86 9B 97 86 80 80 91",
							"80 5B 1B 9B 9B BF 86 80 80 B9",
							"80 4F 1B 8F 9B BF 86 80 80 B9",
							"80 26 1B E6 9B BF 86 80 80 B9",
							"80 6D 1B AD 9B BF 86 80 80 B9",
							"80 3D 1B FD 9B BF 86 80 80 B9",
							"80 07 1B C7 9B 97 86 80 80 91",
							"80 7F 1B BF 9B BF 86 80 80 B9",
							"80 10 36 D0 B6 97 86 80 80 91",
						];
						self._spi_a=(isset(self._spi_a)?(self._spi_a+1)%_spis.length:0);
						//lib.echo(_spis[self._spi_a]+"\n");
					*/
					self.decodeSPI(self.decodeHex(_spis[self._spi_a]));