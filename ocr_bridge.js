// OCR Bridge - Tesseract.js + Camera for Flutter web
// Manages Tesseract.js OCR worker and camera access

let ocrWorker = null;
const cameraState = {};

async function initOcrWorker() {
  if (ocrWorker) return;
  ocrWorker = await Tesseract.createWorker('eng');
}

async function startOcrCamera(containerId) {
  const container = document.getElementById(containerId);
  if (!container) {
    return JSON.stringify({ error: 'Container not found' });
  }

  // Create video element
  const video = document.createElement('video');
  video.setAttribute('autoplay', '');
  video.setAttribute('playsinline', '');
  video.setAttribute('muted', '');
  video.muted = true;
  video.style.cssText = 'width:100%;height:100%;object-fit:cover;position:absolute;top:0;left:0;';

  // Create hidden canvas for frame capture
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
    cameraState[containerId] = { video: video, canvas: canvas, stream: stream };
    return JSON.stringify({ success: true });
  } catch (e) {
    return JSON.stringify({ error: e.message || 'Camera access denied' });
  }
}

async function captureAndRecognize(containerId) {
  const state = cameraState[containerId];
  if (!state) {
    return JSON.stringify({ error: 'Camera not started' });
  }

  if (!ocrWorker) {
    await initOcrWorker();
  }

  const video = state.video;
  const canvas = state.canvas;

  // Only capture if video has dimensions
  if (video.videoWidth === 0 || video.videoHeight === 0) {
    return JSON.stringify({ error: 'Video not ready', text: '', confidence: 0 });
  }

  canvas.width = video.videoWidth;
  canvas.height = video.videoHeight;
  const ctx = canvas.getContext('2d');
  ctx.drawImage(video, 0, 0);

  try {
    const result = await ocrWorker.recognize(canvas);
    return JSON.stringify({
      text: result.data.text,
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
    if (navigator.vibrate) {
      navigator.vibrate(ms);
    }
  } catch (e) {
    // Vibration not supported
  }
}

// Expose to Dart
window.initOcrWorker = initOcrWorker;
window.startOcrCamera = startOcrCamera;
window.captureAndRecognize = captureAndRecognize;
window.stopOcrCamera = stopOcrCamera;
window.createOcrContainer = createOcrContainer;
window.vibrateDevice = vibrateDevice;
