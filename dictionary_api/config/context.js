const fs = require("fs");
const path = require("path");
const wanakana = require("wanakana");
const Database = require("better-sqlite3");


const DAILY_VOCABULARY_COUNT = Math.max(
  1,
  Number.parseInt(process.env.DAILY_VOCABULARY_COUNT || "6", 10) || 6
);


// =====================================
// 1. LOAD JMdict DATABASE
// =====================================

const dictionaryPath = path.join(
  __dirname,
  "..",
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
// 2.5. LOAD TATOEBA DATABASES
// =====================================

const japaneseEnglishPath = path.join(
  __dirname,
  "..",
  "data",
  "japanese_english.sqlite"
);

const japaneseVietnamesePath = path.join(
  __dirname,
  "..",
  "data",
  "japanese_vietnamese.sqlite"
);

// Database lưu nghĩa tiếng Việt suy luận
const inferredMeaningsPath = path.join(
  __dirname,
  "..",
  "data",
  "inferred_meanings.sqlite"
);

const inferredMeaningsDB = new Database(inferredMeaningsPath);

inferredMeaningsDB.exec(`
  CREATE TABLE IF NOT EXISTS inferred_meanings (
    query TEXT PRIMARY KEY,
    total_sentences INTEGER NOT NULL,
    meanings TEXT NOT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
  )
`);

console.log("Database lưu nghĩa suy luận đã sẵn sàng!");

let japaneseEnglishDB;
let japaneseVietnameseDB;

try {
  japaneseEnglishDB = new Database(japaneseEnglishPath, {
    readonly: true,
    fileMustExist: true,
  });

  const result = japaneseEnglishDB
    .prepare("SELECT COUNT(*) AS total FROM ja_en")
    .get();

  console.log("Đọc Tatoeba Nhật - Anh thành công!");
  console.log("Số cặp câu Nhật - Anh:", result.total);
} catch (error) {
  console.error("Không thể mở database Nhật - Anh:", error.message);
  process.exit(1);
}

try {
  japaneseVietnameseDB = new Database(japaneseVietnamesePath, {
    readonly: true,
    fileMustExist: true,
  });

  const result = japaneseVietnameseDB
    .prepare("SELECT COUNT(*) AS total FROM ja_vi")
    .get();

  console.log("Đọc Tatoeba Nhật - Việt thành công!");
  console.log("Số cặp câu Nhật - Việt:", result.total);
} catch (error) {
  console.error("Không thể mở database Nhật - Việt:", error.message);
  process.exit(1);
}

// Chuẩn bị câu truy vấn để tìm câu ví dụ
const searchJapaneseEnglish = japaneseEnglishDB.prepare(`
  SELECT
    id,
    ja_id,
    ja,
    en_id,
    en
  FROM ja_en
  WHERE ja LIKE @query
  ORDER BY LENGTH(ja) ASC
  LIMIT @limit
`);

const searchJapaneseVietnamese = japaneseVietnameseDB.prepare(`
  SELECT
    id,
    ja_id,
    ja,
    vi_id,
    vi
  FROM ja_vi
  WHERE ja LIKE @query
  ORDER BY LENGTH(ja) ASC
  LIMIT @limit
`);

// =====================================
// 2.6. VIETNAMESE MEANING INFERENCE
// =====================================

// Tách câu thành từ đơn và cụm 2–3 âm tiết.
function extractVietnamesePhrases(sentence) {
  const normalized = sentence
    .toLowerCase()
    .normalize("NFC")
    .replace(/[.,!?;:"()[\]{}…“”‘’]/g, " ")
    .replace(/\s+/g, " ")
    .trim();

  if (!normalized) return [];

  const words = normalized.split(" ");
  const phrases = [];

  for (let size = 1; size <= 3; size++) {
    for (let i = 0; i <= words.length - size; i++) {
      phrases.push(words.slice(i, i + size).join(" "));
    }
  }

  return phrases;
}

// Thống kê số câu chứa từng từ/cụm từ.
function inferVietnameseMeanings(sentences) {
  const counts = new Map();

  for (const sentence of sentences) {
    // Set giúp mỗi cụm chỉ được tính một lần trong một câu.
    const phrases = new Set(
      extractVietnamesePhrases(sentence)
    );

    for (const phrase of phrases) {
      counts.set(
        phrase,
        (counts.get(phrase) || 0) + 1
      );
    }
  }

  const totalSentences = sentences.length;

  if (totalSentences === 0) {
    return [];
  }

  return [...counts.entries()]
    .map(([meaning, count]) => ({
      meaning,
      count,
      percentage: Math.round(
        (count / totalSentences) * 100
      ),
    }))
    .filter(item => item.percentage >= 40)
    .sort((a, b) => {
      if (b.count !== a.count) {
        return b.count - a.count;
      }

      // Nếu số câu bằng nhau, ưu tiên cụm dài hơn.
      return b.meaning.length - a.meaning.length;
    });
}

// Chuẩn bị câu lệnh lấy và lưu kết quả.
const getCachedMeanings = inferredMeaningsDB.prepare(`
  SELECT query, total_sentences, meanings
  FROM inferred_meanings
  WHERE query = ?
`);

const saveCachedMeanings = inferredMeaningsDB.prepare(`
  INSERT OR REPLACE INTO inferred_meanings (
    query,
    total_sentences,
    meanings,
    created_at
  )
  VALUES (?, ?, ?, CURRENT_TIMESTAMP)
`);


// Tính nghĩa tiếng Việt một lần cho mỗi từ; các lần sau đọc SQLite cache.
function getOrInferVietnameseMeaning(query) {
  const key = String(query || "").trim().normalize("NFC");
  if (!key) return { query: key, totalSentences: 0, meanings: [], cached: false };

  const cached = getCachedMeanings.get(key);
  if (cached) {
    const saved = JSON.parse(cached.meanings);
    const ranked = (Array.isArray(saved) ? saved : [])
      .filter(item => item && typeof item.meaning === "string")
      .sort((a, b) => (Number(b.count) || 0) - (Number(a.count) || 0));
    const topOnly = ranked.length ? [ranked[0]] : [];
    // Chuẩn hóa cache cũ: chỉ giữ nghĩa có tần suất cao nhất.
    if (JSON.stringify(saved) !== JSON.stringify(topOnly)) {
      saveCachedMeanings.run(key, cached.total_sentences, JSON.stringify(topOnly));
    }
    return { query: key, totalSentences: cached.total_sentences, meanings: topOnly, cached: true };
  }

  const rows = searchJapaneseVietnamese.all({ query: `%${key}%`, limit: 10 });
  const translations = rows.map(row => row.vi).filter(value => typeof value === "string" && value.trim());
  const candidates = inferVietnameseMeanings(translations);
  const topMeaning = candidates.length ? [candidates[0]] : [];

  saveCachedMeanings.run(key, translations.length, JSON.stringify(topMeaning));
  return { query: key, totalSentences: translations.length, meanings: topMeaning, cached: false };
}

// =====================================
// 4.55. PARTS OF SPEECH AND CONJUGATION
// =====================================

// Ánh xạ mã POS của JMdict sang tên tiếng Nhật, Việt và Anh.
const POS_LABELS = {
  n: ["名詞", "Danh từ", "Noun"],
  n_pr: ["代名詞", "Đại từ", "Pronoun"],
  n_adv: ["副詞的名詞", "Danh từ dùng như trạng từ", "Adverbial noun"],
  n_suf: ["接尾辞", "Hậu tố", "Noun, suffix"],
  n_pref: ["接頭辞", "Tiền tố", "Noun, prefix"],
  v1: ["一段動詞", "Động từ nhóm II", "Ichidan verb"],
  v1_s: ["一段動詞（特殊）", "Động từ nhóm II đặc biệt", "Ichidan verb (くれる)"],
  v5aru: ["五段動詞（ある）", "Động từ nhóm I đặc biệt", "Godan verb - aru"],
  v5b: ["五段動詞（ぶ）", "Động từ nhóm I -ぶ", "Godan verb withぶ ending"],
  v5g: ["五段動詞（ぐ）", "Động từ nhóm I -ぐ", "Godan verb withぐ ending"],
  v5k: ["五段動詞（く）", "Động từ nhóm I -く", "Godan verb withく ending"],
  v5k_s: ["五段動詞（行く）", "Động từ nhóm I đặc biệt", "Godan verb - iku"],
  v5m: ["五段動詞（む）", "Động từ nhóm I -む", "Godan verb withむ ending"],
  v5n: ["五段動詞（ぬ）", "Động từ nhóm I -ぬ", "Godan verb withぬ ending"],
  v5r: ["五段動詞（る）", "Động từ nhóm I -る", "Godan verb withる ending"],
  v5s: ["五段動詞（す）", "Động từ nhóm I -す", "Godan verb withす ending"],
  v5t: ["五段動詞（つ）", "Động từ nhóm I -つ", "Godan verb withつ ending"],
  v5u: ["五段動詞（う）", "Động từ nhóm I -う", "Godan verb withう ending"],
  v5u_s: ["五段動詞（特殊）", "Động từ nhóm I đặc biệt", "Godan verb (special)"],
  vk: ["カ行変格動詞", "Động từ bất quy tắc 来る", "Kuru verb - irregular"],
  vs: ["サ行変格動詞", "Động từ する", "Suru verb"],
  vs_i: ["サ行変格動詞（不規則）", "Động từ する bất quy tắc", "Suru verb - irregular"],
  vs_s: ["サ行変格動詞（特殊）", "Động từ する đặc biệt", "Suru verb - special"],
  vz: ["ザ行変格動詞", "Động từ ずる", "Zuru verb"],
  adj_i: ["い形容詞", "Tính từ đuôi い", "I-adjective"],
  adj_な: ["な形容詞", "Tính từ đuôi な", "Na-adjective"],
  adj_na: ["な形容詞", "Tính từ đuôi な", "Na-adjective"],
  adj_no: ["連体詞的形容詞", "Tính từ kết hợp の", "Noun or adjectival noun with の"],
  adj_pn: ["連体詞", "Định từ", "Pre-noun adjectival"],
  adj_t: ["たる形容詞", "Tính từ たる", "Tar(u) adjective"],
  adv: ["副詞", "Trạng từ", "Adverb"],
  adv_to: ["副詞", "Trạng từ", "Adverb taking と"],
  aux: ["助動詞", "Trợ động từ", "Auxiliary"],
  aux_adj: ["助動詞", "Trợ động từ", "Auxiliary adjective"],
  aux_v: ["助動詞", "Trợ động từ", "Auxiliary verb"],
  conj: ["接続詞", "Liên từ", "Conjunction"],
  ctr: ["助数詞", "Từ đếm", "Counter"],
  exp: ["表現", "Cách diễn đạt", "Expressions"],
  int: ["感動詞", "Thán từ", "Interjection"],
  pn: ["代名詞", "Đại từ", "Pronoun"],
  prt: ["助詞", "Trợ từ", "Particle"],
  pref: ["接頭辞", "Tiền tố", "Prefix"],
  suf: ["接尾辞", "Hậu tố", "Suffix"],
  unc: ["未分類", "Chưa phân loại", "Unclassified"],
};

function getPartsOfSpeech(word) {
  const codes = [...new Set(
    (word.sense ?? []).flatMap((sense) => sense.pos ?? [])
  )];

  return codes.map((code) => {
    const normalizedCode = String(code).replace(/-/g, "_");
    const labels = POS_LABELS[normalizedCode] ?? POS_LABELS[code];

    return {
      code,
      japanese: labels?.[0] ?? code,
      vietnamese: labels?.[1] ?? "Chưa có bản dịch",
      english: labels?.[2] ?? code,
    };
  });
}

const GODAN_FORMS = {
  う: { a: "わ", i: "い", e: "え", o: "お", te: "って", ta: "った" },
  く: { a: "か", i: "き", e: "け", o: "こ", te: "いて", ta: "いた" },
  ぐ: { a: "が", i: "ぎ", e: "げ", o: "ご", te: "いで", ta: "いだ" },
  す: { a: "さ", i: "し", e: "せ", o: "そ", te: "して", ta: "した" },
  つ: { a: "た", i: "ち", e: "て", o: "と", te: "って", ta: "った" },
  ぬ: { a: "な", i: "に", e: "ね", o: "の", te: "んで", ta: "んだ" },
  ぶ: { a: "ば", i: "び", e: "べ", o: "ぼ", te: "んで", ta: "んだ" },
  む: { a: "ま", i: "み", e: "め", o: "も", te: "んで", ta: "んだ" },
  る: { a: "ら", i: "り", e: "れ", o: "ろ", te: "って", ta: "った" },
};

function conjugateVerb(reading, verbType) {
  if (!reading) return null;

  const ending = reading.slice(-1);
  const stem = reading.slice(0, -1);

  if (verbType === "ichidan") {
    const base = stem;
    return {
      dictionary: reading,
      masu: `${base}ます`,
      negative: `${base}ない`,
      te: `${base}て`,
      past: `${base}た`,
      potential: `${base}られる`,
      passive: `${base}られる`,
      causative: `${base}させる`,
    };
  }

  if (verbType === "suru") {
    const base = reading.slice(0, -2);
    return {
      dictionary: reading,
      masu: `${base}します`,
      negative: `${base}しない`,
      te: `${base}して`,
      past: `${base}した`,
      potential: `${base}できる`,
      passive: `${base}される`,
      causative: `${base}させる`,
    };
  }

  if (verbType === "kuru") {
    const base = reading.slice(0, -2);
    return {
      dictionary: reading,
      masu: `${base}きます`,
      negative: `${base}こない`,
      te: `${base}きて`,
      past: `${base}きた`,
      potential: `${base}こられる`,
      passive: `${base}こられる`,
      causative: `${base}こさせる`,
    };
  }

  if (verbType === "zuru") {
    const base = reading.slice(0, -2);
    return {
      dictionary: reading,
      masu: `${base}じます`,
      negative: `${base}じない`,
      te: `${base}じて`,
      past: `${base}じた`,
      potential: `${base}じられる`,
      passive: `${base}じられる`,
      causative: `${base}じさせる`,
    };
  }

  const forms = GODAN_FORMS[ending];
  if (!forms) return null;

  const isIkuSpecial = reading === "いく" || reading === "ゆく";
  const te = isIkuSpecial ? `${stem}って` : `${stem}${forms.te}`;
  const past = isIkuSpecial ? `${stem}った` : `${stem}${forms.ta}`;

  return {
    dictionary: reading,
    masu: `${stem}${forms.i}ます`,
    negative: `${stem}${forms.a}ない`,
    te,
    past,
    potential: `${stem}${forms.e}る`,
    passive: `${stem}${forms.a}れる`,
    causative: `${stem}${forms.a}せる`,
  };
}

function getConjugation(word, posCodes) {
  const codes = new Set(posCodes);
  const kana = word.kana ?? [];
  const reading = kana.find((item) => item.common)?.text ?? kana[0]?.text ?? "";
  const kanji = word.kanji ?? [];
  const display = kanji.find((item) => item.common)?.text ?? kanji[0]?.text ?? reading;

  let verbType = null;
  if (codes.has("v1") || codes.has("v1-s")) verbType = "ichidan";
  else if (codes.has("vk")) verbType = "kuru";
  else if ([...codes].some((code) => code.startsWith("vs"))) verbType = "suru";
  else if (codes.has("vz")) verbType = "zuru";
  else if ([...codes].some((code) => /^v5/.test(code))) verbType = "godan";

  if (verbType) {
    const forms = conjugateVerb(reading, verbType);
    if (!forms) return null;

    return {
      type: "verb",
      verbType,
      display,
      reading,
      forms: [
        ["辞書形", "Dictionary", "Thể từ điển", forms.dictionary],
        ["ます形", "Polite", "Thể lịch sự", forms.masu],
        ["ない形", "Negative", "Thể phủ định", forms.negative],
        ["て形", "Te-form", "Thể て", forms.te],
        ["た形", "Past", "Thể quá khứ", forms.past],
        ["可能形", "Potential", "Thể khả năng", forms.potential],
        ["受身形", "Passive", "Thể bị động", forms.passive],
        ["使役形", "Causative", "Thể sai khiến", forms.causative],
      ].map(([japanese, english, vietnamese, value]) => ({
        japanese, english, vietnamese, value,
      })),
    };
  }

  if (codes.has("adj-i") && reading.endsWith("い")) {
    const stem = reading.slice(0, -1);
    return {
      type: "i-adjective",
      display,
      reading,
      forms: [
        { japanese: "辞書形", vietnamese: "Dạng gốc", value: reading },
        { japanese: "否定形", vietnamese: "Phủ định", value: `${stem}くない` },
        { japanese: "過去形", vietnamese: "Quá khứ", value: `${stem}かった` },
        { japanese: "て形", vietnamese: "Dạng て", value: `${stem}くて` },
        { japanese: "副詞形", vietnamese: "Dạng trạng từ", value: `${stem}く` },
      ],
    };
  }

  if ([...codes].some((code) => code.startsWith("adj-na"))) {
    return {
      type: "na-adjective",
      display,
      reading,
      forms: [
        { japanese: "基本形", vietnamese: "Dạng gốc", value: reading },
        { japanese: "否定形", vietnamese: "Phủ định", value: `${reading}ではない` },
        { japanese: "過去形", vietnamese: "Quá khứ", value: `${reading}だった` },
        { japanese: "て形", vietnamese: "Dạng て", value: `${reading}で` },
        { japanese: "連体形", vietnamese: "Dạng bổ nghĩa danh từ", value: `${reading}な` },
      ],
    };
  }

  return null;
}


module.exports = {
  dictionary, wanakana, DAILY_VOCABULARY_COUNT,
  japaneseEnglishDB, japaneseVietnameseDB,
  searchJapaneseEnglish, searchJapaneseVietnamese,
  getCachedMeanings, saveCachedMeanings, inferVietnameseMeanings,
  getOrInferVietnameseMeaning, getPartsOfSpeech, getConjugation,
};
