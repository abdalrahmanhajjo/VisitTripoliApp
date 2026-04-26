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

function withTranslation(baseDoc, translationDoc, fields, explicitLang) {
  const out = { ...baseDoc };
  if (!baseDoc) return out;

  const lang = explicitLang || (translationDoc && translationDoc._lang) || (translationDoc && translationDoc.lang);
  
  if (!lang || lang === 'en') return out;
  
  const embeddedTr = baseDoc.translations && baseDoc.translations[lang];
  const trToUse = embeddedTr || translationDoc;

  if (!trToUse) return out;

  for (const field of fields) {
    if (trToUse[field] != null && trToUse[field] !== '') {
      out[field] = trToUse[field];
    }
  }
  return out;
}

async function loadTranslationMap(translationCollection, idField, ids, lang) {
  const map = new Map();
  if (!lang || lang === 'en' || !ids || ids.length === 0) return map;
  
  const rows = await translationCollection
    .find({ [idField]: { $in: ids }, lang }, { projection: { _id: 0 } })
    .toArray();
    
  for (const row of rows) {
    map.set(row[idField], { ...row, _lang: lang });
  }
  
  for (const id of ids) {
    if (!map.has(id)) {
      map.set(id, { _lang: lang });
    }
  }
  
  return map;
}

module.exports = {
  toArray,
  withTranslation,
  loadTranslationMap,
};
