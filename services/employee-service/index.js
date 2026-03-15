const express = require("express");
const app = express();

const PORT = process.env.PORT || 3001;

app.get("/", (req, res) => {
  res.send("Employee Microservice Running");
});

app.get("/health", (req, res) => {
  res.status(200).json({ status: "ok", service: "employee-service" });
});

app.get("/admin/suppliers", (req, res) => {
  res.json({ message: "Employee supplier management" });
});

app.listen(PORT, () => {
  console.log(`Employee service running on port ${PORT}`);
});
