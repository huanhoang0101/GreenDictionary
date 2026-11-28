const express = require("express");
const wanakana = require("wanakana");
const { dictionary, getOrInferVietnameseMeaning } = require("../config/context");
const router = express.Router();

router.get("/search", (req, res) => {
  try {
    const query = String(req.query.q || "").trim();
    const language = String(req.query.language || "en").toLowerCase();
    if (!query) return res.status(400).json({ error: "Vui lòng nhập từ cần tìm." });
    if (!["en", "vi"].includes(language)) return res.status(400).json({ error: "Chỉ hỗ trợ ngôn ngữ en hoặc vi." });

    const keyword = query.toLowerCase();
    const hira = wanakana.toHiragana(keyword);
    const exact = [], partial = [];
    for (const word of dictionary.words) {
      const kanji = (word.kanji || []).map(x => x.text).filter(Boolean);
      const kana = (word.kana || []).map(x => x.text).filter(Boolean);
      const english = [...new Set((word.sense || []).flatMap(s => s.gloss || []).filter(g => g.lang === "eng" && g.text).map(g => g.text))];
      const spellings = [...kanji, ...kana];
      const exactJa = spellings.some(x => x.toLowerCase() === keyword || x.toLowerCase() === hira);
      const partialJa = spellings.some(x => x.toLowerCase().includes(keyword) || x.toLowerCase().includes(hira));
      const exactEn = language === "en" && english.some(x => x.toLowerCase() === keyword);
      const partialEn = language === "en" && english.some(x => x.toLowerCase().includes(keyword));
      if (!exactJa && !partialJa && !exactEn && !partialEn) continue;
      const primary = kanji.find(x => x) || kana[0] || query;
      const viData = language === "vi" ? getOrInferVietnameseMeaning(primary) : null;
      const meanings = language === "vi" ? (viData?.meanings || []).map(x => x.meaning) : english.slice(0, 10);
      const item = { id: word.id, kanji, kana, meanings, language, ...(language === "vi" ? { meaningStats: viData } : {}) };
      if (exactJa || exactEn) exact.push(item); else partial.push(item);
      if (exact.length + partial.length >= 100) break;
    }
    const results = [...exact, ...partial].slice(0, 20);
    res.json({ query, language, count: results.length, results });
  } catch (error) {
    console.error("Dictionary search error:", error);
    res.status(500).json({ error: "Không thể tìm kiếm từ vựng." });
  }
});
module.exports = router;
