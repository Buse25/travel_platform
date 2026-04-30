const User = require("../models/User");

const getSuggestedUsers = async (req, res) => {
  try {
    const users = await User.find({})
      .select("-password")
      .sort({ username: 1 })
      .limit(10);

    return res.status(200).json({
      users,
    });
  } catch (error) {
    return res.status(500).json({
      message: "Kullanıcılar alınırken hata oluştu.",
      error: error.message,
    });
  }
};

const searchUsers = async (req, res) => {
  try {
    const q = req.query.q?.trim();

    if (!q) {
      return res.status(400).json({
        message: "Arama parametresi gereklidir.",
      });
    }

    const users = await User.find({
      $or: [
        { username: { $regex: q, $options: "i" } },
        { fullName: { $regex: q, $options: "i" } },
        { city: { $regex: q, $options: "i" } },
        { interests: { $elemMatch: { $regex: q, $options: "i" } } },
      ],
    })
      .select("-password")
      .sort({ username: 1 })
      .limit(20);

    return res.status(200).json({
      users,
    });
  } catch (error) {
    return res.status(500).json({
      message: "Arama sırasında hata oluştu.",
      error: error.message,
    });
  }
};

const getUserProfile = async (req, res) => {
  try {
    const userId = req.user._id;
    const user = await User.findById(userId).select("-password");

    if (!user) {
      return res.status(404).json({ message: "Kullanıcı bulunamadı." });
    }

    return res.status(200).json({ user });
  } catch (error) {
    return res.status(500).json({
      message: "Profil bilgisi alınırken hata oluştu.",
      error: error.message,
    });
  }
};

module.exports = {
  getSuggestedUsers,
  searchUsers,
  getUserProfile,
};