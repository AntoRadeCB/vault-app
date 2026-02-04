// OCR Bridge - Tesseract.js + Camera for Flutter web
// Manages Tesseract.js OCR worker and camera access

let ocrWorker = null;
const cameraState = {};

async function initOcrWorker() {
  if (ocrWorker) return;
  ocrWorker = await Tesseract.createWorker('eng');
  // Set PSM to sparse text (good for small numbers on cards)
  await ocrWorker.setParameters({
    tessedit_char_whitelist: '0123456789/ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz#- ',
    tessedit_pageseg_mode: '11', // sparse text
  });
}

async function startOcrCamera(containerId) {
  const container = document.getElementById(containerId);
  if (!container) {
    return JSON.stringify({ error: 'Container not found' });
  }

  const video = document.createElement('video');
  video.setAttribute('autoplay', '');
  video.setAttribute('playsinline', '');
  video.setAttribute('muted', '');
  video.muted = true;
  video.style.cssText = 'width:100%;height:100%;object-fit:cover;position:absolute;top:0;left:0;';

  // Hidden canvases for processing
  const canvasFull = document.createElement('canvas');
  canvasFull.style.display = 'none';
  const canvasCrop = document.createElement('canvas');
  canvasCrop.style.display = 'none';

  container.innerHTML = '';
  container.style.cssText = 'width:100%;height:100%;position:relative;overflow:hidden;background:#000;';
  container.appendChild(video);
  container.appendChild(canvasFull);
  container.appendChild(canvasCrop);

  try {
    const stream = await navigator.mediaDevices.getUserMedia({
      video: {
        facingMode: { ideal: 'environment' },
        width: { ideal: 1920 },
        height: { ideal: 1080 }
      }
    });
    video.srcObject = stream;
    await video.play();
    cameraState[containerId] = {
      video: video,
      canvasFull: canvasFull,
      canvasCrop: canvasCrop,
      stream: stream
    };
    return JSON.stringify({ success: true });
  } catch (e) {
    return JSON.stringify({ error: e.message || 'Camera access denied' });
  }
}

/**
 * Capture and recognize in multiple zones:
 * 1. Bottom strip of the card area (where collector number usually is)
 * 2. Full card area (fallback)
 * Each zone is preprocessed: grayscale → threshold → upscale
 */
