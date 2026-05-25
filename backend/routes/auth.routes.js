// routes/auth.routes.js
const router = require('express').Router();
const ctrl   = require('../controllers/auth.controller');
const auth   = require('../middleware/auth');

router.post('/login',           ctrl.login);
router.get ('/me',        auth, ctrl.getMe);
router.put ('/password',  auth, ctrl.changePassword);

module.exports = router;
