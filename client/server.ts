var express = require('express'),
    app = express(),
    //port number
    port = process.env.PORT || 3000,
    bodyParser = require('body-parser');

app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());

//importing route
var routes = require('./listRoutes'); 
 //register the route
routes(app);

app.listen(port);

console.log('RESTful API server started on: ' + port);
