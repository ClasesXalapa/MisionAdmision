/**
 * Exportador opcional para la plantilla de Misión Admisión.
 * Se ejecuta dentro de Google Sheets y crea una carpeta en Drive con /content.
 */

const MA_VALID_ANSWERS = new Set(['A', 'B', 'C', 'D']);
const MA_VALID_DIFFICULTIES = new Set(['basico', 'intermedio', 'avanzado']);
const MA_VALID_CARD_TYPES = new Set([
  'video', 'pdf', 'formulario', 'simulacro', 'publicacion', 'anuncio',
]);
const MA_VERSION_PATTERN = /^[A-Za-z0-9._-]{1,100}$/;

function onOpen() {
  SpreadsheetApp.getUi()
    .createMenu('Misión Admisión')
    .addItem('Validar contenido', 'validarContenidoMisionAdmision')
    .addItem('Generar JSON en Drive', 'generarJsonMisionAdmision')
    .addToUi();
}

function validarContenidoMisionAdmision() {
  try {
    const documents = construirDocumentos_();
    const errors = validarDocumentos_(documents);
    if (errors.length) {
      SpreadsheetApp.getUi().alert(
        'Contenido inválido',
        errors.map((error) => `• ${error}`).join('\n'),
        SpreadsheetApp.getUi().ButtonSet.OK,
      );
      return;
    }
    SpreadsheetApp.getUi().alert(
      'Contenido válido',
      `${documents.questions.preguntas.length} preguntas, ` +
        `${documents.challenges.retos.length} retos, ` +
        `${documents.resources.cards.length} cards y ` +
        `${documents.ranks.rangos.length} rangos.`,
      SpreadsheetApp.getUi().ButtonSet.OK,
    );
  } catch (error) {
    SpreadsheetApp.getUi().alert(`No fue posible validar: ${error.message}`);
  }
}

function generarJsonMisionAdmision() {
  try {
    const documents = construirDocumentos_();
    const errors = validarDocumentos_(documents);
    if (errors.length) {
      SpreadsheetApp.getUi().alert(
        'No se generaron archivos',
        errors.map((error) => `• ${error}`).join('\n'),
        SpreadsheetApp.getUi().ButtonSet.OK,
      );
      return;
    }

    const timestamp = Utilities.formatDate(
      new Date(),
      Session.getScriptTimeZone(),
      'yyyyMMdd_HHmmss',
    );
    const root = DriveApp.createFolder(`Mision_Admision_JSON_${timestamp}`);
    const content = root.createFolder('content');
    const questions = content.createFolder('preguntas');
    const challenges = content.createFolder('retos');
    const cards = content.createFolder('cards');
    const config = content.createFolder('config');

    crearJson_(content, 'index.json', documents.index);
    crearJson_(questions, 'banco_global.json', documents.questions);
    crearJson_(challenges, 'retos_actuales.json', documents.challenges);
    crearJson_(cards, 'cards_actuales.json', documents.resources);
    crearJson_(config, 'rangos.json', documents.ranks);

    SpreadsheetApp.getUi().alert(
      'JSON generados',
      `Los archivos se guardaron en Drive:\n${root.getUrl()}\n\n` +
        'Antes de publicarlos, ejecuta python3 tool/validate_content.py.',
      SpreadsheetApp.getUi().ButtonSet.OK,
    );
  } catch (error) {
    SpreadsheetApp.getUi().alert(`No fue posible generar los JSON: ${error.message}`);
  }
}

