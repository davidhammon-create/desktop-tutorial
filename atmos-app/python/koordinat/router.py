"""ROUTER - Kaskade: Zwischenspeicher, Formel, billigstes Modell. Reihenfolge ist Kostenreihenfolge."""
from . import apireg
class Router:
    def __init__(self, db, vital):
        self.db, self.vital = db, vital
        self.cache, self.letzte, self.formeln = {}, {}, {}
        self.treffer, self.fehl = {}, {}
    def formel(self, faehigkeit, schluessel, fn):
        """fn() muss denselben Wert liefern wie der echte Aufruf, sonst wird sie verworfen."""
        self.formeln[(faehigkeit, schluessel)] = fn
        self.treffer[(faehigkeit, schluessel)] = 0
        self.fehl[(faehigkeit, schluessel)] = 0
    def route(self, faehigkeit, schluessel, rufe, einheiten=1.0, zweck=""):
        """rufe(name, einheiten) -> Ergebnis. Rueckgabe: (ergebnis, stufe)."""
        k = (faehigkeit, schluessel)
        if k in self.cache:
            return self.cache[k], 0
        if k in self.formeln:
            a = self.formeln[k]()
            if self.letzte.get(k) == a:
                self.cache[k] = a
            self.letzte[k] = a
            return a, 1
        ziel = apireg.waehle(self.db, faehigkeit)
        if not ziel or not apireg.verbrauch(self.db, self.vital, ziel["name"], einheiten, zweck)[0]:
            return None, 3
        a = rufe(ziel["name"], einheiten)
        if self.letzte.get(k) == a:
            self.cache[k] = a
        self.letzte[k] = a
        if k in self.formeln:
            if self.formeln[k]() == a:
                self.treffer[k] += 1
            else:
                self.fehl[k] += 1
                if self.fehl[k] >= 3:
                    del self.formeln[k]
        return a, 2
    def stand(self):
        return dict(cache=len(self.cache), formeln=len(self.formeln),
                    treffer=sum(self.treffer.values()), fehl=sum(self.fehl.values()))
