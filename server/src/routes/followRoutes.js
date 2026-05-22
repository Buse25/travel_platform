const express = require("express");
const router = express.Router();

const authMiddleware = require("../middlewares/authMiddleware");
const {
  followUser,
  unfollowUser,
  getFollowStats,
  isFollowingUser,
} = require("../controllers/followController");

router.post("/:userId", authMiddleware, followUser);
router.delete("/:userId", authMiddleware, unfollowUser);
router.get("/stats/:userId", getFollowStats);
router.get("/is-following/:userId", authMiddleware, isFollowingUser);

module.exports = router;
