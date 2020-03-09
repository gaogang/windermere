import GitHub from './Repos/GitHub';
import { stat } from 'fs';

export default class We {
    constructor(argv) {
        this._argv = argv;
    }

    run() {
        const result = this.parseArgv();
        
        if (result.status === 'error') {
            console.error(result.message);
            return;
        }

        console.info('Creating application - ' + result.appName);

        const githubAddr = 'test';
        const github = new GitHub(githubAddr);
        
        github.create();
    }

    parseArgv() {
        var status = 'success';
        var message = '';
        var appName = '';

        const numOfArgs = this._argv.length;

        this._argv.forEach((val, index) => {
            if (val === '-a' &&
                numOfArgs > index + 1) {
                appName = this._argv[index + 1];
            }
        });

        if (appName === '') {
            return {
                status: 'error',
                message: 'Please provide the name of the app'
            };
        }

        if (status === 'success') {
            return {
                status: status,
                appName: appName
            };
        }

        return {
            status: status,
            message: message
        };
    }
}