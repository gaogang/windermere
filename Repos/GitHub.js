export default class GitHub { 
    constructor(url) {
        if (url === undefined ||
            url === null || 
            url === '') {
                throw 'Github url is missing';
        }
        this._url = url;
    }

    create () {
        console.log('Creating github @ ' + this._url);
    }
}