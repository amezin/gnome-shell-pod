#!/usr/bin/env node

const stream = require('node:stream');
const yargs = require('yargs/yargs');

const Octokit = require('@octokit/core').Octokit.plugin(
    require('@octokit/plugin-paginate-rest').paginateRest,
    require('@octokit/plugin-throttling').throttling,
    require('@octokit/plugin-retry').retry,
    require('@octokit/plugin-request-log').requestLog,
)

async function main() {
    const args = yargs(require('yargs/helpers').hideBin(process.argv))
        .option('token', {
            alias: 't',
            demandOption: true,
            describe: 'GitHub API token',
            type: 'string',
            requiresArg: true,
            default: process.env.GITHUB_TOKEN,
            defaultDescription: '$GITHUB_TOKEN',
        })
        .option('repository', {
            alias: 'r',
            demandOption: true,
            describe: 'GitHub repository name',
            type: 'string',
            requiresArg: true,
            default: process.env.GITHUB_REPOSITORY,
            defaultDescription: '$GITHUB_REPOSITORY',
        })
        .option('owner', {
            alias: 'o',
            demandOption: true,
            describe: 'Package owner',
            type: 'string',
            requiresArg: true,
            default: process.env.GITHUB_REPOSITORY_OWNER,
            defaultDescription: '$GITHUB_REPOSITORY_OWNER',
        })
        .option('api-url', {
            alias: 'u',
            demandOption: true,
            describe: 'GitHub API base URL',
            type: 'string',
            requiresArg: true,
            default: process.env.GITHUB_API_URL || 'https://api.github.com',
            defaultDescription: '$GITHUB_API_URL or https://api.github.com',
        })
        .option('log-level', {
            alias: 'v',
            demandOption: true,
            describe: 'Console log level',
            choices: ['trace', 'debug', 'info', 'warn', 'error', 'fatal'],
            requiresArg: true,
            default: 'info',
        })
        .option('dry-run', {
            alias: 'n',
            type: 'boolean',
            describe: 'Do not delete packages, only print URLs',
        })
        .option('jobs', {
            alias: 'j',
            demandOption: true,
            describe: 'Concurrency level',
            type: 'number',
            requiresArg: true,
            default: 1,
        })
        .strict()
        .argv;

    const octokit = new Octokit({
        auth: args.token,
        baseUrl: args.apiUrl,
        log: require('console-log-level')({
            level: args.logLevel,
        }),
        throttle: {
            onRateLimit: (retryAfter, options, octokit) => {
                octokit.log.warn(
                    `Request quota exhausted for request ${options.method} ${options.url}`
                );

                if (options.request.retryCount === 0) {
                    // only retries once
                    octokit.log.info(`Retrying after ${retryAfter} seconds!`);
                    return true;
                }
            },
            onSecondaryRateLimit: (retryAfter, options, octokit) => {
                // does not retry, only logs a warning
                octokit.log.warn(
                    `SecondaryRateLimit detected for request ${options.method} ${options.url}`
                );
            },
        },
    });

    octokit.hook.after('request', async (response, options) => {
        octokit.log.debug(response);
    });

    const options = {
        concurrency: args.jobs,
    }

    const packages = stream.Readable.from(
        octokit.paginate.iterator(
            'GET /users/{username}/packages',
            {
                username: args.owner,
                package_type: 'container',
            }
        )
    ).flatMap(response => response.data);

    const repo_packages = packages.filter(
        package => (
            package.repository &&
            (
                package.repository.name === args.repository ||
                package.repository.full_name === args.repository
            )
        )
    );

    const versions = repo_packages.flatMap(
        package => octokit.paginate.iterator(
            'GET {+package_url}/versions',
            { package_url: package.url }
        ),
        options,
    ).flatMap(response => response.data);

    const untagged_versions = versions.filter(
        version => version.metadata.container.tags.length === 0
    );

    const deleted = await untagged_versions.map(version => {
        if (args.dryRun) {
            octokit.log.info(`DELETE ${version.url}`);
        } else {
            return octokit.request('DELETE {+version_url}', { version_url: version.url });
        }
    }, options).reduce(previous => previous + 1, 0);

    if (args.dryRun) {
        octokit.log.info(`Will delete ${deleted} package versions`);
    } else {
        octokit.log.info(`Deleted ${deleted} package versions`);
    }
}

main();
