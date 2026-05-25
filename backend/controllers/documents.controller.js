// controllers/documents.controller.js
const db   = require('../config/db');
const path = require('path');
const fs   = require('fs');

exports.upload = async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: 'No file uploaded' });
    const { doc_type } = req.body;
    const employeeId = req.body.employee_id || req.user.id;

    // Only admins can upload for others
    if (parseInt(employeeId) !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Access denied' });
    }

    const { rows } = await db.query(
      `INSERT INTO documents (employee_id, doc_type, file_path, original_name, file_size)
       VALUES ($1,$2,$3,$4,$5) RETURNING *`,
      [employeeId, doc_type || 'other',
       `/uploads/documents/${req.file.filename}`,
       req.file.originalname, req.file.size]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Could not save document' });
  }
};

exports.getMine = async (req, res) => {
  try {
    const { rows } = await db.query(
      'SELECT * FROM documents WHERE employee_id=$1 ORDER BY uploaded_at DESC',
      [req.user.id]
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: 'Could not fetch documents' });
  }
};

exports.getForEmployee = async (req, res) => {
  try {
    const { id } = req.params;
    if (req.user.role === 'employee' && req.user.id !== parseInt(id)) {
      return res.status(403).json({ error: 'Access denied' });
    }
    const { rows } = await db.query(
      'SELECT * FROM documents WHERE employee_id=$1 ORDER BY uploaded_at DESC', [id]
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: 'Could not fetch documents' });
  }
};

exports.deleteDoc = async (req, res) => {
  try {
    const { id } = req.params;
    const { rows } = await db.query('SELECT * FROM documents WHERE id=$1', [id]);
    if (!rows.length) return res.status(404).json({ error: 'Document not found' });

    const doc = rows[0];
    if (req.user.role !== 'admin' && doc.employee_id !== req.user.id) {
      return res.status(403).json({ error: 'Access denied' });
    }

    // Delete file from disk
    const filePath = path.join(__dirname, '..', doc.file_path);
    if (fs.existsSync(filePath)) fs.unlinkSync(filePath);

    await db.query('DELETE FROM documents WHERE id=$1', [id]);
    res.json({ message: 'Document deleted' });
  } catch (err) {
    res.status(500).json({ error: 'Could not delete document' });
  }
};
