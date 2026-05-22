const express = require("express");
const router = express.Router();

const authMiddleware = require("../middlewares/authMiddleware");
const {
  getSuggestedUsers,
  searchUsers,
  getUserProfile,
  updateUserProfile,
  changePassword,
} = require("../controllers/userController");

router.get("/suggested", getSuggestedUsers);
router.get("/search", searchUsers);
router.get("/me", authMiddleware, getUserProfile);
router.put("/me", authMiddleware, updateUserProfile);
router.put("/change-password", authMiddleware, changePassword);

module.exports = router;