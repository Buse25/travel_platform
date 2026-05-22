const adminMiddleware = (req, res, next) => {
  if (!req.user || req.user.role !== "admin") {
    return res.status(403).json({ message: "Admin yetkisi gereklidir." });
  }

  next();
};

module.exports = adminMiddleware;
