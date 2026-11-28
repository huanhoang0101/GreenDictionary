const express = require("express");
const { dictionary, getPartsOfSpeech, getConjugation, getOrInferVietnameseMeaning } = require("../config/context");
const router=express.Router();
router.get("/:id",(req,res)=>{
 try {
  const language=String(req.query.language||"en").toLowerCase();
  if (!["en","vi"].includes(language)) return res.status(400).json({error:"Chỉ hỗ trợ en hoặc vi."});
  const original=dictionary.words.find(x=>String(x.id)===String(req.params.id));
  if(!original) return res.status(404).json({error:"Không tìm thấy từ vựng."});
  const word={...original,sense:(original.sense||[]).map(s=>({...s,gloss:(s.gloss||[]).filter(g=>g.lang==="eng")}))};
  const posCodes=[...new Set((word.sense||[]).flatMap(s=>s.pos||[]))];
  const key=(word.kanji||[]).find(x=>x.common)?.text||(word.kana||[]).find(x=>x.common)?.text||(word.kana||[])[0]?.text;
  const vi=language==="vi"?getOrInferVietnameseMeaning(key):null;
  res.json({word,partsOfSpeech:getPartsOfSpeech(word),conjugation:getConjugation(word,posCodes),language,vietnameseMeaning:vi?.meanings?.[0]||null,meaningStats:vi});
 }catch(e){console.error("Dictionary detail error:",e);res.status(500).json({error:"Không thể lấy chi tiết từ vựng."});}
});
module.exports=router;
