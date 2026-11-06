#!/usr/bin/env python3
"""Régénère Data/quran.json, Data/hadith.json et Data/extra.json depuis les sources publiques.

Usage : python3 scripts/fetch_data.py [dossier_de_sortie]   (défaut : Data/)
Voir DATA_SOURCES.md pour les sources et licences. Data/context.json et Data/glossary.json
sont rédigés à la main et ne sont pas touchés.
"""
import json, re, sys, time, urllib.request
from pathlib import Path

OUT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parent.parent / "Data"
OUT.mkdir(parents=True, exist_ok=True)


def get(url):
    last = None
    for _ in range(4):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0", "Accept": "application/json"})
            return json.load(urllib.request.urlopen(req, timeout=60))
        except Exception as e:  # noqa
            last = e
            time.sleep(1.5)
    raise SystemExit(f"échec : {url} ({last})")


# --- Coran : texte arabe (Tanzil uthmani) + traduction Hamidullah, via alquran.cloud
ar = get("https://api.alquran.cloud/v1/quran/quran-uthmani")["data"]["surahs"]
fr = get("https://api.alquran.cloud/v1/quran/fr.hamidullah")["data"]["surahs"]
quran = []
for s, t in zip(ar, fr):
    ayahs = []
    for x, y in zip(s["ayahs"], t["ayahs"]):
        txt = x["text"].replace("﻿", "").strip()
        # alquran.cloud colle la basmala au verset 1 de chaque sourate (sauf 1 et 9) : on la retire,
        # l'app l'affiche séparément.
        if s["number"] not in (1, 9) and x["numberInSurah"] == 1:
            txt = " ".join(txt.split(" ")[4:])
        ayahs.append({"n": x["numberInSurah"], "ar": txt, "fr": y["text"], "j": x["juz"], "p": x["page"]})
    name = s["name"].split(" ", 1)
    quran.append({"n": s["number"], "ar": name[1] if len(name) > 1 else s["name"], "en": s["englishName"],
                  "tr": s["englishNameTranslation"], "type": s["revelationType"], "ayahs": ayahs})
(OUT / "quran.json").write_text(json.dumps(quran, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
print("quran.json", sum(len(s["ayahs"]) for s in quran), "versets")

# --- Hadiths : fawazahmed0/hadith-api
base = "https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/"
books = []
for cid, frn, arn in [("nawawi", "Les 40 hadiths de l’imam an-Nawawi", "الأربعون النووية"),
                      ("qudsi", "Les 40 hadiths qudsi", "الأحاديث القدسية")]:
    a = {h["hadithnumber"]: h["text"].strip() for h in get(f"{base}ara-{cid}.json")["hadiths"]}
    f = {h["hadithnumber"]: h["text"].strip() for h in get(f"{base}fra-{cid}.json")["hadiths"]}
    ids = sorted(set(a) | set(f))
    books.append({"id": cid, "fr": frn, "ar": arn,
                  "items": [{"n": int(i), "ar": a.get(i, ""), "fr": f.get(i, "")} for i in ids]})
(OUT / "hadith.json").write_text(json.dumps(books, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
print("hadith.json", [(b["id"], len(b["items"])) for b in books])

# --- Métadonnées (Quran.com) + traduction Montada et ses notes (QuranEnc)
chapters = get("https://api.quran.com/api/v4/chapters?language=fr")["chapters"]
meta = {c["id"]: {"fr": c["translated_name"]["name"], "place": c["revelation_place"], "order": c["revelation_order"]}
        for c in chapters}
notes, montada = {}, {}
for n in range(1, 115):
    for x in get(f"https://quranenc.com/api/v1/translation/sura/french_montada/{n}")["result"]:
        key = f"{n}:{int(x['aya'])}"
        montada[key] = re.sub(r"\s*\[\d+\]", "", x["translation"]).strip()
        foot = (x.get("footnotes") or "").strip()
        if foot:
            notes[key] = foot
(OUT / "extra.json").write_text(json.dumps({"meta": meta, "notes": notes, "montada": montada},
                                           ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
print("extra.json", len(montada), "versets,", len(notes), "notes")
