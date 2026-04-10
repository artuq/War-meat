## NarrativeData — teksty fabularnych dialogów
class_name NarrativeData
extends RefCounted


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
