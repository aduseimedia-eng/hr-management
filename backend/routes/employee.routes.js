// routes/employee.routes.js
const router = require('express').Router();
const ctrl   = require('../controllers/employee.controller');
const auth   = require('../middleware/auth');
const rbac   = require('../middleware/rbac');
const { uploadPhoto } = require('../config/multer');

router.get  ('/dashboard',          auth, rbac('admin','manager'), ctrl.getDashboard);
router.get  ('/departments',        auth, ctrl.getDepartments);
router.get  ('/directory',          auth, ctrl.getDirectory);
router.get  ('/',                   auth, rbac('admin','manager'), ctrl.getAll);
router.post ('/',                   auth, rbac('admin'), ctrl.create);
router.get  ('/:id',                auth, ctrl.getById);
router.put  ('/:id',                auth, ctrl.update);
router.patch('/:id/deactivate',     auth, rbac('admin'), ctrl.deactivate);
router.post ('/me/photo',           auth, uploadPhoto.single('photo'), ctrl.uploadPhoto);

module.exports = router;
