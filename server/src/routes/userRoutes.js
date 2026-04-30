const express = require("express");
const router = express.Router();

const authMiddleware = require("../middlewares/authMiddleware");
const {
  getSuggestedUsers,
  searchUsers,
  getUserProfile,
} = require("../controllers/userController");

router.get("/suggested", getSuggestedUsers);
router.get("/search", searchUsers);
router.get("/me", authMiddleware, getUserProfile);

module.exports = router;