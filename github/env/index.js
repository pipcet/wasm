const fs = require("fs");
fs.appendFileSync(process.env.GITHUB_ENV, `ACTIONS_RUNTIME_URL=${process.env.ACTIONS_RUNTIME_URL}`);
fs.appendFileSync(process.env.GITHUB_ENV, `ACTIONS_RUNTIME_TOKEN=${process.env.ACTIONS_RUNTIME_TOKEN}`);
fs.appendFileSync(process.env.GITHUB_ENV, `GITHUB_RUN_ID=${process.env.GITHUB_RUN_ID}`);
