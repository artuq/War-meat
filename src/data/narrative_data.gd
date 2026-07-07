## NarrativeData — teksty fabularnych dialogów i cutscen
class_name NarrativeData
extends RefCounted

# ── Cutscenki fabularne ──────────────────────────────────────────────────────

static func get_cutscene(id: String) -> Dictionary:
	# Zwraca { "image": "res://...", "lines": [{speaker, text}, ...] }
	match id:
		"intro":
			return {
				"image": "res://assets/sprites/ui/cutscenes/cutscene_0_intro.jpg",
				"lines": [
					{"speaker": "", "text": "PLANETA KIEŁBASIANA. ROK 3042 PO UWĘDZENIU."},
					{"speaker": "KIEŁBASA ŚLĄSKA", "text": "Hm. To nie powinno tu być.", "sfx": "drill"},
					{"speaker": "", "text": "Ziemia drży. Alarm ogólny.", "sfx": "rumble"},
					{"speaker": "KOMUNIKAT", "text": "UWAGA. NIEZNANE OBIEKTY BIOLOGICZNE\nPENETRUJĄ POWIERZCHNIĘ W SEKTORACH 3, 7, 12 I 44.", "sfx": "alarm"},
				]
			}
		"after_wave_2":
			return {
				"image": "res://assets/sprites/ui/cutscenes/cutscene_1_report.jpg",
				"lines": [
					{"speaker": "GEN. FRANKFURTER", "text": "Pierwsze kontakty potwierdzone. Klasyfikacja: ŁAZIKI i SZTURMAKI. Cel: nas."},
					{"speaker": "DR. WEISSWURST", "text": "Generale... próbki tkanek wrogów są bardzo stare. Nie chodzi o lata. Chodzi o miliony lat.", "sfx": "radio_static"},
					{"speaker": "GEN. FRANKFURTER", "text": "Co pan mówi, doktorze?"},
				]
			}
		"after_boss_jungle":
			return {
				"image": "res://assets/sprites/ui/cutscenes/cutscene_2_petroglyphs.jpg",
				"lines": [
					{"speaker": "CHORIZO-6", "text": "Generale. Znalazłem petroglify pod korzeniami starego drzewa.", "sfx": "leaves", "music": "cave_ambient"},
					{"speaker": "", "text": "Na ścianie jaskini — wyryty w kamieniu obraz: wielkie kiełbasy walczą z tymi samymi istotami."},
					{"speaker": "CHORIZO-6", "text": "...To były dinozaury."},
				]
			}
		"after_wave_8":
			return {
				"image": "res://assets/sprites/ui/cutscenes/cutscene_3_ancient_truth.jpg",
				"lines": [
					{"speaker": "DR. WEISSWURST", "text": "Przebadałem próbki z monolitu. Pieczęć miała 64.7 miliona lat.", "music": "tense"},
					{"speaker": "DR. WEISSWURST", "text": "Ktoś — albo coś — CELOWO ją osłabił. Wiercenia Inżyniera to tylko spust."},
					{"speaker": "DR. WEISSWURST", "text": "Wielka Pożoga. Pierwsza wojna. Kiełbazaury wygrały. Ale Pożeracze... czekały. I uczyły się."},
					{"speaker": "KOMUNIKAT", "text": "NARUSZENIE SEKTORA BUNKIER WSCHODNI. POZIOM ZAGROŻENIA: KRYTYCZNY.", "sfx": "rumble"},
				]
			}
		"after_boss_desert":
			return {
				"image": "res://assets/sprites/ui/cutscenes/cutscene_4_tunnel_map.jpg",
				"lines": [
					{"speaker": "", "text": "\"Bóg Pustyni\" — obalony. Na jego ciele rytualny wzór: mapa podziemnych tuneli."},
					{"speaker": "BRATWURST", "text": "Generale. Czuję wibracje pod stopami. Niskie. Regularne. Jak... oddech."},
					{"speaker": "GEN. FRANKFURTER", "text": "Ile Pożeraczy wyszło na powierzchnię?"},
					{"speaker": "KOMPUTER", "text": "Szacunkowo: 12% kolonii."},
					{"speaker": "GEN. FRANKFURTER", "text": "To znaczy że 88% nadal jest pod ziemią."},
				]
			}
		"after_boss_desert":
			return {
				"image": "res://assets/sprites/ui/cutscenes/cutscene_4_tunnel_map.jpg",
				"lines": [
					{"speaker": "", "text": "\"Bóg Pustyni\" — obalony. Na jego ciele rytualny wzór: mapa podziemnych tuneli.", "sfx": "heartbeat"},
					{"speaker": "BRATWURST", "text": "Generale. Czuję wibracje pod stopami. Niskie. Regularne. Jak... oddech."},
					{"speaker": "GEN. FRANKFURTER", "text": "Ile Pożeraczy wyszło na powierzchnię?"},
					{"speaker": "KOMPUTER", "text": "Szacunkowo: 12% kolonii."},
					{"speaker": "GEN. FRANKFURTER", "text": "To znaczy że 88% nadal jest pod ziemią.", "sfx": "rumble"},
				]
			}
		"before_boss_bunker":
			return {
				"image": "res://assets/sprites/ui/cutscenes/cutscene_5_final_broadcast.jpg",
				"lines": [
					{"speaker": "GEN. FRANKFURTER", "text": "Obywatele Kiełbasiany. 64 miliony lat temu Kiełbazaury stoczyły tę samą wojnę. Wygrały.", "music": "march"},
					{"speaker": "GEN. FRANKFURTER", "text": "Nie wystarczyło. Ale dzisiaj wiemy: nie wystarczy zamknąć. Trzeba skończyć."},
					{"speaker": "", "text": "Całe siły Kiełbasiany schodzą do podziemi. Raz ostatni.", "sfx": "march_drums"},
				]
			}
		"victory":
			return {
				"image": "res://assets/sprites/ui/cutscenes/cutscene_6_victory.jpg",
				"lines": [
					{"speaker": "", "text": "Królowa Pożeraczy — martwa. Kolonia dezorientuje się. Wycofuje.", "music": "victory_end"},
					{"speaker": "DR. WEISSWURST", "text": "To koniec?"},
					{"speaker": "GEN. FRANKFURTER", "text": "Kiełbazaury też myślały, że to koniec."},
					{"speaker": "CHORIZO-6", "text": "Więc co robimy?"},
					{"speaker": "GEN. FRANKFURTER", "text": "Budujemy lepszą Pieczęć. I tym razem — nie zapominamy."},
				]
			}
	return {}


