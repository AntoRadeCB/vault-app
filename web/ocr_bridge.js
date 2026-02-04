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
        width: { ideal: 1280 },
        height: { ideal: 720 }
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
 * Lightweight capture: only scan the bottom strip of the card.
 * Alternates between normal and inverted on each call to reduce CPU load.
 */
let _scanCycle = 0;

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

  // Draw full frame at reduced resolution for speed
  const maxW = 960;
  const ratio = Math.min(1, maxW / vw);
  const fw = Math.round(vw * ratio);
  const fh = Math.round(vh * ratio);
  canvasFull.width = fw;
  canvasFull.height = fh;
  const ctxFull = canvasFull.getContext('2d');
  ctxFull.drawImage(video, 0, 0, fw, fh);

  // Card area (matching overlay: 72% width, ratio 5:7, centered)
  const cardW = fw * 0.72;
  const cardH = Math.min(cardW * (7 / 5), fh * 0.50);
  const cardX = (fw - cardW) / 2;
  const cardY = (fh - cardH) / 2;

  // Cycle through zones: 0=bottom strip, 1=bottom-left inverted, 2=bottom-right
  const cycle = _scanCycle++ % 3;
  let sx, sy, sw, sh;

  if (cycle === 0) {
    // Full bottom strip (20%)
    sx = cardX; sy = cardY + cardH * 0.78; sw = cardW; sh = cardH * 0.22;
  } else if (cycle === 1) {
    // Bottom-left
    sx = cardX; sy = cardY + cardH * 0.80; sw = cardW * 0.55; sh = cardH * 0.20;
  } else {
    // Bottom-right
    sx = cardX + cardW * 0.45; sy = cardY + cardH * 0.80; sw = cardW * 0.55; sh = cardH * 0.20;
  }

  sx = Math.max(0, Math.round(sx));
  sy = Math.max(0, Math.round(sy));
  sw = Math.min(Math.round(sw), fw - sx);
  sh = Math.min(Math.round(sh), fh - sy);
  if (sw <= 0 || sh <= 0) {
    return JSON.stringify({ text: '', confidence: 0 });
  }

  // Upscale crop to ~500px wide
  const scale = Math.max(1, 500 / sw);
  const dw = Math.round(sw * scale);
  const dh = Math.round(sh * scale);

  canvasCrop.width = dw;
  canvasCrop.height = dh;
  const ctx = canvasCrop.getContext('2d');
  ctx.drawImage(canvasFull, sx, sy, sw, sh, 0, 0, dw, dh);

  // Preprocess: grayscale + threshold
  const imgData = ctx.getImageData(0, 0, dw, dh);
  const data = imgData.data;
  const invert = (cycle === 1); // alternate inverted on cycle 1
  for (let i = 0; i < data.length; i += 4) {
    const gray = data[i] * 0.299 + data[i+1] * 0.587 + data[i+2] * 0.114;
    let bw = gray > 140 ? 255 : 0;
    if (invert) bw = 255 - bw;
    data[i] = bw; data[i+1] = bw; data[i+2] = bw;
  }
  ctx.putImageData(imgData, 0, 0);

  try {
    const result = await ocrWorker.recognize(canvasCrop);
    return JSON.stringify({
      text: result.data.text.trim(),
      confidence: result.data.confidence
    });
  } catch (e) {
    return JSON.stringify({ error: e.message || 'OCR failed', text: '', confidence: 0 });
  }
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
