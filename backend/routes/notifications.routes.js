// routes/notifications.routes.js
const router = require('express').Router();
const ctrl   = require('../controllers/notifications.controller');
const auth   = require('../middleware/auth');
const rbac   = require('../middleware/rbac');

router.get ('/mine',           auth, ctrl.getMine);
router.get ('/unread-count',   auth, ctrl.getUnreadCount);
router.patch('/:id/read',      auth, ctrl.markRead);
router.patch('/read-all',      auth, ctrl.markAllRead);
router.post ('/announce',      auth, rbac('admin'), ctrl.announce);
router.get  ('/announcements', auth, ctrl.getAnnouncements);

module.exports = router;
