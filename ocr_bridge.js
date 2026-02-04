// OCR Bridge - Tesseract.js + Camera for Flutter web

let ocrWorker = null;
const cameraState = {};

async function initOcrWorker() {
  if (ocrWorker) return;
  ocrWorker = await Tesseract.createWorker('eng');
  await ocrWorker.setParameters({
    tessedit_char_whitelist: '0123456789/ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz#- ',
    tessedit_pageseg_mode: '11',
  });
}

async function startOcrCamera(containerId) {
  const container = document.getElementById(containerId);
  if (!container) return JSON.stringify({ error: 'Container not found' });

  const video = document.createElement('video');
  video.setAttribute('autoplay', '');
  video.setAttribute('playsinline', '');
  video.setAttribute('muted', '');
  video.muted = true;
  video.style.cssText = 'width:100%;height:100%;object-fit:cover;position:absolute;top:0;left:0;';

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
        width: { ideal: 1280 },
        height: { ideal: 720 }
      }
    });
    video.srcObject = stream;
    await video.play();
    cameraState[containerId] = { video, canvasFull, canvasCrop, stream };
    return JSON.stringify({ success: true });
  } catch (e) {
    return JSON.stringify({ error: e.message || 'Camera access denied' });
  }
}

/**
 * Multi-zone scan: bottom strip, bottom-left, bottom-right, full card.
 * Each zone gets threshold + inverted pass. Stops early on pattern match.
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

  canvasFull.width = vw;
  canvasFull.height = vh;
  canvasFull.getContext('2d').drawImage(video, 0, 0);

  // Card area matching overlay (72% width, 5:7 ratio, centered)
  const cardW = vw * 0.72;
  const cardH = cardW * (7 / 5);
  const cardX = (vw - cardW) / 2;
  const cardY = (vh - cardH) / 2;

  const zones = [
    { x: cardX, y: cardY + cardH * 0.78, w: cardW, h: cardH * 0.22, name: 'bottom' },
    { x: cardX, y: cardY + cardH * 0.82, w: cardW * 0.5, h: cardH * 0.18, name: 'bottom-left' },
    { x: cardX + cardW * 0.5, y: cardY + cardH * 0.82, w: cardW * 0.5, h: cardH * 0.18, name: 'bottom-right' },
    { x: cardX, y: cardY, w: cardW, h: cardH, name: 'full' },
  ];

  let allTexts = [];

  for (const zone of zones) {
    const sx = Math.max(0, Math.round(zone.x));
    const sy = Math.max(0, Math.round(zone.y));
    const sw = Math.min(Math.round(zone.w), vw - sx);
    const sh = Math.min(Math.round(zone.h), vh - sy);
    if (sw <= 0 || sh <= 0) continue;

    const scale = Math.max(1, 600 / sw);
    const dw = Math.round(sw * scale);
    const dh = Math.round(sh * scale);

    canvasCrop.width = dw;
    canvasCrop.height = dh;
    const ctx = canvasCrop.getContext('2d');
    ctx.drawImage(canvasFull, sx, sy, sw, sh, 0, 0, dw, dh);

    // Normal threshold pass
    const imgData = ctx.getImageData(0, 0, dw, dh);
    const d = imgData.data;
    for (let i = 0; i < d.length; i += 4) {
      const g = d[i] * 0.299 + d[i+1] * 0.587 + d[i+2] * 0.114;
      const bw = g > 140 ? 255 : 0;
      d[i] = bw; d[i+1] = bw; d[i+2] = bw;
    }
    ctx.putImageData(imgData, 0, 0);

    try {
      const r = await ocrWorker.recognize(canvasCrop);
      if (r.data.text.trim()) allTexts.push(r.data.text.trim());

      // Inverted pass (white text on dark bg)
      const inv = ctx.getImageData(0, 0, dw, dh);
      const di = inv.data;
      for (let i = 0; i < di.length; i += 4) {
        di[i] = 255 - di[i]; di[i+1] = 255 - di[i+1]; di[i+2] = 255 - di[i+2];
      }
      ctx.putImageData(inv, 0, 0);
      const ri = await ocrWorker.recognize(canvasCrop);
      if (ri.data.text.trim()) allTexts.push(ri.data.text.trim());

      // Early exit if we found a number pattern (skip full card scan)
      if (zone.name !== 'full' && hasCollectorPattern(allTexts.join(' '))) break;
    } catch (e) {}
  }

  return JSON.stringify({ text: allTexts.join(' | '), confidence: 0 });
}

function hasCollectorPattern(text) {
  return /\d{1,4}\s*[/\\]\s*\d{1,4}/.test(text) ||
         /[A-Z]{1,5}\d{1,4}\s*[/\\]/.test(text) ||
         /#\s*\d{1,4}\b/.test(text);
}

function stopOcrCamera(containerId) {
  const state = cameraState[containerId];
  if (state) {
    if (state.stream) state.stream.getTracks().forEach(t => t.stop());
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
  try { if (navigator.vibrate) navigator.vibrate(ms); } catch(e) {}
}

window.initOcrWorker = initOcrWorker;
window.startOcrCamera = startOcrCamera;
window.captureAndRecognize = captureAndRecognize;
window.stopOcrCamera = stopOcrCamera;
window.createOcrContainer = createOcrContainer;
window.vibrateDevice = vibrateDevice;
