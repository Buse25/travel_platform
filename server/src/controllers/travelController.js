const Travel = require("../models/Travel");

const createTravel = async (req, res) => {
  try {
    console.log("[createTravel] req.user:", req.user);
    console.log("[createTravel] req.body:", req.body);

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

    console.log("[createTravel] Seyahat oluşturuldu:", travel._id);

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
    console.log("[getMyTravels] userId:", req.user._id);

    const travels = await Travel.find({ user: req.user._id }).sort({ createdAt: -1 });

    console.log("[getMyTravels] Bulunan seyahat sayısı:", travels.length);

    res.status(200).json(travels);
  } catch (error) {
    console.error("[getMyTravels] Hata:", error.message);
    res.status(500).json({
      message: "Seyahatler alınırken hata oluştu.",
      error: error.message,
    });
  }
};

module.exports = { createTravel, getMyTravels };