function toArray(value) {
  if (Array.isArray(value)) return value;
  if (value == null) return [];
  if (typeof value === 'string') {
    try {
      const parsed = JSON.parse(value);
      return Array.isArray(parsed) ? parsed : [];
    } catch {
      return [];
    }
  }
  return [];
}

function withTranslation(baseDoc, translationDoc, fields) {
  const out = { ...baseDoc };
  for (const field of fields) {
    if (translationDoc && translationDoc[field] != null && translationDoc[field] !== '') {
      out[field] = translationDoc[field];
    }
  }
  return out;
}

async function loadTranslationMap(translationCollection, idField, ids, lang) {
  if (!lang || lang === 'en' || ids.length === 0) return new Map();
  const rows = await translationCollection
    .find({ [idField]: { $in: ids }, lang }, { projection: { _id: 0 } })
    .toArray();
  return new Map(rows.map((row) => [row[idField], row]));
}

module.exports = {
  toArray,
  withTranslation,
  loadTranslationMap,
};
