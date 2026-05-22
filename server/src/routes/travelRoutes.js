const express = require("express");
const router = express.Router();


const {
  createTravel,
  getFeedTravels,
  getMyTravels,
  getPendingTravels,
  updateTravelVerificationStatus,
  searchTravels,
  getUserApprovedTravels,
} = require("../controllers/travelController");

const authMiddleware = require("../middlewares/authMiddleware");
const adminMiddleware = require("../middlewares/adminMiddleware");

router.get("/admin/pending", authMiddleware, adminMiddleware, getPendingTravels);
router.patch(
  "/admin/:travelId/status",
  authMiddleware,
  adminMiddleware,
  updateTravelVerificationStatus
);
router.post("/", authMiddleware, createTravel);
router.get("/feed", authMiddleware, getFeedTravels);
router.get("/search", searchTravels);
router.get("/my", authMiddleware, getMyTravels);
router.get("/user/:userId", getUserApprovedTravels);

module.exports = router;
