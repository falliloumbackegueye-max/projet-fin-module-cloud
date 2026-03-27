// app/index.js — Application Node.js (démonstration 3-Tiers)
"use strict";

require("dotenv").config();
const express = require("express");
const mysql   = require("mysql2/promise");

const app  = express();
const PORT = process.env.PORT || 3000;

// ── Pool de connexions MySQL ────────────────────────────────
const pool = mysql.createPool({
  host     : process.env.DB_HOST     || "192.168.10.10",
  database : process.env.DB_NAME     || "appdb",
  user     : process.env.DB_USER     || "appuser",
  password : process.env.DB_PASSWORD || "",
  waitForConnections: true,
  connectionLimit   : 10,
});

// ── Routes ──────────────────────────────────────────────────
app.get("/", (req, res) => {
  res.json({
    status : "ok",
    message: "Architecture 3-Tiers opérationnelle",
    tier   : "Web (DMZ)",
    time   : new Date().toISOString(),
  });
});

app.get("/health", async (req, res) => {
  try {
    const [rows] = await pool.query("SELECT 1 AS db_ok");
    res.json({ status: "healthy", db: rows[0] });
  } catch (err) {
    res.status(503).json({ status: "unhealthy", error: err.message });
  }
});

app.get("/data", async (req, res) => {
  try {
    const [rows] = await pool.query("SELECT * FROM items LIMIT 20");
    res.json({ count: rows.length, items: rows });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── Démarrage ───────────────────────────────────────────────
app.listen(PORT, "0.0.0.0", () => {
  console.log(`[app] Serveur démarré sur le port ${PORT}`);
  console.log(`[app] DB → ${process.env.DB_HOST}/${process.env.DB_NAME}`);
});
