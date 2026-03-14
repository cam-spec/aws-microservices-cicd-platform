const express = require("express");
const app = express();

app.get("/", (req, res) => {
  res.send("Customer Microservice Running");
});

app.get("/suppliers", (req, res) => {
  res.send("Supplier list from Customer Service");
});

const PORT = 3000;

app.listen(PORT, () => {
  console.log("Customer service running on port " + PORT);
});