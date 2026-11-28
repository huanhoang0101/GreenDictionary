const path=require("path");
const Database=require("better-sqlite3");
const dbPath=path.join(__dirname,"..","data","grammar","openjlpt.sqlite");
const grammarDB=new Database(dbPath,{readonly:true,fileMustExist:true});
function parseJson(value,fallback=[]){try{return JSON.parse(value||JSON.stringify(fallback));}catch{return fallback;}}
function formatGrammar(row){if(!row)return null;return {id:row.id,pattern:row.pattern,reading:row.reading,romaji:row.romaji,level:row.level,meaning:row.meaning,formation:row.formation,examples:parseJson(row.examples),tags:parseJson(row.tags),notes:row.notes};}
module.exports={grammarDB,formatGrammar};
