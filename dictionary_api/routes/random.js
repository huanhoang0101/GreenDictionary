const express = require("express");
const { dictionary, DAILY_VOCABULARY_COUNT, getOrInferVietnameseMeaning } = require("../config/context");
const router = express.Router();
const indexes = [];
const jp = /[ぁ-んァ-ヶ一-龯々ー]/;
for (let i=0;i<dictionary.words.length;i++) {
 const w=dictionary.words[i], forms=[...(w.kanji||[]),...(w.kana||[])];
 if (forms.some(x=>x.common===true) && forms.some(x=>jp.test(x.text||"")) && (w.sense||[]).some(s=>(s.gloss||[]).some(g=>g.lang==="eng" && g.text))) indexes.push(i);
}
router.get("/random", (req,res)=>{
 try {
  const language=String(req.query.language||"en").toLowerCase();
  if (!["en","vi"].includes(language)) return res.status(400).json({error:"Chỉ hỗ trợ en hoặc vi."});
  const count=Math.min(DAILY_VOCABULARY_COUNT,indexes.length), chosen=new Set();
  while(chosen.size<count) chosen.add(indexes[Math.floor(Math.random()*indexes.length)]);
  const results=[...chosen].map(i=>{
   const w=dictionary.words[i], kanji=(w.kanji||[]).map(x=>({text:x.text,common:x.common,tags:x.tags||[]})), kana=(w.kana||[]).map(x=>({text:x.text,common:x.common,tags:x.tags||[],appliesToKanji:x.appliesToKanji||[]}));
   const en=[...new Set((w.sense||[]).flatMap(s=>s.gloss||[]).filter(g=>g.lang==="eng"&&g.text).map(g=>g.text))].slice(0,3);
   const key=kanji.find(x=>x.common)?.text||kana.find(x=>x.common)?.text||kana[0]?.text;
   const vi=language==="vi"?getOrInferVietnameseMeaning(key):null;
   return {id:w.id,kanji,kana,meanings:language==="vi"?(vi?.meanings||[]).map(x=>x.meaning):en,language};
  });
  res.json({count:results.length,language,results});
 } catch(e){console.error("Random vocabulary error:",e);res.status(500).json({error:"Không thể lấy từ vựng ngẫu nhiên."});}
});
module.exports=router;
