const jwt = require("jsonwebtoken");
const User = require("../models/User");

const authMiddleware = async (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).json({ message: "Yetkilendirme reddedildi. Token bulunamadı." });
  }

  const token = authHeader.split(" ")[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findById(decoded.userId).select("-password");

    if (!user) {
      return res.status(401).json({ message: "Geçersiz token." });
    }

    req.user = {
      _id: user._id,
      username: user.username,
      role: user.role || "user",
    };

    next();
  } catch (error) {
    console.error("[authMiddleware] Token hatası:", error.message);
    return res.status(401).json({ message: "Geçersiz token." });
  }
};

module.exports = authMiddleware;
