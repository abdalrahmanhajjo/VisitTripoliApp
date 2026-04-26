const { MongoClient } = require('mongodb');
require('dotenv').config();

async function fixTours() {
  const uri = process.env.MONGODB_URI;
  if (!uri) return console.error('No MONGODB_URI');
  const client = new MongoClient(uri);
  await client.connect();
  const db = client.db();
  
  const tours = await db.collection('tours').find({}).toArray();
  let updated = 0;
  for (const t of tours) {
    if ((!t.itinerary || !t.itinerary.length) && Array.isArray(t.place_ids) && t.place_ids.length > 0) {
      const places = await db.collection('places').find({ id: { $in: t.place_ids } }).toArray();
      const placeMap = new Map(places.map(p => [p.id, p]));
      const newItinerary = t.place_ids.map((pId, idx) => {
        const place = placeMap.get(pId);
        return {
          day: `Day ${idx + 1}`,
          title: `Visit ${place?.name || 'Destination'}`,
          description: place?.short_description || place?.description || `Explore ${place?.name || 'this location'}.`,
          time: 'Flexible'
        };
      });
      await db.collection('tours').updateOne({ _id: t._id }, { $set: { itinerary: newItinerary } });
      updated++;
    }
  }
  await client.close();
  console.log(`Updated ${updated} tours`);
}

fixTours().catch(console.error);
