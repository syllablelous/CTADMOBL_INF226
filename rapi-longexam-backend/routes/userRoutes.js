const express = require("express");
const {
  getUsers,
  createUser,
  loginUser,
} = require("../controllers/userController");

const router = express.Router();

router.route("/").get(getUsers).post(createUser);
router.post("/login", loginUser);

module.exports = router;
