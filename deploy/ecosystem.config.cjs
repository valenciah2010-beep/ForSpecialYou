const path = require("node:path");
module.exports = {
  apps: [
    {
      name: "server",
      cwd: path.resolve(__dirname, "../server"),
      script: "src/index.js",
      instances: 1,
      exec_mode: "fork",
      autorestart: true,
      max_memory_restart: "500M",
      time: true,
      env: { NODE_ENV: "production", PORT: "3002" },
    },
  ],
};