function construirDocumentos_() {
  const config = config_();
  const required = [
    'content_version',
    'questions_version',
    'challenges_version',
    'cards_version',
    'ranks_version',
    'min_app_version',
  ];
  const missing = required.filter((key) => !text_(config[key]));
  if (missing.length) {
    throw new Error(`Config no contiene valores para: ${missing.join(', ')}.`);
  }

  const generatedAt = text_(config.generated_at) || new Date().toISOString();
  const questions = sheetObjects_('Preguntas').filter(active_).map((row) => ({
    id: text_(row.id),
    enunciado: text_(row.enunciado),
    imagen_url: nullable_(row.imagen_url),
    opciones: [
      text_(row.opcion_a),
      text_(row.opcion_b),
      text_(row.opcion_c),
      text_(row.opcion_d),
    ],
    respuesta_correcta: text_(row.respuesta_correcta).toUpperCase(),
    categoria: text_(row.categoria).toLowerCase(),
    etiquetas: list_(row.etiquetas, true),
    dificultad: text_(row.dificultad).toLowerCase(),
  }));

  const challenges = sheetObjects_('Retos').filter(active_).map((row) => ({
    id: text_(row.id),
    fecha: date_(row.fecha),
    titulo: text_(row.titulo),
    preguntas_ids: list_(row.preguntas_ids, false),
    recurso_resolucion: {
      tipo: text_(row.recurso_tipo).toLowerCase(),
      titulo: text_(row.recurso_titulo),
      url: text_(row.recurso_url),
    },
  }));

  const resources = sheetObjects_('Cards').filter(active_).map((row) => ({
    id: text_(row.id),
    titulo: text_(row.titulo),
    descripcion: text_(row.descripcion),
    tipo: text_(row.tipo).toLowerCase(),
    url: text_(row.url),
    imagen_url: nullable_(row.imagen_url),
    etiquetas: list_(row.etiquetas, true),
    prioridad: integer_(row.prioridad),
    fecha_publicacion: date_(row.fecha_publicacion),
    activa: true,
  }));

  const ranks = sheetObjects_('Rangos').filter(active_).map((row) => ({
    id: text_(row.id),
    nombre: text_(row.nombre),
    descripcion: text_(row.descripcion),
    racha_minima: integer_(row.racha_minima),
  }));

  return {
    questions: {
      schema_version: 1,
      version: text_(config.questions_version),
      generated_at: generatedAt,
      preguntas: questions,
    },
    challenges: {
      schema_version: 1,
      version: text_(config.challenges_version),
      generated_at: generatedAt,
      retos: challenges,
    },
    resources: {
      schema_version: 1,
      version: text_(config.cards_version),
      generated_at: generatedAt,
      cards: resources,
    },
    ranks: {
      schema_version: 1,
      version: text_(config.ranks_version),
      generated_at: generatedAt,
      rangos: ranks,
    },
    index: {
      schema_version: 1,
      content_version: text_(config.content_version),
      generated_at: generatedAt,
      min_app_version: integer_(config.min_app_version),
      files: {
        questions: {
          url: 'content/preguntas/banco_global.json',
          version: text_(config.questions_version),
          required: true,
        },
        challenges: {
          url: 'content/retos/retos_actuales.json',
          version: text_(config.challenges_version),
          required: false,
        },
        resources: {
          url: 'content/cards/cards_actuales.json',
          version: text_(config.cards_version),
          required: false,
        },
        ranks: {
          url: 'content/config/rangos.json',
          version: text_(config.ranks_version),
          required: false,
        },
      },
    },
  };
}

function validarDocumentos_(documents) {
  const errors = [];
  const questionIds = new Set();
  const challengeIds = new Set();
  const challengeDates = new Set();
  const cardIds = new Set();
  const rankIds = new Set();
  const thresholds = new Set();

  if (documents.questions.preguntas.length < 10) {
    errors.push('Debe haber al menos 10 preguntas activas.');
  }
  documents.questions.preguntas.forEach((question, index) => {
    const path = `Preguntas fila ${index + 2}`;
    requiredText_(errors, path, question, ['id', 'enunciado', 'categoria']);
    duplicate_(errors, `${path}: ID`, question.id, questionIds);
    if (question.opciones.length !== 4 || question.opciones.some((value) => !value)) {
      errors.push(`${path}: las cuatro opciones son obligatorias.`);
    }
    if (!MA_VALID_ANSWERS.has(question.respuesta_correcta)) {
      errors.push(`${path}: respuesta_correcta debe ser A, B, C o D.`);
    }
    if (!question.etiquetas.length) {
      errors.push(`${path}: agrega al menos una etiqueta.`);
    }
    if (!MA_VALID_DIFFICULTIES.has(question.dificultad)) {
      errors.push(`${path}: dificultad inválida.`);
    }
    optionalHttps_(errors, `${path}: imagen_url`, question.imagen_url);
  });

  documents.challenges.retos.forEach((challenge, index) => {
    const path = `Retos fila ${index + 2}`;
    requiredText_(errors, path, challenge, ['id', 'fecha', 'titulo']);
    duplicate_(errors, `${path}: ID`, challenge.id, challengeIds);
    duplicate_(errors, `${path}: fecha`, challenge.fecha, challengeDates);
    if (!/^\d{4}-\d{2}-\d{2}$/.test(challenge.fecha)) {
      errors.push(`${path}: fecha debe usar YYYY-MM-DD.`);
    }
    if (!challenge.preguntas_ids.length) {
      errors.push(`${path}: agrega preguntas_ids.`);
    }
    if (new Set(challenge.preguntas_ids).size !== challenge.preguntas_ids.length) {
      errors.push(`${path}: no repitas preguntas dentro del reto.`);
    }
    challenge.preguntas_ids.forEach((id) => {
      if (!questionIds.has(id)) errors.push(`${path}: pregunta inexistente ${id}.`);
    });
    requiredText_(errors, `${path}: recurso`, challenge.recurso_resolucion, ['tipo', 'titulo']);
    requiredHttps_(errors, `${path}: recurso_url`, challenge.recurso_resolucion.url);
  });

  documents.resources.cards.forEach((card, index) => {
    const path = `Cards fila ${index + 2}`;
    requiredText_(errors, path, card, ['id', 'titulo', 'descripcion']);
    duplicate_(errors, `${path}: ID`, card.id, cardIds);
    if (!MA_VALID_CARD_TYPES.has(card.tipo)) errors.push(`${path}: tipo inválido.`);
    requiredHttps_(errors, `${path}: url`, card.url);
    optionalHttps_(errors, `${path}: imagen_url`, card.imagen_url);
    if (!card.etiquetas.length) errors.push(`${path}: agrega al menos una etiqueta.`);
    if (!Number.isInteger(card.prioridad) || card.prioridad < 0) {
      errors.push(`${path}: prioridad debe ser entero no negativo.`);
    }
    if (!/^\d{4}-\d{2}-\d{2}$/.test(card.fecha_publicacion)) {
      errors.push(`${path}: fecha_publicacion debe usar YYYY-MM-DD.`);
    }
  });

  documents.ranks.rangos.forEach((rank, index) => {
    const path = `Rangos fila ${index + 2}`;
    requiredText_(errors, path, rank, ['id', 'nombre', 'descripcion']);
    duplicate_(errors, `${path}: ID`, rank.id, rankIds);
    if (!Number.isInteger(rank.racha_minima) || rank.racha_minima < 0) {
      errors.push(`${path}: racha_minima debe ser entero no negativo.`);
    } else {
      duplicate_(errors, `${path}: racha_minima`, rank.racha_minima, thresholds);
    }
  });
  if (!thresholds.has(0)) errors.push('Debe existir un rango con racha_minima 0.');

  [
    documents.questions.version,
    documents.challenges.version,
    documents.resources.version,
    documents.ranks.version,
    documents.index.content_version,
  ].forEach((version) => {
    if (!MA_VERSION_PATTERN.test(version)) errors.push(`Versión inválida: ${version}.`);
  });
  if (!Number.isInteger(documents.index.min_app_version) || documents.index.min_app_version < 1) {
    errors.push('min_app_version debe ser entero positivo.');
  }
  return errors;
}

