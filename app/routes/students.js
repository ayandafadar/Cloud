/**
 * Student CRUD routes.
 * 
 * Data is stored in a plain array (in-memory).  Every restart
 * resets the data to the seed values below.  This is deliberate
 * for a demo project and is NOT suitable for production.
 */

const express = require('express');
const { v4: uuidv4 } = require('uuid');

const router = express.Router();

// ---------------------------------------------------------------------------
// In-memory data store with seed data
// ---------------------------------------------------------------------------
let students = [
  { id: '1', name: 'Alice Johnson', email: 'alice@university.edu', course: 'Computer Science', year: 3 },
  { id: '2', name: 'Bob Smith', email: 'bob@university.edu', course: 'Software Engineering', year: 2 },
  { id: '3', name: 'Charlie Brown', email: 'charlie@university.edu', course: 'Information Technology', year: 4 },
  { id: '4', name: 'Diana Prince', email: 'diana@university.edu', course: 'Data Science', year: 1 },
  { id: '5', name: 'Eve Williams', email: 'eve@university.edu', course: 'Cybersecurity', year: 3 },
];

// Expose the store for the v2 search endpoint
function getStore() {
  return students;
}

// ---------------------------------------------------------------------------
// Validation helpers
// ---------------------------------------------------------------------------
function validateStudent(body, isUpdate = false) {
  const errors = [];

  if (!isUpdate || body.name !== undefined) {
    if (!body.name || typeof body.name !== 'string' || body.name.trim().length < 2) {
      errors.push('name must be a string with at least 2 characters');
    }
  }

  if (!isUpdate || body.email !== undefined) {
    if (!body.email || typeof body.email !== 'string' || !body.email.includes('@')) {
      errors.push('email must be a valid email address');
    }
  }

  if (!isUpdate || body.course !== undefined) {
    if (!body.course || typeof body.course !== 'string' || body.course.trim().length < 2) {
      errors.push('course must be a string with at least 2 characters');
    }
  }

  if (!isUpdate || body.year !== undefined) {
    if (body.year === undefined || typeof body.year !== 'number' || body.year < 1 || body.year > 6) {
      errors.push('year must be a number between 1 and 6');
    }
  }

  return errors;
}

// ---------------------------------------------------------------------------
// Routes
// ---------------------------------------------------------------------------

/**
 * GET /api/students
 * Returns all students.
 */
router.get('/', (req, res) => {
  res.json({
    count: students.length,
    students,
  });
});

/**
 * GET /api/students/:id
 * Returns one student or 404.
 */
router.get('/:id', (req, res) => {
  const student = students.find(s => s.id === req.params.id);

  if (!student) {
    return res.status(404).json({
      error: 'Not Found',
      message: `Student with id '${req.params.id}' not found`,
    });
  }

  res.json(student);
});

/**
 * POST /api/students
 * Creates a student with input validation.
 */
router.post('/', (req, res) => {
  const errors = validateStudent(req.body);

  if (errors.length > 0) {
    return res.status(400).json({
      error: 'Validation Error',
      messages: errors,
    });
  }

  const newStudent = {
    id: uuidv4().slice(0, 8),
    name: req.body.name.trim(),
    email: req.body.email.trim(),
    course: req.body.course.trim(),
    year: req.body.year,
  };

  students.push(newStudent);

  res.status(201).json(newStudent);
});

/**
 * PUT /api/students/:id
 * Updates a student.
 */
router.put('/:id', (req, res) => {
  const index = students.findIndex(s => s.id === req.params.id);

  if (index === -1) {
    return res.status(404).json({
      error: 'Not Found',
      message: `Student with id '${req.params.id}' not found`,
    });
  }

  const errors = validateStudent(req.body, true);

  if (errors.length > 0) {
    return res.status(400).json({
      error: 'Validation Error',
      messages: errors,
    });
  }

  const updated = { ...students[index] };
  if (req.body.name) updated.name = req.body.name.trim();
  if (req.body.email) updated.email = req.body.email.trim();
  if (req.body.course) updated.course = req.body.course.trim();
  if (req.body.year !== undefined) updated.year = req.body.year;

  students[index] = updated;

  res.json(updated);
});

/**
 * DELETE /api/students/:id
 * Deletes a student.
 */
router.delete('/:id', (req, res) => {
  const index = students.findIndex(s => s.id === req.params.id);

  if (index === -1) {
    return res.status(404).json({
      error: 'Not Found',
      message: `Student with id '${req.params.id}' not found`,
    });
  }

  const deleted = students.splice(index, 1)[0];

  res.json({
    message: 'Student deleted successfully',
    student: deleted,
  });
});

// ---------------------------------------------------------------------------
// Reset helper for tests
// ---------------------------------------------------------------------------
function resetStore() {
  students = [
    { id: '1', name: 'Alice Johnson', email: 'alice@university.edu', course: 'Computer Science', year: 3 },
    { id: '2', name: 'Bob Smith', email: 'bob@university.edu', course: 'Software Engineering', year: 2 },
    { id: '3', name: 'Charlie Brown', email: 'charlie@university.edu', course: 'Information Technology', year: 4 },
    { id: '4', name: 'Diana Prince', email: 'diana@university.edu', course: 'Data Science', year: 1 },
    { id: '5', name: 'Eve Williams', email: 'eve@university.edu', course: 'Cybersecurity', year: 3 },
  ];
}

module.exports = { router, getStore, resetStore };
