'use strict';

import { OperationsManager } from './controllers/Operations';
import UserManager from './controllers/UserManager';


module.exports = function(app: any) {
    
    // var users = require('./controllers/UserManager');
    const userManager: UserManager = new UserManager();
    const operation: OperationsManager = new OperationsManager();

    // Enroll Admin and Register user
    app.route('/enrollAdmin').post(userManager.enrollAdmin);
    app.route('/registerUser').post(userManager.registerUser);

    // Route the webservices
    app.route('/invoke').post(operation.invoke);
    app.route('/query').post(operation.query);
}
