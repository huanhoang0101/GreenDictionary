
const fs = require("fs");

const filePath = "./data/jmdict-all-3.6.2.json";

console.log("Đang đọc JMdict...");

const dictionary = JSON.parse(
  fs.readFileSync(filePath, "utf8")
);

const sample = dictionary.words.find((word) => {
  const hasCommonForm = [
    ...(word.kanji ?? []),
    ...(word.kana ?? [])
  ].some((item) => item.common === true);

  const hasJapaneseText = [
    ...(word.kanji ?? []),
    ...(word.kana ?? [])
  ].some((item) =>
    /[ぁ-んァ-ヶ一-龯々ー]/.test(item.text ?? "")
  );

  const hasEnglishMeaning = (word.sense ?? []).some((sense) =>
    (sense.gloss ?? []).some(
      (gloss) => gloss.lang === "eng"
    )
  );

  return hasCommonForm && hasJapaneseText && hasEnglishMeaning;
});

if (!sample) {
  console.log("Không tìm thấy từ phù hợp.");
  process.exit(1);
}

console.log(JSON.stringify(sample, null, 2));
