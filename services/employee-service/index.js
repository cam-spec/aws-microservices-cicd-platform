const express = require("express");
const app = express();

app.get("/", (req, res) => {
  res.send("Employee Microservice Running");
});

app.get("/admin/suppliers", (req, res) => {
  res.send("Employee supplier management");
});

const PORT = 4000;

app.listen(PORT, () => {
  console.log("Employee service running on port " + PORT);
});