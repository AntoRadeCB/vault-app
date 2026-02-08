// AI Vision Bridge — Camera + Cloud Function + Local Tesseract.js for card scanning

const cameraState = {};
let tesseractWorker = null;
let tesseractLoading = false;

// Lazy load Tesseract.js only when needed
async function ensureTesseract() {
  if (tesseractWorker) return tesseractWorker;
  if (tesseractLoading) {
    // Wait for loading to complete
    while (tesseractLoading) {
      await new Promise(r => setTimeout(r, 100));
    }
    return tesseractWorker;
  }
  
  tesseractLoading = true;
  try {
    // Load Tesseract.js from CDN
    if (!window.Tesseract) {
      await new Promise((resolve, reject) => {
        const script = document.createElement('script');
        script.src = 'https://cdn.jsdelivr.net/npm/tesseract.js@5/dist/tesseract.min.js';
        script.onload = resolve;
        script.onerror = reject;
        document.head.appendChild(script);
      });
    }
    
    // Create worker with English language, optimized for speed
    tesseractWorker = await Tesseract.createWorker('eng', 1, {
      logger: () => {}, // Disable logging
    });
    
    // Set parameters for number/text recognition
    await tesseractWorker.setParameters({
      tessedit_char_whitelist: '0123456789/-ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz ',
      tessedit_pageseg_mode: Tesseract.PSM.SINGLE_LINE,
    });
    
    console.log('Tesseract.js loaded successfully');
    return tesseractWorker;
  } catch (e) {
    console.error('Failed to load Tesseract.js:', e);
    tesseractWorker = null;
    throw e;
  } finally {
    tesseractLoading = false;
  }
}

/**
 * Capture frame and run LOCAL OCR with Tesseract.js
 * Focuses on the bottom portion of the card where collector number is
 */
async function captureAndRecognizeLocal(containerId) {
  const state = cameraState[containerId];
  if (!state) return JSON.stringify({ error: 'Camera not started' });

  const video = state.video;
  const canvas = state.canvas;

  if (video.videoWidth === 0 || video.videoHeight === 0) {
    return JSON.stringify({ error: 'Video not ready' });
  }

  const vw = video.videoWidth;
  const vh = video.videoHeight;

  // Crop to card area first (same as captureFrame)
  const cardRatio = 0.714;
  const cropH = Math.round(vh * 0.60);
  const cropW = Math.round(Math.min(cropH * cardRatio, vw * 0.75));
  const cropX = Math.round((vw - cropW) / 2);
  const cropY = Math.round((vh - cropH) / 2 - vh * 0.03);

  // Now extract just the BOTTOM 15% of the card (where collector number is)
  const numH = Math.round(cropH * 0.12);
  const numY = cropY + cropH - numH - Math.round(cropH * 0.03); // slightly above bottom edge
  const numW = Math.round(cropW * 0.5); // right half where number usually is
  const numX = cropX + Math.round(cropW * 0.45);

  // Create a separate canvas for OCR region
  const ocrCanvas = document.createElement('canvas');
  ocrCanvas.width = numW;
  ocrCanvas.height = numH;
  const ctx = ocrCanvas.getContext('2d');
  
  // Draw the collector number region
  ctx.drawImage(video, numX, numY, numW, numH, 0, 0, numW, numH);
  
  // Enhance contrast for better OCR
  const imageData = ctx.getImageData(0, 0, numW, numH);
  const data = imageData.data;
  for (let i = 0; i < data.length; i += 4) {
    // Convert to grayscale
    const gray = 0.299 * data[i] + 0.587 * data[i+1] + 0.114 * data[i+2];
    // Increase contrast
    const enhanced = gray < 128 ? gray * 0.5 : 128 + (gray - 128) * 1.5;
    const clamped = Math.max(0, Math.min(255, enhanced));
    data[i] = data[i+1] = data[i+2] = clamped;
  }
  ctx.putImageData(imageData, 0, 0);

  try {
    const worker = await ensureTesseract();
    const { data: result } = await worker.recognize(ocrCanvas);
    
    // Extract collector number pattern (e.g., "123/456", "OGN-123", etc.)
    const text = result.text.trim();
    const patterns = [
      /(\d{1,3})\s*[\/\\]\s*(\d{1,3})/,  // 123/456
      /([A-Z]{2,4})-?(\d{1,3})/i,         // OGN-123
      /#?\s*(\d{1,3})/,                    // #123 or just 123
    ];
    
    let collectorNumber = null;
    for (const pattern of patterns) {
      const match = text.match(pattern);
      if (match) {
        collectorNumber = match[0].replace(/\s/g, '');
        break;
      }
    }
    
    return JSON.stringify({
      success: true,
      rawText: text,
      collectorNumber: collectorNumber,
      confidence: result.confidence,
    });
  } catch (e) {
    return JSON.stringify({ error: e.message || 'OCR failed' });
  }
}

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

