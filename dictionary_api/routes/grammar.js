const express=require("express");
const {grammarDB,formatGrammar}=require("../config/grammarDb");
const router=express.Router();
router.get("/search", (req, res) => {
  try {
    const query = req.query.q?.trim() || "";
    const level = req.query.level?.toUpperCase();

    const limit = Math.min(
      Math.max(parseInt(req.query.limit, 10) || 20, 1),
      100
    );

    const offset = Math.max(
      parseInt(req.query.offset, 10) || 0,
      0
    );

    // Kiểm tra cấp độ JLPT
    if (level && !["N1", "N2", "N3", "N4", "N5"].includes(level)) {
      return res.status(400).json({
        error: "Cấp độ JLPT không hợp lệ.",
      });
    }

    const conditions = [];
    const params = {};

    // Lọc theo cấp độ
    if (level) {
      conditions.push("level = @level");
      params.level = level;
    }

    // Tìm kiếm theo nội dung
    if (query) {
      conditions.push(`
        (
          pattern LIKE @query COLLATE NOCASE
          OR reading LIKE @query COLLATE NOCASE
          OR romaji LIKE @query COLLATE NOCASE
          OR meaning LIKE @query COLLATE NOCASE
          OR formation LIKE @query COLLATE NOCASE
          OR notes LIKE @query COLLATE NOCASE
          OR tags LIKE @query COLLATE NOCASE
        )
      `);

      params.query = `%${query}%`;
    }

    const whereClause = conditions.length
      ? `WHERE ${conditions.join(" AND ")}`
      : "";

    // Đếm tổng kết quả
    const countResult = grammarDB.prepare(`
      SELECT COUNT(*) AS total
      FROM grammar
      ${whereClause}
    `).get(params);

    // Lấy danh sách kết quả
    const rows = grammarDB.prepare(`
      SELECT *
      FROM grammar
      ${whereClause}
      ORDER BY
        CASE level
          WHEN 'N1' THEN 1
          WHEN 'N2' THEN 2
          WHEN 'N3' THEN 3
          WHEN 'N4' THEN 4
          WHEN 'N5' THEN 5
        END
      LIMIT @limit OFFSET @offset
    `).all({
      ...params,
      limit,
      offset,
    });

    res.json({
      query,
      level: level || null,
      total: countResult.total,
      limit,
      offset,
      results: rows.map(formatGrammar),
    });
  } catch (error) {
    console.error("Grammar search error:", error);

    res.status(500).json({
      error: "Không thể tìm kiếm ngữ pháp.",
    });
  }
});

router.get("/:id", (req, res) => {
  try {
    const id = req.params.id;

    const row = grammarDB.prepare(`
      SELECT *
      FROM grammar
      WHERE id = ?
    `).get(id);

    if (!row) {
      return res.status(404).json({
        error: "Không tìm thấy mẫu ngữ pháp.",
      });
    }

    res.json({
      grammar: formatGrammar(row),
    });
  } catch (error) {
    console.error("Grammar detail error:", error);

    res.status(500).json({
      error: "Không thể lấy thông tin ngữ pháp.",
    });
  }
});


module.exports=router;
