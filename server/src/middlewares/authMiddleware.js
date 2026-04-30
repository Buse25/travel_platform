const jwt = require("jsonwebtoken");

const authMiddleware = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).json({ message: "Yetkilendirme reddedildi. Token bulunamadı." });
  }

  const token = authHeader.split(" ")[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || "secretkey");

    // FIX: Controller req.user._id bekliyor, decoded içinde userId geliyor
    req.user = {
      _id: decoded.userId,
      username: decoded.username,
    };

    next();
  } catch (error) {
    console.error("[authMiddleware] Token hatası:", error.message);
    return res.status(401).json({ message: "Geçersiz token." });
  }
};

module.exports = authMiddleware;