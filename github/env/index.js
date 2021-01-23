const fs = require("fs");
fs.appendFile(process.env.GITHUB_ENV, `ACTIONS_RUNTIME_URL=${process.env.ACTIONS_RUNTIME_URL}`);
fs.appendFile(process.env.GITHUB_ENV, `ACTIONS_RUNTIME_TOKEN=${process.env.ACTIONS_RUNTIME_TOKEN}`);
fs.appendFile(process.env.GITHUB_ENV, `GITHUB_RUN_ID=${process.env.GITHUB_RUN_ID}`);
