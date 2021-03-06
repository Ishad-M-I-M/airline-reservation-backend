const express = require('express');
const app = express();
const path = require('path');
const session = require('express-session');
const cors = require('cors');

const KnexSessionStore = require('connect-session-knex')(session);
require('dotenv').config({
    path:'../.env'
});

var corsOptions = {
    origin: 'https://airline-reservation-frontend.vercel.app',
    optionsSuccessStatus: 200, // For legacy browser support
    credentials: true
}

app.use(cors(corsOptions));

// controllers
const airportController = require('./controllers/airportController');
const routeController = require('./controllers/routeController');
const aircraftController = require('./controllers/aircraftController');
const flightScheduleController = require('./controllers/flightScheduleController');
const reportController = require('./controllers/reportController');
const discountController = require('./controllers/discountController');
const authController = require('./controllers/authController');
const userController = require('./controllers/userController');
const controller = require('./controllers/controller');


const db = require('./db');
// app.use(express.static(path.join(__dirname, 'build')));
app.use(express.json());

const sessionStore = new KnexSessionStore({
    knex: db,
    clearInterval : (365 * 86400 * 1000),
    disableDbCleanup: true
});

app.use(session({
    key: 'fsasfsfafawfrhykuytjdafapsovapjv32fq',
    secret: 'abc2idnoin2^*(doaiwu',
    store: sessionStore,
    resave: false,
    saveUninitialized: false,
    cookie : {
        maxAge: (365 * 86400 * 1000),
        httpOnly: false,
    }
}));

app.use('/api/airport', airportController );
app.use('/api/route', routeController );
app.use('/api/aircraft', aircraftController);
app.use('/api/flightSchedule', flightScheduleController);
app.use('/api/report', reportController);
app.use('/api/discount', discountController);
app.use('/api/auth', authController);
app.use('/api/user', userController);
app.use('/api/', controller);

// app.get('/', function(req, res) {
//     res.sendFile(path.join(__dirname, 'build', 'index.html'))
// });

app.listen(process.env.PORT || 3001);

console.log("Testing server");
