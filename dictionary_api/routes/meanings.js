const express=require("express");
const {getOrInferVietnameseMeaning}=require("../config/context");
const router=express.Router();
router.get("/inferred",(req,res)=>{try{const q=String(req.query.q||"").trim();if(!q)return res.status(400).json({error:"Vui lòng nhập từ tiếng Nhật cần tìm."});res.json(getOrInferVietnameseMeaning(q));}catch(e){console.error("Inferred meaning error:",e);res.status(500).json({error:"Không thể suy luận nghĩa tiếng Việt."});}});
module.exports=router;
