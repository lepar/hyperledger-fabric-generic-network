'use strict';

import { OperationsManager } from './controllers/Operations';


module.exports = function(app: any) {
    
    // var users = require('./controllers/UserManager');
    const operation: OperationsManager = new OperationsManager();

    // Route the webservices
    app.route('/invoke').post(operation.invoke);
    app.route('/query').post(operation.query);
}
