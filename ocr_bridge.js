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
        width: { ideal: 1280 },
        height: { ideal: 720 }
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

  // Crop to card area (matching overlay: 72% width, 5:7 ratio, centered)
  const cardW = vw * 0.72;
  const cardH = Math.min(cardW * (7 / 5), vh * 0.50);
  const cardX = (vw - cardW) / 2;
  const cardY = (vh - cardH) / 2;

  // Draw the card area at good resolution for AI vision
  const maxDim = 768;
  const scale = Math.min(1, maxDim / Math.max(cardW, cardH));
  const dw = Math.round(cardW * scale);
  const dh = Math.round(cardH * scale);

  canvas.width = dw;
  canvas.height = dh;
  const ctx = canvas.getContext('2d');
  ctx.drawImage(video, cardX, cardY, cardW, cardH, 0, 0, dw, dh);

  return canvas.toDataURL('image/jpeg', 0.85);
}

/**
 * Legacy: Capture current frame + call API (synchronous flow).
 * Still works but the Dart side now uses captureFrame + sendToApi separately.
 */
async function captureAndRecognize(containerId) {
  const base64 = captureFrame(containerId);
  if (base64.startsWith('{')) return base64; // error JSON

  try {
    const resp = await fetch(
      'https://europe-west1-inventorymanager-dev-20262.cloudfunctions.net/scanCard',
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ image: base64 })
      }
    );

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
