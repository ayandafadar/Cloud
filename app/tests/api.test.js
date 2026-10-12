/**
 * Automated tests for the Blue-Green Deployment Demo API.
 * 
 * Uses Jest + Supertest to exercise every endpoint, including
 * validation, error handling, and 404 scenarios.
 */

const request = require('supertest');
const app = require('../app');
const { resetStore } = require('../routes/students');

// Reset the in-memory store before each test to guarantee isolation
beforeEach(() => {
  resetStore();
});

// ============================================================================
// Root endpoint
// ============================================================================
describe('GET /', () => {
  it('should return application info with 200', async () => {
    const res = await request(app).get('/');
    expect(res.status).toBe(200);
    expect(res.body.application).toBe('DeployShift \u2014 Blue-Green Deployment Demo API');
    expect(res.body.version).toBeDefined();
    expect(res.body.environment).toBeDefined();
    expect(res.body.status).toBe('running');
    expect(res.body.instanceId).toBeDefined();
  });

  it('should return visual console on GET /console', async () => {
    const res = await request(app).get('/console');
    expect(res.status).toBe(200);
    expect(res.text).toContain('DeployShift');
    expect(res.text).toContain('Blue-Green Kubernetes Live Console');
  });
});

// ============================================================================
// Health endpoint
// ============================================================================
describe('GET /health', () => {
  it('should return healthy status', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('healthy');
    expect(res.body.version).toBeDefined();
    expect(res.body.uptime).toBeGreaterThanOrEqual(0);
  });
});

// ============================================================================
// Readiness endpoint
// ============================================================================
describe('GET /ready', () => {
  it('should return ready status', async () => {
    const res = await request(app).get('/ready');
    expect(res.status).toBe(200);
    expect(res.body.ready).toBe(true);
    expect(res.body.checks.server).toBe('up');
    expect(res.body.checks.dataStore).toBe('available');
  });
});

// ============================================================================
// Version endpoint
// ============================================================================
describe('GET /api/version', () => {
  it('should return version information', async () => {
    const res = await request(app).get('/api/version');
    expect(res.status).toBe(200);
    expect(res.body.version).toBeDefined();
    expect(res.body.environment).toBeDefined();
    expect(res.body.instanceId).toBeDefined();
    expect(res.body.nodeVersion).toBeDefined();
    expect(res.body.capabilities).toEqual(expect.arrayContaining(['crud', 'health-checks']));
  });
});

// ============================================================================
// Student CRUD
// ============================================================================
describe('GET /api/students', () => {
  it('should return all seeded students', async () => {
    const res = await request(app).get('/api/students');
    expect(res.status).toBe(200);
    expect(res.body.count).toBe(5);
    expect(res.body.students).toHaveLength(5);
  });
});

describe('GET /api/students/:id', () => {
  it('should return a student by id', async () => {
    const res = await request(app).get('/api/students/1');
    expect(res.status).toBe(200);
    expect(res.body.name).toBe('Alice Johnson');
    expect(res.body.email).toBe('alice@university.edu');
  });

  it('should return 404 for non-existent id', async () => {
    const res = await request(app).get('/api/students/999');
    expect(res.status).toBe(404);
    expect(res.body.error).toBe('Not Found');
    expect(res.body.message).toContain('999');
  });
});

describe('POST /api/students', () => {
  it('should create a new student with valid data', async () => {
    const newStudent = {
      name: 'Frank Castle',
      email: 'frank@university.edu',
      course: 'Network Security',
      year: 2,
    };

    const res = await request(app)
      .post('/api/students')
      .send(newStudent);

    expect(res.status).toBe(201);
    expect(res.body.name).toBe('Frank Castle');
    expect(res.body.id).toBeDefined();

    // Verify persistence
    const listRes = await request(app).get('/api/students');
    expect(listRes.body.count).toBe(6);
  });

  it('should return 400 for missing name', async () => {
    const res = await request(app)
      .post('/api/students')
      .send({ email: 'x@y.com', course: 'CS', year: 1 });

    expect(res.status).toBe(400);
    expect(res.body.error).toBe('Validation Error');
    expect(res.body.messages).toEqual(expect.arrayContaining([
      expect.stringContaining('name'),
    ]));
  });

  it('should return 400 for invalid email', async () => {
    const res = await request(app)
      .post('/api/students')
      .send({ name: 'Test User', email: 'invalid', course: 'CS', year: 1 });

    expect(res.status).toBe(400);
    expect(res.body.messages).toEqual(expect.arrayContaining([
      expect.stringContaining('email'),
    ]));
  });

  it('should return 400 for invalid year', async () => {
    const res = await request(app)
      .post('/api/students')
      .send({ name: 'Test User', email: 'a@b.com', course: 'CS', year: 10 });

    expect(res.status).toBe(400);
    expect(res.body.messages).toEqual(expect.arrayContaining([
      expect.stringContaining('year'),
    ]));
  });

  it('should return 400 for empty body', async () => {
    const res = await request(app)
      .post('/api/students')
      .send({});

    expect(res.status).toBe(400);
    expect(res.body.messages.length).toBeGreaterThanOrEqual(1);
  });
});

describe('PUT /api/students/:id', () => {
  it('should update an existing student', async () => {
    const res = await request(app)
      .put('/api/students/1')
      .send({ name: 'Alice Updated' });

    expect(res.status).toBe(200);
    expect(res.body.name).toBe('Alice Updated');
    expect(res.body.email).toBe('alice@university.edu'); // unchanged
  });

  it('should return 404 for non-existent student', async () => {
    const res = await request(app)
      .put('/api/students/999')
      .send({ name: 'Nobody' });

    expect(res.status).toBe(404);
  });

  it('should return 400 for invalid update data', async () => {
    const res = await request(app)
      .put('/api/students/1')
      .send({ year: 99 });

    expect(res.status).toBe(400);
  });
});

describe('DELETE /api/students/:id', () => {
  it('should delete an existing student', async () => {
    const res = await request(app).delete('/api/students/1');
    expect(res.status).toBe(200);
    expect(res.body.message).toContain('deleted');

    // Verify removal
    const listRes = await request(app).get('/api/students');
    expect(listRes.body.count).toBe(4);
  });

  it('should return 404 when deleting non-existent student', async () => {
    const res = await request(app).delete('/api/students/999');
    expect(res.status).toBe(404);
  });
});

// ============================================================================
// 404 for unknown routes
// ============================================================================
describe('Unknown routes', () => {
  it('should return 404 for unknown path', async () => {
    const res = await request(app).get('/api/nonexistent');
    expect(res.status).toBe(404);
    expect(res.body.error).toBe('Not Found');
  });
});

// ============================================================================
// Release Capability Gate (Test-Driven Blue-Green Deployment)
// ============================================================================
describe('Release Capability Gate: v2.0.0 Requirements', () => {
  // >>> CHANGE THIS ONE THING TO TRIGGER / SWITCH <<<
  // Set to '1.0.0' -> TEST PASSES for Blue (Baseline)
  // Set to '2.0.0' -> TEST FAILS on Blue! (Requires Green deploy)
  const targetRelease = '2.0.0';

  it(`should verify active release matches target ${targetRelease}`, async () => {
    const res = await request(app).get('/api/version');
    expect(res.status).toBe(200);
    expect(res.body.version).toBe(targetRelease);

    if (targetRelease === '2.0.0') {
      expect(res.body.capabilities).toContain('search');
    }
  });
});