function config_() {
  const result = {};
  sheetObjects_('Config').forEach((row) => {
    const key = text_(row.clave);
    if (!key) throw new Error('Config contiene una clave vacía.');
    if (Object.prototype.hasOwnProperty.call(result, key)) {
      throw new Error(`Config contiene la clave duplicada ${key}.`);
    }
    result[key] = text_(row.valor);
  });
  return result;
}

function sheetObjects_(name) {
  const sheet = SpreadsheetApp.getActive().getSheetByName(name);
  if (!sheet) throw new Error(`No existe la hoja ${name}.`);
  const values = sheet.getDataRange().getDisplayValues();
  if (!values.length) throw new Error(`La hoja ${name} está vacía.`);
  const headers = values.shift().map((value) => text_(value).toLowerCase());
  if (headers.some((header) => !header)) throw new Error(`${name} tiene encabezados vacíos.`);
  if (new Set(headers).size !== headers.length) throw new Error(`${name} tiene encabezados duplicados.`);
  return values
    .filter((row) => row.some((value) => text_(value)))
    .map((row) => Object.fromEntries(headers.map((header, index) => [header, row[index]])));
}

function crearJson_(folder, name, value) {
  folder.createFile(name, JSON.stringify(value, null, 2), MimeType.PLAIN_TEXT);
}

function text_(value) {
  return String(value == null ? '' : value).trim();
}

function nullable_(value) {
  const result = text_(value);
  return result || null;
}

function list_(value, lowercase) {
  const seen = new Set();
  return text_(value)
    .replace(/\n/g, ';')
    .replace(/,/g, ';')
    .split(';')
    .map((item) => lowercase ? item.trim().toLowerCase() : item.trim())
    .filter((item) => item && !seen.has(item) && seen.add(item));
}

function active_(row) {
  const value = text_(row.activa || row.activo).toLowerCase();
  if (!value) return true;
  if (/^(si|sí|true|1|x|activo|activa)$/i.test(value)) return true;
  if (/^(no|false|0|n|inactivo|inactiva)$/i.test(value)) return false;
  throw new Error(`Activo/activa debe ser SI o NO; se recibió ${value}.`);
}

function integer_(value) {
  const text = text_(value);
  if (!/^-?\d+$/.test(text)) return NaN;
  return Number(text);
}

function date_(value) {
  const result = text_(value);
  return result.length >= 10 ? result.substring(0, 10) : result;
}

function requiredText_(errors, path, object, fields) {
  fields.forEach((field) => {
    if (!text_(object[field])) errors.push(`${path}: ${field} es obligatorio.`);
  });
}

function duplicate_(errors, label, value, seen) {
  if (!text_(value)) return;
  if (seen.has(value)) errors.push(`${label} duplicado: ${value}.`);
  seen.add(value);
}

function requiredHttps_(errors, label, value) {
  if (!/^https:\/\//i.test(text_(value))) errors.push(`${label} debe usar HTTPS.`);
}

function optionalHttps_(errors, label, value) {
  if (value != null && !/^https:\/\//i.test(text_(value))) {
    errors.push(`${label} debe estar vacío o usar HTTPS.`);
  }
}
