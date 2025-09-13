const mongoose = require("mongoose");

const itemSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
    },
    description: {
      type: [String],
      default: [""],
    },
    photoUrl: {
      type: String,
      default: "",
    },
    qtyTotal: {
      type: Number,
      required: true,
      min: 0,
    },
    qtyAvailable: {
      type: Number,
      required: true,
      min: 0,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.models.Item || mongoose.model("Item", itemSchema);
