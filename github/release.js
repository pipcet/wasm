const this_release_date = process.argv[2];
this_release_date = this_release_date.substr(1, this_release_date.length - 2)
const last_release_date = process.argv[3];
last_release_date = last_release_date.substr(1, this_release_date.length - 2)
const child_process = require("child_process");
const log = child_process.execSync(`git log ${last_release_date}..HEAD --pretty=format:'%H %s%b'`).toString() || "no changes";
const last_hash = child_process.execSync(`git rev-parse ${last_release_date}`).toString();
let json = {};
json.tag_name = this_release_date;
json.name = `${this_release_date} (automatic release)`;
json.prelease = true;
let body = `Changes since ${last_release_date} (${last_hash}):\n\n`;
body += log;
json.body = body;
console.log(JSON.stringify(json));