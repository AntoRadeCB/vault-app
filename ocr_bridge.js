// AI Vision Bridge — Camera + Cloud Function for card scanning

const cameraState = {};

// Callback for async scan results (set from Dart side)
let _onScanResult = null;
let _onScanError = null;

async function startOcrCamera(containerId) {
  const container = document.getElementById(containerId);
  if (!container) return JSON.stringify({ error: 'Container not found' });

  const video = document.createElement('video');
  video.setAttribute('autoplay', '');
  video.setAttribute('playsinline', '');
  video.setAttribute('muted', '');
  video.muted = true;
  video.style.cssText = 'width:100%;height:100%;object-fit:cover;position:absolute;top:0;left:0;';

  const canvas = document.createElement('canvas');
  canvas.style.display = 'none';

  container.innerHTML = '';
  container.style.cssText = 'width:100%;height:100%;position:relative;overflow:hidden;background:#000;';
  container.appendChild(video);
  container.appendChild(canvas);

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
    cameraState[containerId] = { video, canvas, stream };
    return JSON.stringify({ success: true });
  } catch (e) {
    return JSON.stringify({ error: e.message || 'Camera access denied' });
  }
}

/**
 * Capture current frame and return base64 WITHOUT calling API.
 * This allows Dart side to fire API calls asynchronously.
 */
function captureFrame(containerId) {
  const state = cameraState[containerId];
  if (!state) return JSON.stringify({ error: 'Camera not started' });

  const video = state.video;
  const canvas = state.canvas;

  if (video.videoWidth === 0 || video.videoHeight === 0) {
    return JSON.stringify({ error: 'Video not ready' });
  }

  const vw = video.videoWidth;
  const vh = video.videoHeight;

  // Crop to single-card area (matching the overlay cutout)
  // Overlay: 60% height, width = height * 0.714, centered
  const cardRatio = 0.714;
  const cropH = Math.round(vh * 0.60);
  const cropW = Math.round(Math.min(cropH * cardRatio, vw * 0.75));
  const cropX = Math.round((vw - cropW) / 2);
  const cropY = Math.round((vh - cropH) / 2 - vh * 0.03); // slight up offset matching overlay

  // Output at native crop resolution (no downscale — card fills entire image)
  canvas.width = cropW;
  canvas.height = cropH;
  const ctx = canvas.getContext('2d');
  ctx.imageSmoothingEnabled = true;
  ctx.imageSmoothingQuality = 'high';
  ctx.drawImage(video, cropX, cropY, cropW, cropH, 0, 0, cropW, cropH);

  return canvas.toDataURL('image/jpeg', 0.92);
}

/**
 * Capture current frame + call API.
 * contextJson may contain: { expansion, cards, mode }
 * mode: "premium" (GPT-5.2 + card list) or "ocr" (Gemini Flash OCR, default)
 */
async function captureAndRecognize(containerId, contextJson) {
  const base64 = captureFrame(containerId);
  if (base64.startsWith('{')) return base64; // error JSON

  let scanContext = {};
  try { if (contextJson) scanContext = JSON.parse(contextJson); } catch(e) {}

  const isPremium = scanContext.mode === 'premium';
  const apiUrl = isPremium
    ? 'https://scancard-orjhcexzoa-ew.a.run.app'
    : 'https://scancardocr-orjhcexzoa-ew.a.run.app';

  try {
    const body = { image: base64 };
    if (isPremium) {
      if (scanContext.expansion) body.expansion = scanContext.expansion;
      if (scanContext.cards) body.cards = scanContext.cards;
    }

    const resp = await fetch(apiUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body)
    });

    if (!resp.ok) {
      const errText = await resp.text();
      return JSON.stringify({ error: `API ${resp.status}: ${errText}`, text: '', confidence: 0 });
    }

    const data = await resp.json();

    if (data.found && data.cardName) {
      return JSON.stringify({
        text: data.cardName,
        cardName: data.cardName,
        extraInfo: data.extraInfo || null,
        confidence: 95,
        aiResult: data,
        cards: data.cards || [data]
      });
    } else {
      return JSON.stringify({ text: '', confidence: 0, cards: [] });
    }
  } catch (e) {
    return JSON.stringify({ error: e.message || 'API call failed', text: '', confidence: 0 });
  }
}

// No-op: no worker to init anymore
async function initOcrWorker() {}

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
window.captureFrame = captureFrame;
window.stopOcrCamera = stopOcrCamera;
window.createOcrContainer = createOcrContainer;
window.vibrateDevice = vibrateDevice;
