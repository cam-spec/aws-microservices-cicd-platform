const express = require("express");
const app = express();

const PORT = process.env.PORT || 3000;

app.get("/", (req, res) => {
  res.send("Customer Microservice Running");
});

app.get("/health", (req, res) => {
  res.status(200).json({ status: "ok", service: "customer-service" });
});

app.get("/suppliers", (req, res) => {
  res.send("Supplier list from Customer Service");
});

app.listen(PORT, () => {
  console.log(`Customer service running on port ${PORT}`);
});