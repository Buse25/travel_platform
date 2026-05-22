const mongoose = require("mongoose");
const Travel = require("../models/Travel");

const APPROVED_STATUS = "Onayland\u0131";

const ALLOWED_VERIFICATION_STATUSES = ["Beklemede", "Onaylandı", "Reddedildi"];

const createTravel = async (req, res) => {
  try {
    const {
      country,
      city,
      district,
      startDate,
      endDate,
      purpose,
      category,
      description,
      ticketPhoto,
      locationPhoto,
    } = req.body;

    // Zorunlu alan kontrolü
    if (!country || !city || !startDate || !endDate || !purpose || !category || !description) {
      return res.status(400).json({
        message: "Zorunlu alanlar eksik.",
        missing: {
          country: !country,
          city: !city,
          startDate: !startDate,
          endDate: !endDate,
          purpose: !purpose,
          category: !category,
          description: !description,
        },
      });
    }

    if (description.length > 1500) {
      return res.status(400).json({ message: "Açıklama en fazla 1500 karakter olabilir." });
    }

    const parsedStartDate = new Date(startDate);
    const parsedEndDate = new Date(endDate);
    const today = new Date();
    today.setHours(23, 59, 59, 999);

    if (isNaN(parsedStartDate) || isNaN(parsedEndDate)) {
      return res.status(400).json({ message: "Geçersiz tarih formatı." });
    }

    if (parsedEndDate < parsedStartDate) {
      return res.status(400).json({ message: "Bitiş tarihi başlangıç tarihinden küçük olamaz." });
    }

    if (parsedStartDate > today || parsedEndDate > today) {
      return res.status(400).json({ message: "İleri tarihli seyahat eklenemez." });
    }

    const tags = [city.trim(), category.trim()];

    const travel = await Travel.create({
      user: req.user._id,
      country: country.trim(),
      city: city.trim(),
      district: district ? district.trim() : "",
      startDate: parsedStartDate,
      endDate: parsedEndDate,
      purpose,
      category,
      description: description.trim(),
      ticketPhoto: ticketPhoto || "",
      locationPhoto: locationPhoto || "",
      tags,
      verificationStatus: "Beklemede",
    });

    res.status(201).json({
      message: "Seyahat başarıyla eklendi.",
      travel,
    });
  } catch (error) {
    console.error("[createTravel] Hata:", error.message);
    res.status(500).json({
      message: "Seyahat oluşturulurken hata oluştu.",
      error: error.message,
    });
  }
};

const getMyTravels = async (req, res) => {
  try {
    const travels = await Travel.find({ user: req.user._id }).sort({ createdAt: -1 });

    res.status(200).json(travels);
  } catch (error) {
    console.error("[getMyTravels] Hata:", error.message);
    res.status(500).json({
      message: "Seyahatler alınırken hata oluştu.",
      error: error.message,
    });
  }
};

const getFeedTravels = async (req, res) => {
  try {
    const travels = await Travel.find({ verificationStatus: APPROVED_STATUS })
      .populate("user", "_id fullName username city profileImage")
      .sort({ createdAt: -1 })
      .limit(50);

    return res.status(200).json({
      source: "global",
      travels,
    });
  } catch (error) {
    return res.status(500).json({
      message: "Ana akis alinirken hata olustu.",
      error: error.message,
    });
  }
};

const getPendingTravels = async (req, res) => {
  try {
    const travels = await Travel.find({ verificationStatus: "Beklemede" })
      .populate("user", "_id fullName username city profileImage")
      .sort({ createdAt: -1 });

    return res.status(200).json({ travels });
  } catch (error) {
    return res.status(500).json({
      message: "Bekleyen seyahatler alınırken hata oluştu.",
      error: error.message,
    });
  }
};

const updateTravelVerificationStatus = async (req, res) => {
  try {
    const { travelId } = req.params;
    const bodyKeys = Object.keys(req.body || {});

    if (bodyKeys.length !== 1 || bodyKeys[0] !== "verificationStatus") {
      return res.status(400).json({
        message: "Sadece verificationStatus alanı güncellenebilir.",
      });
    }

    const { verificationStatus } = req.body;

    if (!ALLOWED_VERIFICATION_STATUSES.includes(verificationStatus)) {
      return res.status(400).json({ message: "Geçersiz onay durumu." });
    }

    if (!mongoose.Types.ObjectId.isValid(travelId)) {
      return res.status(400).json({ message: "Geçersiz seyahat id." });
    }

    const travel = await Travel.findByIdAndUpdate(
      travelId,
      {
        verificationStatus,
        reviewedAt: new Date(),
        reviewedBy: req.user._id,
      },
      { new: true, runValidators: true }
    ).populate("user", "_id fullName username city profileImage");

    if (!travel) {
      return res.status(404).json({ message: "Seyahat bulunamadı." });
    }

    return res.status(200).json({
      message: "Seyahat onay durumu güncellendi.",
      travel,
    });
  } catch (error) {
    return res.status(500).json({
      message: "Seyahat onay durumu güncellenirken hata oluştu.",
      error: error.message,
    });
  }
};

const getUserApprovedTravels = async (req, res) => {
  try {
    const { userId } = req.params;

    const travels = await Travel.find({
      user: userId,
      verificationStatus: "Onaylandı",
    }).sort({ createdAt: -1 });

    return res.status(200).json({ travels });
  } catch (error) {
    return res.status(500).json({
      message: "Kullanıcının seyahatleri alınırken hata oluştu.",
      error: error.message,
    });
  }
};
const searchTravels = async (req, res) => {
  try {
    const q = req.query.q?.trim();

    if (!q) {
      return res.status(400).json({ message: "Arama parametresi gereklidir." });
    }

    const travels = await Travel.find({
      verificationStatus: "Onaylandı",
      $or: [
        { country: { $regex: q, $options: "i" } },
        { city: { $regex: q, $options: "i" } },
        { district: { $regex: q, $options: "i" } },
        { purpose: { $regex: q, $options: "i" } },
        { category: { $regex: q, $options: "i" } },
        { description: { $regex: q, $options: "i" } },
        { tags: { $elemMatch: { $regex: q, $options: "i" } } },
      ],
    })
      .populate("user", "_id fullName username city profileImage")
      .sort({ createdAt: -1 })
      .limit(30);

    return res.status(200).json({ travels });
  } catch (error) {
    return res.status(500).json({
      message: "Seyahat araması sırasında hata oluştu.",
      error: error.message,
    });
  }
};
module.exports = {
  createTravel,
  getFeedTravels,
  getMyTravels,
  getPendingTravels,
  updateTravelVerificationStatus,
  searchTravels,
  getUserApprovedTravels,
};
