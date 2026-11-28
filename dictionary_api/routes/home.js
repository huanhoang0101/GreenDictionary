const express = require("express");
const router = express.Router();
router.get("/", (req, res) => res.json({ message: "Japanese Dictionary API is running!", services: ["dictionary", "grammar", "examples", "inferred-meanings"] }));
module.exports = router;
