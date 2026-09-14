(function (global) {
  'use strict';

  const TIME_ZONE = 'America/Los_Angeles';
  const DATE_TIME_RE = /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})(?::(\d{2})(?:\.(\d{1,3}))?)?$/;
  const DATE_RE = /^(\d{4})-(\d{2})-(\d{2})$/;
  const EXPLICIT_ZONE_RE = /(?:Z|[+-]\d{2}:?\d{2})$/i;

  function partsInPacific(date, includeTime) {
    const options = {
      timeZone: TIME_ZONE,
      year: 'numeric', month: '2-digit', day: '2-digit',
      hourCycle: 'h23'
    };
    if (includeTime) {
      options.hour = '2-digit';
      options.minute = '2-digit';
      options.second = '2-digit';
    }
    return Object.fromEntries(
      new Intl.DateTimeFormat('en-US', options)
        .formatToParts(date)
        .filter(part => part.type !== 'literal')
        .map(part => [part.type, part.value])
    );
  }

  function offsetAt(date) {
    const p = partsInPacific(date, true);
    const representedAsUtc = Date.UTC(
      Number(p.year), Number(p.month) - 1, Number(p.day),
      Number(p.hour), Number(p.minute), Number(p.second)
    );
    return representedAsUtc - date.getTime();
  }

  // Convert a timezone-free datetime-local value, interpreted as Pacific time,
  // to an unambiguous UTC instant. Iteration handles PST/PDT transitions.
  function pacificWallTimeToDate(value) {
    const match = String(value || '').match(DATE_TIME_RE);
    if (!match) return null;
    const wallUtc = Date.UTC(
      Number(match[1]), Number(match[2]) - 1, Number(match[3]),
      Number(match[4]), Number(match[5]), Number(match[6] || 0),
      Number(String(match[7] || '0').padEnd(3, '0'))
    );
    let instant = wallUtc;
    for (let i = 0; i < 3; i += 1) {
      instant = wallUtc - offsetAt(new Date(instant));
    }
    const result = new Date(instant);
    return Number.isNaN(result.getTime()) ? null : result;
  }

  function parseDateTime(value) {
    if (!value) return null;
    const text = String(value).trim();
    const date = EXPLICIT_ZONE_RE.test(text)
      ? new Date(text)
      : pacificWallTimeToDate(text);
    return date && !Number.isNaN(date.getTime()) ? date : null;
  }

  function toUtcIso(value) {
    const date = parseDateTime(value);
    return date ? date.toISOString() : '';
  }

  function toDateTimeLocal(value) {
    const text = String(value || '').trim();
    if (DATE_TIME_RE.test(text)) return text.slice(0, 16);
    const date = parseDateTime(text);
    if (!date) return '';
    const p = partsInPacific(date, true);
    return `${p.year}-${p.month}-${p.day}T${p.hour}:${p.minute}`;
  }

  function nowDateTimeLocal() {
    return toDateTimeLocal(new Date().toISOString());
  }

  function todayDate() {
    const p = partsInPacific(new Date(), false);
    return `${p.year}-${p.month}-${p.day}`;
  }

  function formatDateTime(value) {
    const date = parseDateTime(value);
    if (!date) return value ? String(value) : '—';
    return new Intl.DateTimeFormat('en-US', {
      timeZone: TIME_ZONE,
      month: '2-digit', day: '2-digit', year: 'numeric',
      hour: 'numeric', minute: '2-digit', hour12: true,
      timeZoneName: 'short'
    }).format(date).replace(',', '');
  }

  // Calendar-only fields must never be converted through a timezone.
  function formatDateOnly(value) {
    if (!value) return '—';
    const match = String(value).trim().match(DATE_RE);
    if (match) return `${match[2]}-${match[3]}-${match[1]}`;
    const date = parseDateTime(value) || new Date(value);
    if (Number.isNaN(date.getTime())) return String(value);
    const p = partsInPacific(date, false);
    return `${p.month}-${p.day}-${p.year}`;
  }

  function sortValue(value) {
    const date = parseDateTime(value);
    if (date) return date.getTime();
    const match = String(value || '').trim().match(DATE_RE);
    return match ? Date.UTC(Number(match[1]), Number(match[2]) - 1, Number(match[3])) : 0;
  }

  global.HorizonTime = Object.freeze({
    timeZone: TIME_ZONE,
    formatDateTime,
    formatDateOnly,
    nowDateTimeLocal,
    todayDate,
    toDateTimeLocal,
    toUtcIso,
    sortValue
  });
})(window);
