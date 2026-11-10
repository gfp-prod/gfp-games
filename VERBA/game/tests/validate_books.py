"""Static authoring gate for physical Latin books. Standard library only."""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
books = json.loads((root / "data/books.json").read_text(encoding="utf-8"))
lexicon = {item["word"] for item in json.loads((root / "data/lexicon.json").read_text(encoding="utf-8"))}
assert isinstance(books, list) and len(books) >= 3, "Need three real readable books"
ids = set()
positions = set()
for book in books:
    needed = ("id", "title", "subject", "difficulty", "passage", "glossary",
              "question", "options", "answer", "explanation", "xp", "teaches", "location")
    assert all(key in book for key in needed), f"Incomplete book: {book.get('id')}"
    uid = book["id"]
    assert isinstance(uid, str) and uid and uid not in ids, f"Invalid/duplicate book id {uid}"
    ids.add(uid)
    assert book["title"].startswith("De "), uid
    assert isinstance(book["passage"], str) and len(book["passage"].split()) >= 9, uid
    assert book["passage"].count("\n") >= 2, uid
    assert 1 <= int(book["difficulty"]) <= 5, uid
    assert isinstance(book["glossary"], list) and len(book["glossary"]) >= 3, uid
    assert all(isinstance(g, str) and " = " in g for g in book["glossary"]), uid
    assert isinstance(book["options"], list) and len(book["options"]) == 3, uid
    assert len(set(book["options"])) == 3, f"Duplicate answers in {uid}"
    assert isinstance(book["answer"], int) and 0 <= book["answer"] < len(book["options"]), uid
    assert 10 <= int(book["xp"]) <= 120, uid
    assert isinstance(book["teaches"], list) and book["teaches"], uid
    assert all(word in lexicon for word in book["teaches"]), f"Book references unknown spells: {uid}"
    location = book["location"]
    assert len(location) == 2 and all(isinstance(n, (float, int)) for n in location), uid
    assert tuple(location) not in positions, f"Books overlap: {uid}"
    positions.add(tuple(location))
    assert "?" in book["question"], uid
    assert isinstance(book["explanation"], str) and len(book["explanation"]) > 15, uid
print(f"PASS: validated {len(books)} distinct Latin books; unique locations and lexicon-backed magical rewards")