static func get_briefing(arena_id: String) -> Array[Dictionary]:
	match arena_id:
		"jungle":
			return [
				{"speaker": "🎖️", "text": "Oddział, wchodzimy w dżunglę. Zwiad donosi o dużej aktywności wrogów."},
				{"speaker": "🎖️", "text": "Przetrwajcie 5 fal. Spodziewajcie się szybkich ataków z każdej strony."},
			]
		"desert":
			return [
				{"speaker": "🎖️", "text": "Pustynia. Zero osłon, pełna ekspozycja. Wróg ma przewagę zasięgu."},
				{"speaker": "🎖️", "text": "Trzymajcie się razem. Piasek spowalnia, ale nie poddawajcie się."},
			]
		"bunker":
			return [
				{"speaker": "🎖️", "text": "Stary bunkier wroga. Ciasne korytarze, beczki z materiałami wybuchowymi."},
				{"speaker": "🎖️", "text": "Uważajcie na eksplozje. Ciężka piechota czeka w środku. Powodzenia."},
			]
	return []


static func get_boss_dialog(arena_id: String) -> Array[Dictionary]:
	match arena_id:
		"jungle":
			return [
				{"speaker": "🎖️", "text": "Boss pokonany! Dżungla jest nasza."},
				{"speaker": "📡", "text": "Przechwycono sygnał z pustyni. Nowe współrzędne odblokowane."},
				{"speaker": "🎖️", "text": "Dopiero zaczynamy, żołnierze. Zbierajcie surowce i ruszamy dalej."},
			]
		"desert":
			return [
				{"speaker": "🎖️", "text": "Snajper wyeliminowany. Pustynia pod kontrolą."},
				{"speaker": "📡", "text": "Namierzono podziemny bunkier wroga. To ich ostatnia baza."},
				{"speaker": "🎖️", "text": "Przygotujcie się na najtrudniejszą walkę. Zbierzcie co możecie."},
			]
		"bunker":
			return [
				{"speaker": "🎖️", "text": "ZWYCIĘSTWO! Bunkier zdobyty. Wróg całkowicie rozbity!"},
				{"speaker": "📡", "text": "Wszystkie bazy wroga zneutralizowane. Operacja zakończona."},
				{"speaker": "🎖️", "text": "Dobra robota, oddział WAR MEAT. Wracamy do domu."},
				{"speaker": "🥩", "text": "...ale mięso wojny nigdy nie kończy się naprawdę."},
			]
	return []
