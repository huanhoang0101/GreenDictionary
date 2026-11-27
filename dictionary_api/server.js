
const express = require("express");
const cors = require("cors");
const fs = require("fs");
const path = require("path");
const wanakana = require("wanakana");
const Database = require("better-sqlite3");

const app = express();
const PORT = process.env.PORT || 3000;

const DAILY_VOCABULARY_COUNT = Math.max(
  1,
  Number.parseInt(process.env.DAILY_VOCABULARY_COUNT || "6", 10) || 6
);

app.use(cors());
app.use(express.json());

// =====================================
// 1. LOAD JMdict DATABASE
// =====================================

const dictionaryPath = path.join(
  __dirname,
  "data",
  "jmdict-all-3.6.2.json"
);

console.log("Đang đọc dữ liệu JMdict...");

let dictionary;

try {
  dictionary = JSON.parse(
    fs.readFileSync(dictionaryPath, "utf8")
  );

  console.log("Đọc JMdict thành công!");
  console.log("Tổng số mục từ:", dictionary.words.length);
} catch (error) {
  console.error("Không thể đọc file JMdict:", error.message);
  process.exit(1);
}

// =====================================
// 2. LOAD GRAMMAR DATABASE
// =====================================

const grammarPath = path.join(
  __dirname,
  "data",
  "grammar",
  "openjlpt.sqlite"
);

let grammarDB;

try {
  if (!fs.existsSync(grammarPath)) {
    throw new Error("Không tìm thấy openjlpt.sqlite");
  }

  grammarDB = new Database(grammarPath, {
    readonly: true,
    fileMustExist: true,
  });

  const grammarCount = grammarDB
    .prepare("SELECT COUNT(*) AS total FROM grammar")
    .get();

  console.log("Đọc Grammar SQLite thành công!");
  console.log("Tổng số mẫu ngữ pháp:", grammarCount.total);
} catch (error) {
  console.error("Không thể mở Grammar SQLite:", error.message);
  process.exit(1);
}

// Chuyển JSON text trong SQLite thành dữ liệu JavaScript
function parseJson(value, fallback = []) {
  try {
    return JSON.parse(value || JSON.stringify(fallback));
  } catch {
    return fallback;
  }
}

// Chuẩn hóa dữ liệu ngữ pháp trước khi trả về Flutter
function formatGrammar(row) {
  if (!row) return null;

  return {
    id: row.id,
    pattern: row.pattern,
    reading: row.reading,
    romaji: row.romaji,
    level: row.level,
    meaning: row.meaning,
    formation: row.formation,
    examples: parseJson(row.examples),
    tags: parseJson(row.tags),
    notes: row.notes,
  };
}

// =====================================
// 3. HOME API
// =====================================

app.get("/", (req, res) => {
  res.json({
    message: "Japanese Dictionary API is running!",
    services: [
      "dictionary",
      "grammar",
    ],
  });
});

// =====================================
// 4. DICTIONARY SEARCH API
// =====================================

app.get("/api/dictionary/search", (req, res) => {
  const query = req.query.q?.trim();

  if (!query) {
    return res.status(400).json({
      error: "Vui lòng nhập từ cần tìm.",
    });
  }

  const keyword = query.toLowerCase();
  const hiraganaKeyword = wanakana.toHiragana(keyword);

  const exactMatches = [];
  const otherMatches = [];

  for (const word of dictionary.words) {
    const kanji = (word.kanji ?? []).map(item => item.text);
    const kana = (word.kana ?? []).map(item => item.text);

    const meanings = (word.sense ?? [])
      .flatMap(sense => sense.gloss ?? [])
      .filter(gloss => gloss.lang === "eng")
      .map(gloss => gloss.text);

    const spellings = [...kanji, ...kana];

    const isExactJapanese = spellings.some(text =>
      text.toLowerCase() === keyword ||
      text.toLowerCase() === hiraganaKeyword
    );

    const isPartialJapanese = spellings.some(text =>
      text.toLowerCase().includes(keyword) ||
      text.toLowerCase().includes(hiraganaKeyword)
    );

    const isExactEnglish = meanings.some(text =>
      text.toLowerCase() === keyword
    );

    const isPartialEnglish = meanings.some(text =>
      text.toLowerCase().includes(keyword)
    );

    if (
      !isExactJapanese &&
      !isPartialJapanese &&
      !isExactEnglish &&
      !isPartialEnglish
    ) {
      continue;
    }

    const result = {
      id: word.id,
      kanji,
      kana,
      meanings: [...new Set(meanings)].slice(0, 10),
    };

    if (isExactJapanese || isExactEnglish) {
      exactMatches.push(result);
    } else {
      otherMatches.push(result);
    }
  }

  const results = [
    ...exactMatches,
    ...otherMatches,
  ].slice(0, 20);

  res.json({
    query,
    count: results.length,
    results,
  });
});


