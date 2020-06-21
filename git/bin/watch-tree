const { spawn, execSync } = require("child_process");
const proc = spawn("inotifywait", ["-m", "-e", "close_write", "-r", "subrepos"]);

function handle_line(line)
{
    let [path, events, file] = line.split(/ /);
    events = events.split(",");
    for (let event of events) {
	if (event === "CLOSE_WRITE") {
	    let subrepo = path.match(/^subrepos\/([^\/]*)\//)[1];
	    console.log(subrepo);
	    execSync(`touch stamp/subrepos/${subrepo}`);
	}
    }
}

execSync(`mkdir -p stamp/subrepos/`);
let indata = "";
proc.stdout.on("data", data => {
    indata += data.toString();
    let m;
    while (m = indata.match(/^(.*?)\n(.*)$/)) {
	handle_line (m[1]);
	indata = m[2];
    }
});