/**
 * Run local OCR on a base64 image to extract collector number
 * @param {string} base64Image - The image as base64 data URL
 * @param {Object} cardRegion - Optional {x, y, width, height} of detected card
 */
async function ocrFromBase64(base64Image, cardRegion) {
  try {
    const worker = await ensureTesseract();
    
    // Create image element from base64
    const img = new Image();
    await new Promise((resolve, reject) => {
      img.onload = resolve;
      img.onerror = reject;
      img.src = base64Image;
    });
    
    // Create canvas for OCR region (bottom portion of card)
    const canvas = document.createElement('canvas');
    const ctx = canvas.getContext('2d');
    
    let cropX, cropY, cropW, cropH;
    
    if (cardRegion && cardRegion.width > 0) {
      // Use detected card region - extract bottom 15% for collector number
      cropX = cardRegion.x + cardRegion.width * 0.3;
      cropY = cardRegion.y + cardRegion.height * 0.85;
      cropW = cardRegion.width * 0.5;
      cropH = cardRegion.height * 0.12;
    } else {
      // Fallback: bottom center of image
      cropX = img.width * 0.3;
      cropY = img.height * 0.85;
      cropW = img.width * 0.4;
      cropH = img.height * 0.12;
    }
    
    canvas.width = Math.max(1, Math.round(cropW));
    canvas.height = Math.max(1, Math.round(cropH));
    
    ctx.drawImage(img, cropX, cropY, cropW, cropH, 0, 0, canvas.width, canvas.height);
    
    // Enhance contrast
    const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
    const data = imageData.data;
    for (let i = 0; i < data.length; i += 4) {
      const gray = 0.299 * data[i] + 0.587 * data[i+1] + 0.114 * data[i+2];
      // High contrast: make dark pixels darker, light pixels lighter
      const enhanced = gray < 128 ? 0 : 255;
      data[i] = data[i+1] = data[i+2] = enhanced;
    }
    ctx.putImageData(imageData, 0, 0);
    
    // Run OCR
    const { data: result } = await worker.recognize(canvas);
    const text = result.text.trim();
    
    // Extract collector number pattern
    const patterns = [
      /(\d{1,3})\s*[\/\\]\s*(\d{1,3})/,  // 123/456
      /([A-Z]{2,4})[- ]?(\d{1,3})/i,      // OGN-123, SVP 123
      /#\s*(\d{1,3})/,                    // #123
      /(\d{2,3})(?:\s|$)/,                // Just numbers at end
    ];
    
    let collectorNumber = null;
    for (const pattern of patterns) {
      const match = text.match(pattern);
      if (match) {
        collectorNumber = match[0].replace(/\s+/g, '').toUpperCase();
        break;
      }
    }
    
    return JSON.stringify({
      success: true,
      rawText: text,
      collectorNumber: collectorNumber,
      confidence: result.confidence,
    });
  } catch (e) {
    console.error('OCR error:', e);
    return JSON.stringify({ error: e.message || 'OCR failed' });
  }
}

window.initOcrWorker = initOcrWorker;
window.startOcrCamera = startOcrCamera;
window.captureAndRecognize = captureAndRecognize;
window.captureAndRecognizeLocal = captureAndRecognizeLocal;
window.captureFrame = captureFrame;
window.stopOcrCamera = stopOcrCamera;
window.createOcrContainer = createOcrContainer;
window.vibrateDevice = vibrateDevice;
window.ensureTesseract = ensureTesseract;
window.ocrFromBase64 = ocrFromBase64;
