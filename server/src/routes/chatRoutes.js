const express = require("express");
const router = express.Router();

const authMiddleware = require("../middlewares/authMiddleware");
const {
  getOrCreateConversation,
  getConversations,
  getUnreadCount,
  getMessages,
  sendMessage,
  markMessagesAsRead,
} = require("../controllers/chatController");

router.post("/conversation/:userId", authMiddleware, getOrCreateConversation);
router.get("/conversations", authMiddleware, getConversations);
router.get("/unread-count", authMiddleware, getUnreadCount);
router.get("/messages/:conversationId", authMiddleware, getMessages);
router.post("/messages/:conversationId", authMiddleware, sendMessage);
router.put("/messages/:conversationId/read", authMiddleware, markMessagesAsRead);

module.exports = router;
