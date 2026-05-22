const Follow = require("../models/Follow");
const Travel = require("../models/Travel");
const User = require("../models/User");

const APPROVED_STATUS = "Onayland\u0131";

const getExploreData = async (req, res) => {
  try {
    const travelsPromise = Travel.find({ verificationStatus: APPROVED_STATUS })
      .populate("user", "_id fullName username city profileImage")
      .sort({ createdAt: -1 })
      .limit(20);

    const popularUsersPromise = Follow.aggregate([
      {
        $group: {
          _id: "$following",
          followerCount: { $sum: 1 },
        },
      },
      { $sort: { followerCount: -1 } },
      { $limit: 10 },
      {
        $lookup: {
          from: "users",
          localField: "_id",
          foreignField: "_id",
          as: "user",
        },
      },
      { $unwind: "$user" },
      {
        $project: {
          _id: "$user._id",
          fullName: "$user.fullName",
          username: "$user.username",
          city: "$user.city",
          profileImage: "$user.profileImage",
          followerCount: 1,
        },
      },
    ]);

    const newUsersPromise = User.find({})
      .select("_id fullName username city profileImage")
      .sort({ createdAt: -1 })
      .limit(10);

    const [travels, popularUsers, newUsers] = await Promise.all([
      travelsPromise,
      popularUsersPromise,
      newUsersPromise,
    ]);

    return res.status(200).json({
      travels,
      popularUsers,
      newUsers,
    });
  } catch (error) {
    return res.status(500).json({
      message: "Kesfet verileri alinirken hata olustu.",
      error: error.message,
    });
  }
};

module.exports = {
  getExploreData,
};
