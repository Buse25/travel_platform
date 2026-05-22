const express = require("express");
const cors = require("cors");
const authRoutes = require("./routes/authRoutes");
const userRoutes = require("./routes/userRoutes");
const travelRoutes = require("./routes/travelRoutes");
const followRoutes = require("./routes/followRoutes");
const exploreRoutes = require("./routes/exploreRoutes");
const chatRoutes = require("./routes/chatRoutes");

const app = express();

app.use(cors());
// app.use(express.json());
app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ extended: true, limit: "10mb" }));

app.get("/api/health", (req, res) => {
  res.json({ status: "ok", message: "API is running 🚀" });
});

app.use("/api/auth", authRoutes);
app.use("/api/users", userRoutes);
app.use("/api/travels", travelRoutes);
app.use("/api/follows", followRoutes);
app.use("/api/explore", exploreRoutes);
app.use("/api/chats", chatRoutes);

module.exports = app;
