import { serverConfig } from '../config.js';
import { clampNumber } from '../utils/validators.js';

export function normalizeMealImage(imageData) {
  if (!imageData) return null;

  const trimmedImage = String(imageData).trim();
  if (trimmedImage.startsWith('data:image/')) {
    return trimmedImage;
  }

  if (/^[A-Za-z0-9+/=\s]+$/.test(trimmedImage)) {
    return `data:image/jpeg;base64,${trimmedImage.replace(/\s/g, '')}`;
  }

  return null;
}

export function extractOpenAIText(payload) {
  if (typeof payload?.output_text === 'string') {
    return payload.output_text;
  }

  const output = Array.isArray(payload?.output) ? payload.output : [];
  return output
    .flatMap((item) => item.content || [])
    .map((content) => content.text || '')
    .filter(Boolean)
    .join('\n');
}

export function parseJSONOutput(text) {
  const trimmedText = String(text || '').trim();

  try {
    return JSON.parse(trimmedText);
  } catch {
    const match = trimmedText.match(/\{[\s\S]*\}/);
    if (!match) return null;
    try {
      return JSON.parse(match[0]);
    } catch {
      return null;
    }
  }
}

export function normalizeResponseLanguage(language) {
  const requested = String(language || '').trim().toLowerCase();
  if (requested.includes('chinese') || requested.includes('zh') || requested.includes('中文')) {
    return {
      name: 'Simplified Chinese',
      instruction: 'Simplified Chinese',
      insightTitles: '提示, 注意, 警报, 提醒',
      fallbackSummary: '这是基于照片的餐食估算。实际数值可能会因份量和食材而变化。',
      fallbackRecommendations: ['尽量确认份量', '单独检查过敏原', '用于日常记录，不替代医疗建议'],
      fallbackNotes: ['AI 照片估算', '份量会影响总量', '请单独确认过敏原'],
      fallbackInsight: {
        title: '注意',
        message: '今天记录已完成，暂未看到明显异常。'
      }
    };
  }

  return {
    name: 'English',
    instruction: 'English',
    insightTitles: 'Tip, Notice, Alert, Reminder',
    fallbackSummary: 'This is a photo-based meal estimate. Exact totals may vary with portion size and ingredients.',
    fallbackRecommendations: ['Confirm portion size when possible', 'Check allergens separately', 'Use this estimate for tracking, not medical advice'],
    fallbackNotes: ['AI photo estimate only', 'Portion size may change totals', 'Confirm allergens separately'],
    fallbackInsight: {
      title: 'Notice',
      message: 'Today is fully logged, with no major pattern standing out yet.'
    }
  };
}

export function normalizeMealEstimate(rawEstimate, languageInfo = normalizeResponseLanguage('English')) {
  const notes = Array.isArray(rawEstimate?.notes)
    ? rawEstimate.notes.map((note) => String(note).trim()).filter(Boolean).slice(0, 5)
    : [];
  const recommendations = Array.isArray(rawEstimate?.recommendations)
    ? rawEstimate.recommendations.map((item) => String(item).trim()).filter(Boolean).slice(0, 5)
    : [];
  const summary = String(rawEstimate?.summary || '').trim();

  return {
    calories: clampNumber(rawEstimate?.calories, 0, 3000, 0),
    protein: clampNumber(rawEstimate?.protein, 0, 250, 0),
    carbs: clampNumber(rawEstimate?.carbs, 0, 400, 0),
    fat: clampNumber(rawEstimate?.fat, 0, 250, 0),
    fiber: clampNumber(rawEstimate?.fiber, 0, 100, 0),
    sugar: clampNumber(rawEstimate?.sugar, 0, 250, 0),
    confidence: String(rawEstimate?.confidence || 'low').trim(),
    summary: summary || languageInfo.fallbackSummary,
    recommendations: recommendations.length > 0
      ? recommendations
      : languageInfo.fallbackRecommendations,
    notes: notes.length > 0
      ? notes
      : languageInfo.fallbackNotes
  };
}

export function normalizeHealthInsights(rawInsights, languageInfo = normalizeResponseLanguage('English')) {
  const insights = Array.isArray(rawInsights?.insights)
    ? rawInsights.insights
      .map((item) => ({
        title: String(item?.title || languageInfo.fallbackInsight.title).trim().slice(0, 24),
        message: String(item?.message || '').trim().slice(0, 140)
      }))
      .filter((item) => item.title && item.message)
      .slice(0, 1)
    : [];

  return {
    insights: insights.length > 0
      ? insights
      : [languageInfo.fallbackInsight]
  };
}

export function normalizeAdminAIReport(rawReport, fallbackDateRange, languageInfo = normalizeResponseLanguage('English')) {
  const isChinese = languageInfo.name === 'Simplified Chinese';
  const toShortString = (value, maxLength = 420) => String(value || '').trim().slice(0, maxLength);
  const toStringList = (value, maxItems = 8, maxLength = 420) => (
    Array.isArray(value)
      ? value.map((item) => toShortString(item, maxLength)).filter(Boolean).slice(0, maxItems)
      : []
  );

  return {
    title: toShortString(rawReport?.title, 90) || (isChinese ? '照护数据分析报告' : 'Care Data Analysis Report'),
    dateRange: toShortString(rawReport?.dateRange, 80) || fallbackDateRange,
    summary: toShortString(rawReport?.summary, 900) || (isChinese ? '所选记录未返回摘要。' : 'No summary was returned for the selected records.'),
    highlights: toStringList(rawReport?.highlights),
    patterns: toStringList(rawReport?.patterns || rawReport?.detailedPatterns),
    concerns: toStringList(rawReport?.concerns),
    recommendations: toStringList(rawReport?.recommendations),
    dataQualityNotes: toStringList(rawReport?.dataQualityNotes, 6),
    followUpQuestions: toStringList(rawReport?.followUpQuestions, 8),
    language: languageInfo.name
  };
}

export async function requestOpenAIJSON({ apiKey, input, maxOutputTokens }) {
  const openAIResponse = await fetch('https://api.openai.com/v1/responses', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      model: serverConfig.openAIModel,
      input,
      max_output_tokens: maxOutputTokens
    })
  });

  const payload = await openAIResponse.json().catch(() => ({}));
  if (!openAIResponse.ok) {
    const error = new Error(payload?.error?.message || 'OpenAI request failed.');
    error.status = 502;
    error.payload = payload;
    throw error;
  }

  const outputText = extractOpenAIText(payload);
  const json = parseJSONOutput(outputText);
  if (!json) {
    const error = new Error('OpenAI returned non-JSON output.');
    error.status = 502;
    error.outputText = outputText;
    throw error;
  }

  return json;
}
