const mongoose = require("mongoose");

const travelSchema = new mongoose.Schema(
    {
        user: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true,
        },
        country: {
            type: String,
            required: true,
            trim: true,
        },
        city: {
            type: String,
            required: true,
            trim: true,
        },
        district: {
            type: String,
            trim: true,
            default: "",
        },
        startDate: {
            type: Date,
            required: true,
        },
        endDate: {
            type: Date,
            required: true,
        },
        purpose: {
            type: String,
            required: true,
            enum: ["Turistik", "Eğitim", "Aile ziyareti", "İş"],
        },
        category: {
            type: String,
            required: true,
            enum: ["Kültürel", "Business", "Gastronomi", "Doğa", "Tarihi"],
        },
        description: {
            type: String,
            required: true,
            maxlength: 1500,
            trim: true,
        },
        ticketPhoto: {
            type: String,
            default: "",
        },
        locationPhoto: {
            type: String,
            default: "",
        },
        tags: {
            type: [String],
            default: [],
        },
        verificationStatus: {
            type: String,
            enum: ["Beklemede", "Onaylandı", "Reddedildi"],
            default: "Beklemede",
        },
    },
    { timestamps: true }
);

module.exports = mongoose.model("Travel", travelSchema);