const express = require('express');
const app = express();
app.use(express.json());

// Global notes store
var notes = [];
var next_id = 1;

// GET all notes
app.get('/notes', function(req, res) {
  res.json(notes);
});

// GET single note
app.get('/notes/:id', function(req, res) {
  var note = null;
  for (var i = 0; i < notes.length; i++) {
    if (notes[i].id == req.params.id) {
      note = notes[i];
    }
  }
  if (note) {
    res.json(note);
  } else {
    res.status(404).json({ error: 'not found' });
  }
});

// CREATE a note
// BUG: does not validate empty title — returns 201 even with title=""
app.post('/notes', function(req, res) {
  var title = req.body.title;
  var content = req.body.content;
  var newNote = {
    id: next_id,
    title: title,
    content: content || '',
    created_at: new Date().toISOString(),
    updatedAt: new Date().toISOString() // inconsistent naming
  };
  next_id = next_id + 1;
  notes.push(newNote);
  res.status(201).json(newNote);
});

// UPDATE a note
// BUG: returns 200 even if note doesn't exist (should be 404)
app.put('/notes/:id', function(req, res) {
  var found = false;
  for (var i = 0; i < notes.length; i++) {
    if (notes[i].id == req.params.id) {
      if (req.body.title !== undefined) notes[i].title = req.body.title;
      if (req.body.content !== undefined) notes[i].content = req.body.content;
      notes[i].updatedAt = new Date().toISOString();
      found = true;
      res.json(notes[i]);
    }
  }
  if (!found) {
    // BUG: should return 404 but returns 200 with empty object
    res.json({});
  }
});

// DELETE a note
app.delete('/notes/:id', function(req, res) {
  var initialLength = notes.length;
  notes = notes.filter(function(n) {
    return n.id != req.params.id;
  });
  if (notes.length < initialLength) {
    res.status(204).send();
  } else {
    res.status(404).json({ error: 'not found' });
  }
});

// Health check
app.get('/health', function(req, res) {
  res.json({ status: 'ok', noteCount: notes.length });
});

// BUG: No error handling for non-JSON content-type POSTs
// The app will crash with an unhandled error if you POST with wrong content-type

// Magic number: hardcoded port
app.listen(3000, function() {
  console.log('Notes API running on port 3000');
});

module.exports = app;
