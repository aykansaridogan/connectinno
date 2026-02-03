import re
from typing import List


def _split_sentences(text: str) -> List[str]:
    # very small sentence splitter
    parts = re.split(r'(?<=[.!?])\s+', text.strip())
    parts = [p.strip() for p in parts if p.strip()]
    return parts


def summarize_text(text: str, max_sentences: int = 3) -> str:
    """Naive extractive summarizer: pick up to `max_sentences` sentences.

    This is intentionally simple and deterministic — it's a placeholder
    for integrating a real LLM or embedding-based summarizer later.
    """
    if not text:
        return ''
    sentences = _split_sentences(text)
    if len(sentences) <= max_sentences:
        return ' '.join(sentences)

    # Score sentences by presence of content words (simple heuristic):
    words = [w.lower() for w in re.findall(r"\w+", text) if len(w) > 2]
    freq = {}
    for w in words:
        freq[w] = freq.get(w, 0) + 1

    def score(s: str) -> int:
        s_words = [w.lower() for w in re.findall(r"\w+", s) if len(w) > 2]
        return sum(freq.get(w, 0) for w in s_words)

    scored = [(i, s, score(s)) for i, s in enumerate(sentences)]
    # pick top sentences by score, but keep original order
    top = sorted(scored, key=lambda t: (-t[2], t[0]))[:max_sentences]
    top_sorted = sorted(top, key=lambda t: t[0])
    return ' '.join([t[1] for t in top_sorted])
