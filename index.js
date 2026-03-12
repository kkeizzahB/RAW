const express = require("express");
const cors = require("cors");
const fs = require('fs');
const path = require('path');
const app = express();

app.use(cors());
app.use(express.json());
app.set("json spaces", 2);

// Serve JSON files from Apis directory
app.get('/:filename', (req, res) => {
  const filename = req.params.filename;
  
  // Only serve .json files
  if (!filename.endsWith('.json')) {
    return res.status(404).json({ error: 'Not found' });
  }

  const filePath = path.join(__dirname, 'Apis', filename);

  if (fs.existsSync(filePath)) {
    try {
      const jsonData = JSON.parse(fs.readFileSync(filePath, 'utf8'));
      res.json(jsonData);
    } catch (error) {
      res.status(500).json({ error: 'Error reading file' });
    }
  } else {
    res.status(404).json({ error: 'File not found' });
  }
});

// Root route to show available endpoints
app.get('/', (req, res) => {
  try {
    const files = fs.readdirSync(path.join(__dirname, 'Apis'))
      .filter(file => file.endsWith('.json'));
    
    res.json({
      endpoints: files.map(file => ({
        file,
        url: `/${file}`
      }))
    });
  } catch (error) {
    res.json({ endpoints: [] });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

module.exports = app;