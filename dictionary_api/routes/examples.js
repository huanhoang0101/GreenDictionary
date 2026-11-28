const express = require("express");
const { searchJapaneseEnglish, searchJapaneseVietnamese } = require("../config/context");
const router = express.Router();
router.get("/search", (req, res) => {
  try {
    const query = req.query.q?.trim();
    const language = (req.query.language || "vi").toLowerCase();

    const limit = Math.min(
      Math.max(parseInt(req.query.limit, 10) || 10, 1),
      50
    );

    if (!query) {
      return res.status(400).json({
        error: "Vui lòng nhập từ tiếng Nhật cần tìm.",
      });
    }

    if (!["vi", "en"].includes(language)) {
      return res.status(400).json({
        error: "Ngôn ngữ không hợp lệ. Chỉ hỗ trợ vi hoặc en.",
      });
    }

    const searchPattern = `%${query}%`;

    let results = [];

    if (language === "vi") {
      results = searchJapaneseVietnamese.all({
        query: searchPattern,
        limit,
      }).map((row) => ({
        id: row.id,
        japaneseSentenceId: row.ja_id,
        japanese: row.ja,
        translationSentenceId: row.vi_id,
        translation: row.vi,
        language: "vi",
      }));
    } else {
      results = searchJapaneseEnglish.all({
        query: searchPattern,
        limit,
      }).map((row) => ({
        id: row.id,
        japaneseSentenceId: row.ja_id,
        japanese: row.ja,
        translationSentenceId: row.en_id,
        translation: row.en,
        language: "en",
      }));
    }

    res.json({
      query,
      language,
      count: results.length,
      results,
    });
  } catch (error) {
    console.error("Tatoeba example search error:", error);

    res.status(500).json({
      error: "Không thể tìm câu ví dụ.",
    });
  }
});


module.exports = router;