// =====================================
// 4.5. RANDOM DAILY VOCABULARY API
// =====================================

// Chỉ lấy mục từ có dạng viết phổ biến, chữ Nhật thực sự
// và ít nhất một nghĩa tiếng Anh.
const dailyVocabularyIndexes = [];

const japaneseTextRegex = /[ぁ-んァ-ヶ一-龯々ー]/;

for (let i = 0; i < dictionary.words.length; i++) {
  const word = dictionary.words[i];

  const allForms = [
    ...(word.kanji ?? []),
    ...(word.kana ?? []),
  ];

  const hasCommonForm = allForms.some(
    (item) => item.common === true
  );

  const hasJapaneseText = allForms.some(
    (item) => japaneseTextRegex.test(item.text ?? "")
  );

  const hasEnglishMeaning = (word.sense ?? []).some(
    (sense) =>
      (sense.gloss ?? []).some(
        (gloss) =>
          gloss.lang === "eng" &&
          typeof gloss.text === "string" &&
          gloss.text.trim().length > 0
      )
  );

  if (hasCommonForm && hasJapaneseText && hasEnglishMeaning) {
    dailyVocabularyIndexes.push(i);
  }
}

console.log(
  "Số từ thông dụng đủ điều kiện hiển thị ngẫu nhiên:",
  dailyVocabularyIndexes.length
);

// API lấy từ ngẫu nhiên
app.get("/api/dictionary/random", (req, res) => {
  try {
    if (dailyVocabularyIndexes.length === 0) {
      return res.status(404).json({
        error: "Không tìm thấy từ vựng phù hợp.",
      });
    }

    const count = Math.min(
      DAILY_VOCABULARY_COUNT,
      dailyVocabularyIndexes.length
    );

    const selectedIndexes = new Set();

    while (selectedIndexes.size < count) {
      const randomPosition = Math.floor(
        Math.random() * dailyVocabularyIndexes.length
      );

      selectedIndexes.add(
        dailyVocabularyIndexes[randomPosition]
      );
    }

    const results = [...selectedIndexes].map((index) => {
      const word = dictionary.words[index];

      const kanji = (word.kanji ?? []).map((item) => ({
        text: item.text,
        common: item.common,
        tags: item.tags ?? [],
      }));

      const kana = (word.kana ?? []).map((item) => ({
        text: item.text,
        common: item.common,
        tags: item.tags ?? [],
        appliesToKanji: item.appliesToKanji ?? [],
      }));

      const meanings = [
        ...new Set(
          (word.sense ?? [])
            .flatMap((sense) => sense.gloss ?? [])
            .filter(
              (gloss) =>
                gloss.lang === "eng" &&
                typeof gloss.text === "string"
            )
            .map((gloss) => gloss.text)
        ),
      ].slice(0, 3);

      return {
        id: word.id,
        kanji,
        kana,
        meanings,
      };
    });

    res.json({
      count: results.length,
      results,
    });
  } catch (error) {
    console.error("Random vocabulary error:", error);

    res.status(500).json({
      error: "Không thể lấy từ vựng ngẫu nhiên.",
    });
  }
});


// =====================================
// 4.6. DICTIONARY DETAIL API
// =====================================

app.get("/api/dictionary/:id", (req, res) => {
  try {
    const id = req.params.id;

    const word = dictionary.words.find(
      (item) => String(item.id) === id
    );

    if (!word) {
      return res.status(404).json({
        error: "Không tìm thấy từ vựng.",
      });
    }

    // Trả về toàn bộ dữ liệu gốc của mục từ trong JMdict.
    res.json({
      word,
    });
  } catch (error) {
    console.error("Dictionary detail error:", error);

    res.status(500).json({
      error: "Không thể lấy chi tiết từ vựng.",
    });
  }
});


// =====================================
// 5. GRAMMAR SEARCH API
// =====================================

app.get("/api/grammar/search", (req, res) => {
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

// =====================================
// 6. GRAMMAR DETAIL API
// =====================================

app.get("/api/grammar/:id", (req, res) => {
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

// =====================================
// 7. START SERVER
// =====================================

app.listen(PORT, "0.0.0.0", () => {
  console.log(`API đang chạy tại http://localhost:${PORT}`);
});
