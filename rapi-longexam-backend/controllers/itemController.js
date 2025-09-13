const Item = require("../models/Item");

const getItems = async (req, res) => {
  try {
    const items = await Item.find();
    res.json({ items });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const createItem = async (req, res) => {
  try {
    const { name, description, photoUrl, qtyTotal, qtyAvailable, isActive } =
      req.body;

    if (!name) return res.status(400).json({ message: "Name is required" });

    const total = Number(qtyTotal ?? 0);
    const avail = Number(qtyAvailable ?? total);

    if (total < 0 || avail < 0)
      return res.status(400).json({ message: "Quantities must be >= 0" });

    if (avail > total)
      return res
        .status(400)
        .json({ message: "qtyAvailable cannot exceed qtyTotal" });

    const item = await Item.create({
      name,
      description: description ?? "",
      photoUrl: photoUrl ?? "",
      qtyTotal: total,
      qtyAvailable: avail,
      isActive: isActive ?? true,
    });
    res.status(201).json(item);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

const updateItem = async (req, res) => {
  try {
    const payload = { ...req.body };

    // Validate qty relationship if either is present
    if (payload.qtyTotal !== undefined || payload.qtyAvailable !== undefined) {
      const current = await Item.findById(req.params.id);
      if (!current) return res.status(404).json({ message: "Item not found" });

      const total =
        payload.qtyTotal !== undefined
          ? Number(payload.qtyTotal)
          : current.qtyTotal;
      const avail =
        payload.qtyAvailable !== undefined
          ? Number(payload.qtyAvailable)
          : current.qtyAvailable;

      if (total < 0 || avail < 0)
        return res
          .status(400)
          .json({ message: "Quantities must be >= 0" });
      if (avail > total)
        return res
          .status(400)
          .json({ message: "qtyAvailable cannot exceed qtyTotal" });

      payload.qtyTotal = total;
      payload.qtyAvailable = avail;
    }

    const item = await Item.findByIdAndUpdate(req.params.id, payload, {
      new: true,
    });
    if (!item) return res.status(404).json({ message: "Item not found" });

    res.json(item);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

const deleteItem = async (req, res) => {
  try {
    await Item.findByIdAndDelete(req.params.id);
    res.json({ message: "Item deleted successfully" });
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

module.exports = { getItems, createItem, updateItem, deleteItem };
