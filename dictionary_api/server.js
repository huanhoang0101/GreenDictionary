const express = require("express");
const cors = require("cors");
const fs = require("fs");
const path = require("path");
const wanakana = require("wanakana");

const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json());

// Đường dẫn đến file JMdict
const filePath = path.join(
  __dirname,
  "data",
  "jmdict-all-3.6.2.json"
);

console.log("Đang đọc dữ liệu JMdict...");

let dictionary;

try {
  dictionary = JSON.parse(fs.readFileSync(filePath, "utf8"));

  console.log("Đọc dữ liệu thành công!");
  console.log("Tổng số mục từ:", dictionary.words.length);
} catch (error) {
  console.error("Không thể đọc file JMdict:", error.message);
  process.exit(1);
}

// Kiểm tra API
app.get("/", (req, res) => {
  res.json({
    message: "Japanese Dictionary API is running!",
  });
});

// Tìm kiếm từ vựng

app.get("/api/dictionary/search", (req, res) => {
  const query = req.query.q?.trim();

  if (!query) {
    return res.status(400).json({
      error: "Vui lòng nhập từ cần tìm."
    });
  }

  const keyword = query.toLowerCase();
  const hiraganaKeyword = wanakana.toHiragana(keyword);

  const exactMatches = [];
  const otherMatches = [];

  for (const word of dictionary.words) {
    const kanji = (word.kanji ?? []).map(item => item.text);
    const kana = (word.kana ?? []).map(item => item.text);

    // Lấy nghĩa tiếng Anh
    const meanings = (word.sense ?? [])
      .flatMap(sense => sense.gloss ?? [])
      .filter(gloss => gloss.lang === "eng")
      .map(gloss => gloss.text);

    const spellings = [...kanji, ...kana];

    // Kiểm tra từ tiếng Nhật
    const isExactJapanese = spellings.some(text =>
      text.toLowerCase() === keyword ||
      text.toLowerCase() === hiraganaKeyword
    );

    const isPartialJapanese = spellings.some(text =>
      text.toLowerCase().includes(keyword) ||
      text.toLowerCase().includes(hiraganaKeyword)
    );

    // Kiểm tra nghĩa tiếng Anh
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
      meanings: [...new Set(meanings)].slice(0, 10)
    };

    // Ưu tiên kết quả khớp chính xác
    if (isExactJapanese || isExactEnglish) {
      exactMatches.push(result);
    } else {
      otherMatches.push(result);
    }
  }

  const results = [
    ...exactMatches,
    ...otherMatches
  ].slice(0, 20);

  res.json({
    query,
    count: results.length,
    results
  });
});



// Khởi động server
app.listen(PORT, () => {
  console.log(`API đang chạy tại http://localhost:${PORT}`);
});