const mongoose = require("mongoose");
const Follow = require("../models/Follow");
const User = require("../models/User");

const isValidUserId = (userId) => mongoose.Types.ObjectId.isValid(userId);

const followUser = async (req, res) => {
  try {
    const followerId = req.user._id;
    const { userId } = req.params;

    if (!isValidUserId(userId)) {
      return res.status(400).json({ message: "Gecersiz kullanici id." });
    }

    if (followerId.toString() === userId.toString()) {
      return res.status(400).json({ message: "Kullanici kendisini takip edemez." });
    }

    const userToFollow = await User.findById(userId).select("_id");

    if (!userToFollow) {
      return res.status(404).json({ message: "Takip edilecek kullanici bulunamadi." });
    }

    const existingFollow = await Follow.findOne({
      follower: followerId,
      following: userId,
    });

    if (existingFollow) {
      return res.status(400).json({ message: "Bu kullanici zaten takip ediliyor." });
    }

    const follow = await Follow.create({
      follower: followerId,
      following: userId,
    });

    return res.status(201).json({
      message: "Kullanici takip edildi.",
      follow,
    });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(400).json({ message: "Bu kullanici zaten takip ediliyor." });
    }

    return res.status(500).json({
      message: "Takip islemi sirasinda hata olustu.",
      error: error.message,
    });
  }
};

const unfollowUser = async (req, res) => {
  try {
    const followerId = req.user._id;
    const { userId } = req.params;

    if (!isValidUserId(userId)) {
      return res.status(400).json({ message: "Gecersiz kullanici id." });
    }

    if (followerId.toString() === userId.toString()) {
      return res.status(400).json({ message: "Kullanici kendisini takipten cikaramaz." });
    }

    const deletedFollow = await Follow.findOneAndDelete({
      follower: followerId,
      following: userId,
    });

    if (!deletedFollow) {
      return res.status(404).json({ message: "Takip kaydi bulunamadi." });
    }

    return res.status(200).json({ message: "Kullanici takipten cikarildi." });
  } catch (error) {
    return res.status(500).json({
      message: "Takipten cikarma sirasinda hata olustu.",
      error: error.message,
    });
  }
};

const getFollowStats = async (req, res) => {
  try {
    const { userId } = req.params;

    if (!isValidUserId(userId)) {
      return res.status(400).json({ message: "Gecersiz kullanici id." });
    }

    const user = await User.findById(userId).select("_id");

    if (!user) {
      return res.status(404).json({ message: "Kullanici bulunamadi." });
    }

    const [followersCount, followingCount] = await Promise.all([
      Follow.countDocuments({ following: userId }),
      Follow.countDocuments({ follower: userId }),
    ]);

    return res.status(200).json({
      userId,
      followersCount,
      followingCount,
    });
  } catch (error) {
    return res.status(500).json({
      message: "Takip istatistikleri alinirken hata olustu.",
      error: error.message,
    });
  }
};

const isFollowingUser = async (req, res) => {
  try {
    const followerId = req.user._id;
    const { userId } = req.params;

    if (!isValidUserId(userId)) {
      return res.status(400).json({ message: "Gecersiz kullanici id." });
    }

    const user = await User.findById(userId).select("_id");

    if (!user) {
      return res.status(404).json({ message: "Kullanici bulunamadi." });
    }

    const follow = await Follow.findOne({
      follower: followerId,
      following: userId,
    }).select("_id");

    return res.status(200).json({
      userId,
      isFollowing: Boolean(follow),
    });
  } catch (error) {
    return res.status(500).json({
      message: "Takip durumu kontrol edilirken hata olustu.",
      error: error.message,
    });
  }
};

module.exports = {
  followUser,
  unfollowUser,
  getFollowStats,
  isFollowingUser,
};
