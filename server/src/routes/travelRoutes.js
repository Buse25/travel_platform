const express = require("express");
const router = express.Router();

const {
    createTravel,
    getMyTravels,
} = require("../controllers/travelController");

const authMiddleware = require("../middlewares/authMiddleware");

router.post("/", authMiddleware, createTravel);
router.get("/my", authMiddleware, getMyTravels);

module.exports = router;