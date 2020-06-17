const artifact = require('@actions/artifact');
const client = artifact.create();
const name = process.argv[2];
async function main()
{
    console.log(await client.downloadArtifact(name, `artifact/${name}.new`, {
	continueOnError: false,
	createArtifactFolder: false,
    }));
}

main();
