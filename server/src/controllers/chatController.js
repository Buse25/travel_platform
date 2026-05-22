const mongoose = require("mongoose");
const Conversation = require("../models/Conversation");
const Message = require("../models/Message");
const User = require("../models/User");

const isValidObjectId = (id) => mongoose.Types.ObjectId.isValid(id);

const getOrCreateConversation = async (req, res) => {
  try {
    const currentUserId = req.user._id;
    const { userId } = req.params;

    if (!isValidObjectId(userId)) {
      return res.status(400).json({ message: "Gecersiz kullanici id." });
    }

    if (currentUserId.toString() === userId.toString()) {
      return res.status(400).json({ message: "Kullanici kendisiyle sohbet baslatamaz." });
    }

    const otherUser = await User.findById(userId).select("_id fullName username city profileImage");

    if (!otherUser) {
      return res.status(404).json({ message: "Kullanici bulunamadi." });
    }

    let conversation = await Conversation.findOne({
      participants: { $all: [currentUserId, userId], $size: 2 },
    })
      .populate("participants", "_id fullName username city profileImage")
      .populate({
        path: "lastMessage",
        populate: { path: "sender", select: "_id fullName username profileImage" },
      });

    if (!conversation) {
      conversation = await Conversation.create({
        participants: [currentUserId, userId],
      });

      conversation = await Conversation.findById(conversation._id)
        .populate("participants", "_id fullName username city profileImage")
        .populate({
          path: "lastMessage",
          populate: { path: "sender", select: "_id fullName username profileImage" },
        });
    }

    return res.status(200).json({ conversation });
  } catch (error) {
    return res.status(500).json({
      message: "Konusma olusturulurken hata olustu.",
      error: error.message,
    });
  }
};

const getConversations = async (req, res) => {
  try {
    const currentUserId = req.user._id;

    const conversations = await Conversation.find({
      participants: currentUserId,
    })
      .populate("participants", "_id fullName username city profileImage")
      .populate({
        path: "lastMessage",
        populate: { path: "sender", select: "_id fullName username profileImage" },
      })
      .sort({ updatedAt: -1 });

    const conversationsWithUnread = await Promise.all(
      conversations.map(async (conversation) => {
        const unreadCount = await Message.countDocuments({
          conversation: conversation._id,
          sender: { $ne: currentUserId },
          read: { $ne: true },
        });

        return {
          ...conversation.toObject(),
          unreadCount,
        };
      })
    );

    return res.status(200).json({ conversations: conversationsWithUnread });
  } catch (error) {
    return res.status(500).json({
      message: "Konusmalar alinirken hata olustu.",
      error: error.message,
    });
  }
};

const getUnreadCount = async (req, res) => {
  try {
    const currentUserId = req.user._id;

    const conversations = await Conversation.find({
      participants: currentUserId,
    }).select("_id");

    const conversationIds = conversations.map((conversation) => conversation._id);

    const unreadCount = await Message.countDocuments({
      conversation: { $in: conversationIds },
      sender: { $ne: currentUserId },
      read: { $ne: true },
    });

    return res.status(200).json({ unreadCount });
  } catch (error) {
    return res.status(500).json({
      message: "Okunmamis mesaj sayisi alinirken hata olustu.",
      error: error.message,
    });
  }
};

const getMessages = async (req, res) => {
  try {
    const currentUserId = req.user._id;
    const { conversationId } = req.params;

    if (!isValidObjectId(conversationId)) {
      return res.status(400).json({ message: "Gecersiz konusma id." });
    }

    const conversation = await Conversation.findOne({
      _id: conversationId,
      participants: currentUserId,
    });

    if (!conversation) {
      return res.status(404).json({ message: "Konusma bulunamadi." });
    }

    const messages = await Message.find({ conversation: conversationId })
      .populate("sender", "_id fullName username profileImage")
      .sort({ createdAt: 1 });

    return res.status(200).json({ messages });
  } catch (error) {
    return res.status(500).json({
      message: "Mesajlar alinirken hata olustu.",
      error: error.message,
    });
  }
};

const sendMessage = async (req, res) => {
  try {
    const currentUserId = req.user._id;
    const { conversationId } = req.params;
    const { text } = req.body;

    if (!isValidObjectId(conversationId)) {
      return res.status(400).json({ message: "Gecersiz konusma id." });
    }

    if (!text || !text.trim()) {
      return res.status(400).json({ message: "Mesaj metni gereklidir." });
    }

    if (text.trim().length > 2000) {
      return res.status(400).json({ message: "Mesaj en fazla 2000 karakter olabilir." });
    }

    const conversation = await Conversation.findOne({
      _id: conversationId,
      participants: currentUserId,
    });

    if (!conversation) {
      return res.status(404).json({ message: "Konusma bulunamadi." });
    }

    const message = await Message.create({
      conversation: conversationId,
      sender: currentUserId,
      text: text.trim(),
      read: false,
      readBy: [currentUserId],
    });

    conversation.lastMessage = message._id;
    await conversation.save();

    const populatedMessage = await Message.findById(message._id).populate(
      "sender",
      "_id fullName username profileImage"
    );

    return res.status(201).json({ message: populatedMessage });
  } catch (error) {
    return res.status(500).json({
      message: "Mesaj gonderilirken hata olustu.",
      error: error.message,
    });
  }
};

const markMessagesAsRead = async (req, res) => {
  try {
    const currentUserId = req.user._id;
    const { conversationId } = req.params;

    if (!isValidObjectId(conversationId)) {
      return res.status(400).json({ message: "Gecersiz konusma id." });
    }

    const conversation = await Conversation.findOne({
      _id: conversationId,
      participants: currentUserId,
    });

    if (!conversation) {
      return res.status(404).json({ message: "Konusma bulunamadi." });
    }

    const result = await Message.updateMany(
      {
        conversation: conversationId,
        sender: { $ne: currentUserId },
        read: { $ne: true },
      },
      {
        $set: { read: true },
        $addToSet: { readBy: currentUserId },
      }
    );

    return res.status(200).json({
      message: "Mesajlar okundu olarak isaretlendi.",
      modifiedCount: result.modifiedCount || 0,
    });
  } catch (error) {
    return res.status(500).json({
      message: "Mesajlar okundu olarak isaretlenirken hata olustu.",
      error: error.message,
    });
  }
};

module.exports = {
  getOrCreateConversation,
  getConversations,
  getUnreadCount,
  getMessages,
  sendMessage,
  markMessagesAsRead,
};
