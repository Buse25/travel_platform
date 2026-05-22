const User = require("../models/User");
const bcrypt = require("bcryptjs");

const getSuggestedUsers = async (req, res) => {
  try {
    const users = await User.find({})
      .select("-password")
      .sort({ username: 1 })
      .limit(10);

    return res.status(200).json({ users });
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
      return res.status(400).json({ message: "Arama parametresi gereklidir." });
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

    return res.status(200).json({ users });
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

const updateUserProfile = async (req, res) => {
  try {
    const userId = req.user._id;
    const { fullName, username, email, phone, city, profileImage } = req.body;

    const existingUsername = await User.findOne({
      username,
      _id: { $ne: userId },
    });

    if (existingUsername) {
      return res.status(400).json({ message: "Bu kullanıcı adı zaten kullanılıyor." });
    }

    const existingEmail = await User.findOne({
      email,
      _id: { $ne: userId },
    });

    if (existingEmail) {
      return res.status(400).json({ message: "Bu e-posta zaten kullanılıyor." });
    }

    const updatedUser = await User.findByIdAndUpdate(
      userId,
      { fullName, username, email, phone, city, profileImage },
      { new: true, runValidators: true }
    ).select("-password");

    return res.status(200).json({
      message: "Profil başarıyla güncellendi.",
      user: updatedUser,
    });
  } catch (error) {
    return res.status(500).json({
      message: "Profil güncellenirken hata oluştu.",
      error: error.message,
    });
  }
};

const changePassword = async (req, res) => {
  try {
    const userId = req.user._id;
    const { oldPassword, newPassword } = req.body;

    if (!oldPassword || !newPassword) {
      return res.status(400).json({ message: "Eski ve yeni şifre gereklidir." });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({ message: "Yeni şifre en az 6 karakter olmalıdır." });
    }

    const user = await User.findById(userId);

    if (!user) {
      return res.status(404).json({ message: "Kullanıcı bulunamadı." });
    }

    const isMatch = await bcrypt.compare(oldPassword, user.password);

    if (!isMatch) {
      return res.status(400).json({ message: "Eski şifre hatalı." });
    }

    const salt = await bcrypt.genSalt(10);
    user.password = await bcrypt.hash(newPassword, salt);
    await user.save();

    return res.status(200).json({ message: "Şifre başarıyla değiştirildi." });
  } catch (error) {
    return res.status(500).json({
      message: "Şifre değiştirilirken hata oluştu.",
      error: error.message,
    });
  }
};

module.exports = {
  getSuggestedUsers,
  searchUsers,
  getUserProfile,
  updateUserProfile,
  changePassword,
};