async function captureAndRecognize(containerId) {
  const state = cameraState[containerId];
  if (!state) return JSON.stringify({ error: 'Camera not started' });
  if (!ocrWorker) await initOcrWorker();

  const video = state.video;
  const canvasFull = state.canvasFull;
  const canvasCrop = state.canvasCrop;

  if (video.videoWidth === 0 || video.videoHeight === 0) {
    return JSON.stringify({ error: 'Video not ready', text: '', confidence: 0 });
  }

  const vw = video.videoWidth;
  const vh = video.videoHeight;

  // Draw full frame
  canvasFull.width = vw;
  canvasFull.height = vh;
  const ctxFull = canvasFull.getContext('2d');
  ctxFull.drawImage(video, 0, 0);

  // Calculate card area within the frame
  // The overlay cutout is ~72% width, centered, ratio 5:7
  const cardW = vw * 0.72;
  const cardH = cardW * (7 / 5);
  const cardX = (vw - cardW) / 2;
  const cardY = (vh - cardH) / 2;

  // Try multiple zones, best result wins
  const zones = [
    // Zone 1: Bottom 20% of card (collector number area)
    { x: cardX, y: cardY + cardH * 0.78, w: cardW, h: cardH * 0.22, name: 'bottom' },
    // Zone 2: Bottom-left quarter (where most TCGs put the number)
    { x: cardX, y: cardY + cardH * 0.82, w: cardW * 0.5, h: cardH * 0.18, name: 'bottom-left' },
    // Zone 3: Bottom-right quarter
    { x: cardX + cardW * 0.5, y: cardY + cardH * 0.82, w: cardW * 0.5, h: cardH * 0.18, name: 'bottom-right' },
    // Zone 4: Full card (fallback)
    { x: cardX, y: cardY, w: cardW, h: cardH, name: 'full' },
  ];

  let bestText = '';
  let bestConfidence = 0;
  let allTexts = [];

  for (const zone of zones) {
    // Clamp to frame bounds
    const sx = Math.max(0, Math.round(zone.x));
    const sy = Math.max(0, Math.round(zone.y));
    const sw = Math.min(Math.round(zone.w), vw - sx);
    const sh = Math.min(Math.round(zone.h), vh - sy);
    if (sw <= 0 || sh <= 0) continue;

    // Crop and upscale to at least 600px wide for better OCR
    const scale = Math.max(1, 600 / sw);
    const dw = Math.round(sw * scale);
    const dh = Math.round(sh * scale);

    canvasCrop.width = dw;
    canvasCrop.height = dh;
    const ctx = canvasCrop.getContext('2d');

    // Draw cropped zone upscaled
    ctx.drawImage(canvasFull, sx, sy, sw, sh, 0, 0, dw, dh);

    // Preprocess: grayscale + high contrast threshold
    const imgData = ctx.getImageData(0, 0, dw, dh);
    const data = imgData.data;
    for (let i = 0; i < data.length; i += 4) {
      // Luminance
      const gray = data[i] * 0.299 + data[i + 1] * 0.587 + data[i + 2] * 0.114;
      // Adaptive threshold: make text black on white
      const bw = gray > 140 ? 255 : 0;
      data[i] = bw;
      data[i + 1] = bw;
      data[i + 2] = bw;
    }
    ctx.putImageData(imgData, 0, 0);

    try {
      const result = await ocrWorker.recognize(canvasCrop);
      const text = result.data.text.trim();
      const conf = result.data.confidence;

      if (text) {
        allTexts.push(text);
        if (conf > bestConfidence) {
          bestConfidence = conf;
          bestText = text;
        }
      }

      // Also try inverted (white text on dark background — common on card bottoms)
      const imgDataInv = ctx.getImageData(0, 0, dw, dh);
      const dataInv = imgDataInv.data;
      for (let i = 0; i < dataInv.length; i += 4) {
        dataInv[i] = 255 - dataInv[i];
        dataInv[i + 1] = 255 - dataInv[i + 1];
        dataInv[i + 2] = 255 - dataInv[i + 2];
      }
      ctx.putImageData(imgDataInv, 0, 0);

      const resultInv = await ocrWorker.recognize(canvasCrop);
      const textInv = resultInv.data.text.trim();
      if (textInv) {
        allTexts.push(textInv);
        if (resultInv.data.confidence > bestConfidence) {
          bestConfidence = resultInv.data.confidence;
          bestText = textInv;
        }
      }

      // If we already found something with a number pattern, stop early
      // (don't waste time on full card scan)
      if (zone.name !== 'full' && hasCollectorPattern(allTexts.join(' '))) {
        break;
      }
    } catch (e) {
      // OCR failed for this zone, try next
    }
  }

  return JSON.stringify({
    text: allTexts.join(' | '),
    confidence: bestConfidence
  });
}

/** Quick check if text contains a collector number pattern */
function hasCollectorPattern(text) {
  return /\d{1,4}\s*\/\s*\d{1,4}/.test(text) ||
         /[A-Z]{1,5}\d{1,4}\s*\//.test(text) ||
         /#\s*\d{1,4}\b/.test(text);
}

function stopOcrCamera(containerId) {
  const state = cameraState[containerId];
  if (state) {
    if (state.stream) {
      state.stream.getTracks().forEach(function(track) { track.stop(); });
    }
    delete cameraState[containerId];
  }
}

function createOcrContainer(id) {
  const div = document.createElement('div');
  div.id = id;
  div.style.cssText = 'width:100%;height:100%;background:#000;position:relative;overflow:hidden;';
  return div;
}

function vibrateDevice(ms) {
  try {
    if (navigator.vibrate) navigator.vibrate(ms);
  } catch (e) {}
}

// Expose to Dart
window.initOcrWorker = initOcrWorker;
window.startOcrCamera = startOcrCamera;
window.captureAndRecognize = captureAndRecognize;
window.stopOcrCamera = stopOcrCamera;
window.createOcrContainer = createOcrContainer;
window.vibrateDevice = vibrateDevice;
