/**
 * Mount all API routers — single place to see the surface area.
 */
const adminRoutes = require('./routes/admin');
const authRoutes = require('./routes/auth');
const couponsRoutes = require('./routes/coupons');
const offersRoutes = require('./routes/offers');
const bookingsRoutes = require('./routes/bookings');
const badgesRoutes = require('./routes/badges');
const businessRoutes = require('./routes/business');
const categoriesRoutes = require('./routes/categories');
const eventsRoutes = require('./routes/events');
const feedRoutes = require('./routes/feed');
const interestsRoutes = require('./routes/interests');
const placesRoutes = require('./routes/places');
const profileRoutes = require('./routes/profile');
const savedPlacesRoutes = require('./routes/saved_places');
const toursRoutes = require('./routes/tours');
const tripsRoutes = require('./routes/trips');
const tripSharesRoutes = require('./routes/trip_shares');
const audioGuidesRoutes = require('./routes/audio_guides');
const uploadRoutes = require('./routes/upload');
const aiRoutes = require('./routes/ai');
const reviewsRoutes = require('./routes/reviews');
const directionsRoutes = require('./routes/directions');

function registerRoutes(app) {
  app.use('/api/auth', authRoutes);
  app.use('/api/coupons', couponsRoutes);
  app.use('/api/offers', offersRoutes);
  // Web parity aliases
  app.use('/api/promotions', offersRoutes);
  app.use('/api/messages', offersRoutes);
  app.use('/api/proposals', offersRoutes);
  app.use('/api/bookings', bookingsRoutes);
  app.use('/api/badges', badgesRoutes);
  app.use('/api/admin', adminRoutes);
  app.use('/api/places', placesRoutes);
  app.use('/api/categories', categoriesRoutes);
  app.use('/api/tours', toursRoutes);
  app.use('/api/events', eventsRoutes);
  app.use('/api/interests', interestsRoutes);
  app.use('/api/user', profileRoutes);
  app.use('/api/user', savedPlacesRoutes);
  app.use('/api/user', tripsRoutes);
  app.use('/api/trip-shares', tripSharesRoutes);
  app.use('/api/audio-guides', audioGuidesRoutes);
  app.use('/api/feed', feedRoutes);
  app.use('/api/business', businessRoutes);
  app.use('/api/upload', uploadRoutes);
  app.use('/api/ai', aiRoutes);
  app.use('/api/reviews', reviewsRoutes);
  app.use('/api/directions', directionsRoutes);
}

module.exports = { registerRoutes };
