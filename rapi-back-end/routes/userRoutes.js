const express = require("express");

const {
  getUsers,
  createUser,
  updateUser,
  deleteUser,
  loginUser,
  changePassword,
  deleteAccount,
  updateUsername,
} = require("../controllers/userController");

const router = express.Router();

router.route("/").get(getUsers).post(createUser);

router.route("/:id").put(updateUser).delete(deleteUser);

router.post("/login", loginUser);

router.post("/change-password", changePassword);

router.post("/delete-account", deleteAccount);

router.post("/update-username", updateUsername);

module.exports = router;
