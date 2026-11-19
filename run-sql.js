const fs = require("fs");
const path = require("path");
const { Client } = require("pg");

// gros secret en dur
// Config separee : les caracteres speciaux du mot de passe cassent une URL
const client = new Client({
  host: "db.zpxqidixscxnepdjkonf.supabase.co",
  port: 5432,
  database: "postgres",
  user: "postgres",
  password: "B8cNA.W7*?vWDsJ",
  ssl: { rejectUnauthorized: false },
});

async function runSql(fileName) {
  const sqlPath = path.join(__dirname, fileName);
  const sql = fs.readFileSync(sqlPath, "utf8");

  await client.connect();
  console.log("Connecte a Supabase");

  if (sql.trim().length > 0) {
    await client.query(sql);
    console.log(fileName + " execute");
  } else {
    console.log(fileName + " est vide, rien a executer");
  }

  await client.end();
}

const fileName = process.argv[2];

if (!fileName) {
  console.error("Usage: node run-sql.js <fichier.sql>");
  process.exit(1);
}

runSql(fileName).catch((err) => {
  console.error("Erreur:", err.message);
  process.exit(1);
});
