#!/usr/bin/env python3
import ijson, json, csv, sys, time
from pathlib import Path

def sanitize(text: str) -> str:
    return text.replace(',', ' ').replace('\t',' ').replace('\n',' ').strip()

def main():
    if len(sys.argv) < 3 or len(sys.argv) > 4:
        print("Usage: python to_tsvs_from_json.py <input.json> <team_name> [MAX_N]")
        sys.exit(1)

    in_path = Path(sys.argv[1])
    team    = sys.argv[2]
    max_n   = int(sys.argv[3]) if len(sys.argv)==4 else None
    out_dir = in_path.parent

    art_tsv      = out_dir / "articles.tsv"
    auth_tsv     = out_dir / "authors.tsv"
    authored_tsv = out_dir / "authored.tsv"
    cites_tsv    = out_dir / "cites.tsv"

    authors = {}
    count = 0
    start = time.time()

    with open(art_tsv,      "w", newline="", encoding="utf-8") as f_art, \
         open(authored_tsv, "w", newline="", encoding="utf-8") as f_au, \
         open(cites_tsv,    "w", newline="", encoding="utf-8") as f_cite:

        art_writer  = csv.writer(f_art,      delimiter="\t", quoting=csv.QUOTE_NONE, escapechar="\\")
        au_writer   = csv.writer(f_au,       delimiter="\t", quoting=csv.QUOTE_NONE, escapechar="\\")
        cite_writer = csv.writer(f_cite,     delimiter="\t", quoting=csv.QUOTE_NONE, escapechar="\\")

        art_writer.writerow(["_id","title"])
        au_writer.writerow(["author_id","article_id"])
        cite_writer.writerow(["article_id","reference_id"])

        with open(in_path, "r", encoding="utf-8", errors="ignore") as f_in:
            for rec in ijson.items(f_in, 'item'):
                aid = rec.get("id") or rec.get("_id", "")
                if not aid:
                    continue

                art_writer.writerow([aid, sanitize(rec.get("title",""))])

                for a in rec.get("authors", []):
                    auth_id = a.get("id") or a.get("_id", "")
                    if not auth_id:
                        continue
                    authors[auth_id] = sanitize(a.get("name",""))
                    au_writer.writerow([auth_id, aid])

                for ref in rec.get("references", []):
                    cite_writer.writerow([aid, ref])

                count += 1
                if count % 100 == 0:
                    print(f"Processed {count} records in {(time.time()-start):.1f}s")
                if max_n and count >= max_n:
                    print(f"Reached MAX_N={max_n}, stopping early.")
                    break

    with open(auth_tsv, "w", newline="", encoding="utf-8") as f_auth:
        auth_writer = csv.writer(f_auth, delimiter="\t", quoting=csv.QUOTE_NONE, escapechar="\\")
        auth_writer.writerow(["_id","name"])
        for auth_id, name in authors.items():
            auth_writer.writerow([auth_id, name])

    print(f"✓ TSVs generated (N={count}) in {(time.time()-start):.1f}s")

if __name__ == "__main__":
    main()
