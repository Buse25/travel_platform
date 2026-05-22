const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const User = require("../models/User");

const register = async (req, res) => {
  try {
    const { fullName, username, email, phone, city, password } = req.body;

    if (!fullName || !username || !email || !phone || !city || !password) {
      return res.status(400).json({
        message: "Tüm alanlar zorunludur.",
      });
    }

    const existingUserByEmail = await User.findOne({ email });
    if (existingUserByEmail) {
      return res.status(400).json({
        message: "Bu e-posta ile kayıtlı bir kullanıcı zaten var.",
      });
    }

    const existingUserByUsername = await User.findOne({ username });
    if (existingUserByUsername) {
      return res.status(400).json({
        message: "Bu kullanıcı adı zaten kullanılıyor.",
      });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const newUser = await User.create({
      fullName,
      username,
      email,
      phone,
      city,
      password: hashedPassword,
    });

    return res.status(201).json({
      message: "Kayıt başarılı.",
      user: {
        id: newUser._id,
        fullName: newUser.fullName,
        username: newUser.username,
        email: newUser.email,
        city: newUser.city,
      },
    });
  } catch (error) {
    return res.status(500).json({
      message: "Kayıt sırasında bir hata oluştu.",
      error: error.message,
    });
  }
};

const login = async (req, res) => {
  try {
    const { username, password } = req.body;

    if (!username || !password) {
      return res.status(400).json({
        message: "Kullanıcı adı ve şifre zorunludur.",
      });
    }

    const user = await User.findOne({ username });
    if (!user) {
      return res.status(400).json({
        message: "Kullanıcı bulunamadı.",
      });
    }

    const isPasswordCorrect = await bcrypt.compare(password, user.password);
    if (!isPasswordCorrect) {
      return res.status(400).json({
        message: "Şifre hatalı.",
      });
    }

    const token = jwt.sign(
      {
        userId: user._id,
        username: user.username,
      },
      process.env.JWT_SECRET,
      { expiresIn: "7d" }
    );

    return res.status(200).json({
      message: "Giriş başarılı.",
      token,
      user: {
        id: user._id,
        fullName: user.fullName,
        username: user.username,
        email: user.email,
        city: user.city,
      },
    });
  } catch (error) {
    return res.status(500).json({
      message: "Giriş sırasında bir hata oluştu.",
      error: error.message,
    });
  }
};

module.exports = {
  register,
  login,
};
