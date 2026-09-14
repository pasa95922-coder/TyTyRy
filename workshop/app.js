(() => {
  'use strict';

  const CELL = 96;
  const palette = [
    '#101222', '#191b32', '#22233f', '#2b2d50', '#373960', '#454870', '#575b83', '#737897',
    '#0b2935', '#103b46', '#15505a', '#196773', '#21818a', '#299c9f', '#39b9b4', '#63d4c9',
    '#94e5d5', '#c0f3df', '#292840', '#413b50', '#5e5266', '#7a6d80', '#4d535e', '#727b82',
    '#928e80', '#b6af98', '#d6cfb1', '#f1e6c7', '#72441f', '#ac6929', '#eaa13c', '#ffda78'
  ];

  const $ = (id) => document.getElementById(id);
  const stage = $('stage');
  const overlay = $('overlay');
  const ctx = stage.getContext('2d', { alpha: true });
  const octx = overlay.getContext('2d', { alpha: true });
  const assetGrid = $('asset-grid');
  const layerList = $('layer-list');
  const framesEl = $('frames');
  const images = new Map();
  const assets = new Map();
  let libraryMode = 'character';
  let selectedLayerId = null;
  let tool = 'select';
  let gridVisible = true;
  let onionVisible = false;
  let pickedColor = null;
  let crop = null;
  let pointer = null;
  let playing = false;
  let speed = 1;
  let toastTimer = 0;
  let state;
  let history = [];
  let historyIndex = -1;

  const imgPath = (type, index) => `assets/frames/${type}_${String(index).padStart(2, '0')}.png`;
  const addAssetDefinition = (id, path, name, group) => assets.set(id, { id, path, name, group });
  for (let i = 0; i < 8; i += 1) addAssetDefinition(`idle-${i}`, imgPath('idle', i), `Покой ${String(i + 1).padStart(2, '0')}`, 'character');
  for (let i = 0; i < 10; i += 1) addAssetDefinition(`attack-${i}`, imgPath('attack', i), `Атака ${String(i + 1).padStart(2, '0')}`, 'character');
  for (let i = 0; i < 6; i += 1) addAssetDefinition(`hurt-${i}`, imgPath('hurt', i), `Урон ${String(i + 1).padStart(2, '0')}`, 'character');
  for (let i = 0; i < 8; i += 1) addAssetDefinition(`death-${i}`, imgPath('death', i), `Смерть ${String(i + 1).padStart(2, '0')}`, 'character');
  for (let i = 0; i < 4; i += 1) addAssetDefinition(`fx-${i}`, imgPath('fx', i), `Вспышка ${i + 1}`, 'effects');

  const loadImage = (asset) => new Promise((resolve) => {
    if (images.has(asset.id)) return resolve(images.get(asset.id));
    const image = new Image();
    image.onload = () => { images.set(asset.id, image); resolve(image); };
    image.onerror = () => { images.set(asset.id, null); resolve(null); };
    image.src = asset.path;
  });

  const layer = (assetId, name, extra = {}) => ({
    id: `layer-${crypto.randomUUID()}`,
    assetId,
    name: name || assets.get(assetId)?.name || 'Пустой слой',
    x: 0, y: 0, scale: 1, rotation: 0, opacity: 100, hue: 0, brightness: 100, saturation: 100,
    flipX: false, visible: true, tint: null, crop: null, cutouts: [], recolors: [], ...extra
  });
  const frame = (duration, layers) => ({ id: `frame-${crypto.randomUUID()}`, duration, scale: 1, layers });
  const defaultAnimation = (kind, count, durations) => ({
    name: kind === 'idle' ? 'Покой' : kind === 'attack' ? 'Атака' : kind === 'hurt' ? 'Получение урона' : 'Смерть',
    playback: kind === 'idle' ? 'loop' : 'once',
    frames: Array.from({ length: count }, (_, i) => {
      const layers = [layer(`${kind}-${i}`, `${kind === 'idle' ? 'Зверь' : kind === 'attack' ? 'Удар' : kind === 'hurt' ? 'Реакция' : 'Смерть'} ${String(i + 1).padStart(2, '0')}`)];
      if (kind === 'attack' && i >= 4 && i <= 7) layers.push(layer(`fx-${i - 4}`, `Ударный след ${i - 3}`, { y: 18 }));
      return frame(durations[i], layers);
    })
  });

  const defaultState = () => ({
    title: 'Мифический зверь',
    currentAnimation: 'attack',
    currentFrame: 0,
    animations: {
      idle: defaultAnimation('idle', 8, [140, 140, 160, 180, 140, 140, 160, 180]),
      attack: defaultAnimation('attack', 10, [90, 90, 110, 60, 40, 80, 70, 90, 110, 140]),
      hurt: defaultAnimation('hurt', 6, [50, 70, 90, 100, 110, 140]),
      death: defaultAnimation('death', 8, [100, 80, 90, 110, 120, 160, 180, 240])
    }
  });

  const deepClone = (value) => JSON.parse(JSON.stringify(value));
  const currentAnimation = () => state.animations[state.currentAnimation];
  const currentFrame = () => currentAnimation().frames[state.currentFrame];
  const selectedLayer = () => currentFrame()?.layers.find((item) => item.id === selectedLayerId) || null;
  const colorTargets = (item) => {
    if ($('color-scope')?.value !== 'animation') return [item];
    const layerIndex = currentFrame().layers.indexOf(item);
    const family = item.assetId?.replace(/-\d+$/, '');
    return currentAnimation().frames
      .map((itemFrame) => itemFrame.layers[layerIndex])
      .filter((candidate) => candidate && candidate.assetId?.replace(/-\d+$/, '') === family);
  };
  const commit = () => {
    history = history.slice(0, historyIndex + 1);
    history.push(JSON.stringify(state));
    if (history.length > 40) history.shift();
    historyIndex = history.length - 1;
    localStorage.setItem('sprite-workshop-project', JSON.stringify(state));
    updateHistoryButtons();
  };
  const restoreHistory = (next) => {
    state = JSON.parse(history[next]);
    historyIndex = next;
    selectedLayerId = currentFrame().layers.at(-1)?.id || null;
    localStorage.setItem('sprite-workshop-project', JSON.stringify(state));
    updateHistoryButtons();
    renderAll();
  };
  const updateHistoryButtons = () => {
    $('undo').disabled = historyIndex <= 0;
    $('redo').disabled = historyIndex >= history.length - 1;
  };
  const change = (callback, save = true) => {
    callback();
    if (save) commit();
    renderAll();
  };
  const showToast = (message) => {
    const toast = $('toast');
    toast.textContent = message;
    toast.classList.add('is-visible');
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => toast.classList.remove('is-visible'), 2100);
  };

  function renderLibrary() {
    assetGrid.innerHTML = '';
    const visible = [...assets.values()].filter((asset) => asset.group === libraryMode);
    if (!visible.length) {
      assetGrid.innerHTML = '<p class="hint">Здесь появятся ваши импортированные PNG.</p>';
      return;
    }
    for (const asset of visible) {
      const button = document.createElement('button');
      button.className = 'asset';
      button.title = `${asset.name}: добавить в кадр`;
      button.dataset.asset = asset.id;
      const image = images.get(asset.id);
      if (image) {
        const preview = document.createElement('img');
        preview.src = asset.path;
        preview.alt = asset.name;
        button.append(preview);
      } else {
        button.textContent = '…';
      }
      const label = document.createElement('small');
      label.textContent = asset.name.replace(/[^0-9]/g, '') || '＋';
      button.append(label);
      assetGrid.append(button);
    }
  }

  const rgbToHex = (r, g, b) => `#${[r, g, b].map((value) => value.toString(16).padStart(2, '0')).join('')}`;
  const sameRgb = (data, pixel, color) => data[pixel * 4] === color[0] && data[pixel * 4 + 1] === color[1] && data[pixel * 4 + 2] === color[2] && data[pixel * 4 + 3] > 0;
  function applyRecolors(context, item) {
    if (!item.recolors?.length) return;
    const imageData = context.getImageData(0, 0, CELL, CELL);
    const data = imageData.data;
    for (const replacement of item.recolors) {
      const from = hexRgb(replacement.from); const target = hexRgb(replacement.to);
      const paint = (pixel) => { data[pixel * 4] = target[0]; data[pixel * 4 + 1] = target[1]; data[pixel * 4 + 2] = target[2]; };
      if (replacement.mode === 'connected' && replacement.seed) {
        const start = replacement.seed.y * CELL + replacement.seed.x;
        if (!sameRgb(data, start, from)) continue;
        const queue = new Int32Array(CELL * CELL); const visited = new Uint8Array(CELL * CELL);
        let head = 0; let tail = 1; queue[0] = start; visited[start] = 1;
        while (head < tail) {
          const pixel = queue[head++]; paint(pixel);
          const x = pixel % CELL; const y = Math.floor(pixel / CELL);
          const neighbours = [pixel - 1, pixel + 1, pixel - CELL, pixel + CELL];
          for (const next of neighbours) {
            const nx = next % CELL; const ny = Math.floor(next / CELL);
            if (nx < 0 || nx >= CELL || ny < 0 || ny >= CELL || Math.abs(nx - x) + Math.abs(ny - y) !== 1 || visited[next] || !sameRgb(data, next, from)) continue;
            visited[next] = 1; queue[tail++] = next;
          }
        }
      } else {
        for (let pixel = 0; pixel < CELL * CELL; pixel += 1) if (sameRgb(data, pixel, from)) paint(pixel);
      }
    }
    context.putImageData(imageData, 0, 0);
  }

  function sourceCanvas(item) {
    const image = images.get(item.assetId);
    if (!image) return null;
    const offscreen = document.createElement('canvas');
    offscreen.width = CELL; offscreen.height = CELL;
    const offctx = offscreen.getContext('2d');
    if (item.crop) {
      const c = item.crop;
      offctx.drawImage(image, c.x, c.y, c.w, c.h, c.x, c.y, c.w, c.h);
    } else {
      offctx.drawImage(image, 0, 0, CELL, CELL);
    }
    for (const cut of item.cutouts || []) offctx.clearRect(cut.x, cut.y, cut.w, cut.h);
    applyRecolors(offctx, item);
    return offscreen;
  }

  function drawFrame(target, itemFrame, options = {}) {
    const clear = options.clear !== false;
    const frameOpacity = options.opacity ?? 1;
    if (clear) target.clearRect(0, 0, CELL, CELL);
    const frameScale = Number(itemFrame.scale) || 1;
    target.save();
    target.translate(48, 92);
    target.scale(frameScale, frameScale);
    target.translate(-48, -92);
    for (const item of itemFrame.layers) {
      if (!item.visible || !images.get(item.assetId)) continue;
      const source = sourceCanvas(item);
      if (!source) continue;
      target.save();
      target.translate(48 + item.x, 48 + item.y);
      target.rotate(item.rotation * Math.PI / 180);
      target.scale(item.flipX ? -item.scale : item.scale, item.scale);
      target.globalAlpha = frameOpacity * Math.max(0, Math.min(1, item.opacity / 100));
      target.imageSmoothingEnabled = false;
      target.filter = `hue-rotate(${item.hue}deg) brightness(${item.brightness}%) saturate(${item.saturation}%)`;
      target.drawImage(source, -48, -48, CELL, CELL);
      if (item.tint) {
        target.globalCompositeOperation = 'source-atop';
        target.globalAlpha = frameOpacity * Math.max(0, Math.min(1, item.opacity / 100)) * .32;
        target.fillStyle = item.tint;
        target.fillRect(-48, -48, CELL, CELL);
      }
      target.restore();
    }
    target.restore();
  }

  function renderStage() {
    ctx.clearRect(0, 0, CELL, CELL);
    if (onionVisible) {
      const animation = currentAnimation();
      const before = animation.frames[state.currentFrame - 1];
      const after = animation.frames[state.currentFrame + 1];
      if (before) drawFrame(ctx, before, { clear: false, opacity: .16 });
      if (after) drawFrame(ctx, after, { clear: false, opacity: .16 });
    }
    drawFrame(ctx, currentFrame(), { clear: false });
  }

  function drawOverlay() {
    octx.clearRect(0, 0, CELL, CELL);
    octx.imageSmoothingEnabled = false;
    if (gridVisible) {
      octx.save();
      octx.strokeStyle = 'rgba(176, 207, 230, .21)';
      octx.lineWidth = .24;
      for (let i = 8; i < CELL; i += 8) {
        octx.beginPath(); octx.moveTo(i, 0); octx.lineTo(i, CELL); octx.stroke();
        octx.beginPath(); octx.moveTo(0, i); octx.lineTo(CELL, i); octx.stroke();
      }
      octx.strokeStyle = 'rgba(57, 185, 180, .62)';
      octx.beginPath(); octx.moveTo(48, 88); octx.lineTo(48, 96); octx.stroke();
      octx.beginPath(); octx.moveTo(44, 92); octx.lineTo(52, 92); octx.stroke();
      octx.restore();
    }
    if (tool === 'select' && selectedLayer()) {
      const item = selectedLayer();
      const frameScale = Number(currentFrame().scale) || 1;
      const side = 96 * item.scale;
      octx.save();
      octx.translate(48, 92);
      octx.scale(frameScale, frameScale);
      octx.translate(-48, -92);
      octx.translate(48 + item.x, 48 + item.y);
      octx.rotate(item.rotation * Math.PI / 180);
      octx.strokeStyle = '#8ee7d6';
      octx.lineWidth = .7;
      octx.setLineDash([2, 1]);
      octx.strokeRect(-48 * item.scale, -48 * item.scale, side, side);
      octx.restore();
    }
    if (crop) {
      octx.save();
      octx.fillStyle = 'rgba(255, 218, 120, .12)';
      octx.strokeStyle = '#ffda78';
      octx.lineWidth = .8;
      octx.setLineDash([2, 1]);
      octx.fillRect(crop.x, crop.y, crop.w, crop.h);
      octx.strokeRect(crop.x, crop.y, crop.w, crop.h);
      octx.restore();
    }
  }

  function renderLayers() {
    layerList.innerHTML = '';
    const layers = currentFrame().layers;
    [...layers].reverse().forEach((item) => {
      const row = document.createElement('div');
      row.className = `layer-item${item.id === selectedLayerId ? ' is-selected' : ''}`;
      row.dataset.layer = item.id;
      row.innerHTML = `
        <button class="visibility" data-action="visibility" title="Показать/скрыть">${item.visible ? '◉' : '○'}</button>
        <button class="layer-name" data-action="select" title="Выбрать слой"></button>
        <button class="small-action" data-action="up" title="Выше">↑</button>
        <button class="small-action" data-action="down" title="Ниже">↓</button>
        <button class="small-action" data-action="delete" title="Удалить">×</button>`;
      row.querySelector('.layer-name').textContent = item.name;
      layerList.append(row);
    });
  }

  function updateInspector() {
    const item = selectedLayer();
    const inputs = document.querySelectorAll('#inspector input');
    $('delete-layer').disabled = !item;
    $('cut-part').disabled = !item || !crop;
    $('flip-x').disabled = !item;
    $('color-scope').disabled = !item;
    $('selected-name').textContent = item ? item.name : 'Ничего не выбрано';
    inputs.forEach((input) => { input.disabled = !item; });
    if (!item) return;
    $('layer-name').value = item.name;
    $('pos-x').value = item.x;
    $('pos-y').value = item.y;
    $('scale').value = item.scale;
    $('rotation').value = item.rotation;
    $('opacity').value = item.opacity;
    $('hue').value = item.hue;
    $('brightness').value = item.brightness;
    $('saturation').value = item.saturation;
    $('opacity-value').textContent = `${item.opacity}%`;
    $('hue-value').textContent = `${item.hue}°`;
  }

  function renderFrames() {
    framesEl.innerHTML = '';
    currentAnimation().frames.forEach((itemFrame, index) => {
      const button = document.createElement('button');
      button.className = `frame${index === state.currentFrame ? ' is-selected' : ''}`;
      button.dataset.frame = index;
      button.title = `Кадр ${index + 1}, ${itemFrame.duration} мс`;
      const thumb = document.createElement('canvas');
      thumb.width = CELL; thumb.height = CELL;
      drawFrame(thumb.getContext('2d'), itemFrame);
      button.append(thumb);
      const number = document.createElement('span'); number.className = 'frame-number'; number.textContent = String(index + 1).padStart(2, '0');
      const timing = document.createElement('span'); timing.className = 'frame-time'; timing.textContent = `${itemFrame.duration}мс`;
      button.append(number, timing);
      framesEl.append(button);
    });
    $('frame-duration').value = currentFrame().duration;
    $('frame-scale').value = Number(currentFrame().scale) || 1;
    const total = currentAnimation().frames.reduce((sum, item) => sum + item.duration, 0);
    $('timeline-summary').textContent = `${currentAnimation().frames.length} кадров · ${(total / 1000).toFixed(2)} с`;
  }

  function renderHeader() {
    $('project-name').value = state.title;
    $('animation-select').value = state.currentAnimation;
    $('frame-label').textContent = `${currentAnimation().name} · кадр ${String(state.currentFrame + 1).padStart(2, '0')}`;
    $('grid-toggle').classList.toggle('is-active', gridVisible);
    $('grid-toggle').setAttribute('aria-pressed', String(gridVisible));
    $('onion-toggle').classList.toggle('is-active', onionVisible);
    $('onion-toggle').setAttribute('aria-pressed', String(onionVisible));
    $('eyedropper-tool').classList.toggle('is-active', tool === 'eyedropper');
    $('tool-hint').textContent = tool === 'crop'
      ? 'Потяните рамку по части спрайта, затем нажмите «Вынести фрагмент».'
      : tool === 'eyedropper'
        ? 'Щёлкните по нужному оттенку на выбранном слое.'
        : 'Перетаскивайте выбранный слой мышью или стрелками.';
  }

  function renderAll() {
    renderStage();
    drawOverlay();
    renderHeader();
    renderLibrary();
    renderPalette();
    renderLayers();
    updateInspector();
    renderFrames();
  }

  function setFrame(index) {
    state.currentFrame = Math.max(0, Math.min(currentAnimation().frames.length - 1, index));
    selectedLayerId = currentFrame().layers.at(-1)?.id || null;
    crop = null;
    renderAll();
  }

  function getPoint(event) {
    const box = overlay.getBoundingClientRect();
    return {
      x: Math.max(0, Math.min(CELL, Math.round((event.clientX - box.left) / box.width * CELL))),
      y: Math.max(0, Math.min(CELL, Math.round((event.clientY - box.top) / box.height * CELL)))
    };
  }

  function pickColorAtStage(point) {
    const item = selectedLayer();
    if (!item) return showToast('Сначала выберите слой.');
    const frameScale = Number(currentFrame().scale) || 1;
    let x = 48 + (point.x - 48) / frameScale;
    let y = 92 + (point.y - 92) / frameScale;
    const dx = x - (48 + item.x); const dy = y - (48 + item.y);
    const angle = -item.rotation * Math.PI / 180;
    let localX = dx * Math.cos(angle) - dy * Math.sin(angle);
    const localY = dx * Math.sin(angle) + dy * Math.cos(angle);
    if (item.flipX) localX = -localX;
    const scale = item.scale || 1;
    const sourceX = Math.round(localX / scale + 48);
    const sourceY = Math.round(localY / scale + 48);
    if (sourceX < 0 || sourceX >= CELL || sourceY < 0 || sourceY >= CELL) return showToast('Этот пиксель вне выбранного слоя.');
    const source = sourceCanvas(item);
    const pixel = source?.getContext('2d').getImageData(sourceX, sourceY, 1, 1).data;
    if (!pixel || pixel[3] === 0) return showToast('Здесь нет непрозрачного пикселя выбранного слоя.');
    pickedColor = { hex: rgbToHex(pixel[0], pixel[1], pixel[2]), seed: { x: sourceX, y: sourceY } };
    renderPalette();
    showToast(`Выбран цвет ${pickedColor.hex.toUpperCase()}.`);
  }

  function exportCanvas() {
    const c = document.createElement('canvas'); c.width = CELL; c.height = CELL;
    drawFrame(c.getContext('2d'), currentFrame());
    return c;
  }
  function download(blob, name) {
    const url = URL.createObjectURL(blob);
    const anchor = document.createElement('a');
    anchor.href = url; anchor.download = name; anchor.click();
    setTimeout(() => URL.revokeObjectURL(url), 1000);
  }
  function exportPng() {
    exportCanvas().toBlob((blob) => {
      if (blob) download(blob, `${safeName(state.title)}_${state.currentAnimation}_${String(state.currentFrame + 1).padStart(2, '0')}.png`);
    }, 'image/png');
  }
  const transliteration = {
    а: 'a', б: 'b', в: 'v', г: 'g', д: 'd', е: 'e', ё: 'e', ж: 'zh', з: 'z', и: 'i', й: 'y', к: 'k', л: 'l', м: 'm', н: 'n', о: 'o', п: 'p', р: 'r', с: 's', т: 't', у: 'u', ф: 'f', х: 'h', ц: 'ts', ч: 'ch', ш: 'sh', щ: 'sch', ъ: '', ы: 'y', ь: '', э: 'e', ю: 'yu', я: 'ya'
  };
  const safeName = (value) => {
    const latin = value.trim().toLowerCase().replace(/[а-яё]/g, (letter) => transliteration[letter] || '');
    return latin.replace(/[^a-z0-9]+/g, '_').replace(/^_|_$/g, '') || 'sprite';
  };

  const crcTable = (() => {
    const table = new Uint32Array(256);
    for (let i = 0; i < 256; i += 1) {
      let value = i;
      for (let bit = 0; bit < 8; bit += 1) value = (value >>> 1) ^ ((value & 1) ? 0xedb88320 : 0);
      table[i] = value >>> 0;
    }
    return table;
  })();
  const crc32 = (bytes) => {
    let value = 0xffffffff;
    for (const byte of bytes) value = (value >>> 8) ^ crcTable[(value ^ byte) & 255];
    return (value ^ 0xffffffff) >>> 0;
  };
  const u16 = (value) => Uint8Array.of(value & 255, (value >>> 8) & 255);
  const u32 = (value) => Uint8Array.of(value & 255, (value >>> 8) & 255, (value >>> 16) & 255, (value >>> 24) & 255);
  const concat = (chunks) => {
    const length = chunks.reduce((sum, chunk) => sum + chunk.length, 0);
    const merged = new Uint8Array(length); let cursor = 0;
    chunks.forEach((chunk) => { merged.set(chunk, cursor); cursor += chunk.length; });
    return merged;
  };
  const zipStore = (entries) => {
    const encoder = new TextEncoder(); const local = []; const central = []; let offset = 0;
    entries.forEach((entry) => {
      const name = encoder.encode(entry.name); const checksum = crc32(entry.data);
      const header = concat([u32(0x04034b50), u16(20), u16(0), u16(0), u16(0), u16(0), u32(checksum), u32(entry.data.length), u32(entry.data.length), u16(name.length), u16(0)]);
      local.push(header, name, entry.data);
      central.push(concat([u32(0x02014b50), u16(20), u16(20), u16(0), u16(0), u16(0), u16(0), u32(checksum), u32(entry.data.length), u32(entry.data.length), u16(name.length), u16(0), u16(0), u16(0), u16(0), u32(0), u32(offset), name]));
      offset += header.length + name.length + entry.data.length;
    });
    const centralBytes = concat(central);
    return concat([...local, centralBytes, u32(0x06054b50), u16(0), u16(0), u16(entries.length), u16(entries.length), u32(centralBytes.length), u32(offset), u16(0)]);
  };
  const canvasPng = (canvas) => new Promise((resolve) => canvas.toBlob(resolve, 'image/png'));
  async function exportAllPngFrames() {
    const animation = currentAnimation();
    const animationName = { idle: 'idle', attack: 'attack', hurt: 'hurt', death: 'death' }[state.currentAnimation] || 'animation';
    const base = `beast_${animationName}`;
    const entries = [];
    for (let index = 0; index < animation.frames.length; index += 1) {
      const canvas = document.createElement('canvas'); canvas.width = CELL; canvas.height = CELL;
      drawFrame(canvas.getContext('2d'), animation.frames[index]);
      const blob = await canvasPng(canvas);
      if (!blob) throw new Error('Не удалось собрать PNG-кадр.');
      entries.push({ name: `${base}/${base}_${String(index + 1).padStart(2, '0')}.png`, data: new Uint8Array(await blob.arrayBuffer()) });
    }
    download(new Blob([zipStore(entries)], { type: 'application/zip' }), `${base}_png_frames.zip`);
    showToast(`Скачан ZIP: ${entries.length} PNG-кадров.`);
  }

  function hexRgb(hex) {
    const n = Number.parseInt(hex.slice(1), 16);
    return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
  }
  function nearestIndex(r, g, b) {
    let pick = 1; let best = Infinity;
    palette.forEach((color, index) => {
      const [pr, pg, pb] = hexRgb(color);
      const distance = (r - pr) ** 2 + (g - pg) ** 2 + (b - pb) ** 2;
      if (distance < best) { best = distance; pick = index + 1; }
    });
    return pick;
  }
  function gifIndices(imageData, width, height) {
    const indexed = new Uint8Array(width * height);
    for (let pixel = 0, out = 0; pixel < imageData.length; pixel += 4, out += 1) {
      indexed[out] = imageData[pixel + 3] < 128 ? 0 : nearestIndex(imageData[pixel], imageData[pixel + 1], imageData[pixel + 2]);
    }
    return indexed;
  }
  function lzw(data, minCodeSize) {
    const clear = 1 << minCodeSize;
    const end = clear + 1;
    let dictionary; let codeSize; let nextCode; let bytes = []; let accumulator = 0; let bits = 0;
    const write = (code) => {
      accumulator |= code << bits;
      bits += codeSize;
      while (bits >= 8) { bytes.push(accumulator & 255); accumulator >>= 8; bits -= 8; }
    };
    const reset = () => {
      dictionary = new Map();
      for (let i = 0; i < clear; i += 1) dictionary.set(String(i), i);
      codeSize = minCodeSize + 1;
      nextCode = end + 1;
    };
    reset(); write(clear);
    let prefix = String(data[0]);
    for (let i = 1; i < data.length; i += 1) {
      const key = `${prefix},${data[i]}`;
      if (dictionary.has(key)) { prefix = key; continue; }
      write(dictionary.get(prefix));
      if (nextCode < 4096) {
        dictionary.set(key, nextCode);
        nextCode += 1;
        if (nextCode === (1 << codeSize) && codeSize < 12) codeSize += 1;
      } else {
        write(clear); reset();
      }
      prefix = String(data[i]);
    }
    write(dictionary.get(prefix)); write(end);
    if (bits > 0) bytes.push(accumulator & 255);
    return bytes;
  }
  function gifBytes(scale = 4) {
    const width = CELL * scale;
    const height = CELL * scale;
    const output = [];
    const text = (value) => [...value].forEach((char) => output.push(char.charCodeAt(0)));
    const word = (value) => output.push(value & 255, (value >> 8) & 255);
    text('GIF89a'); word(width); word(height); output.push(0xf5, 0, 0);
    output.push(0, 0, 0);
    palette.forEach((color) => output.push(...hexRgb(color)));
    while (output.length < 13 + 64 * 3) output.push(0, 0, 0);
    text('!\xff\x0bNETSCAPE2.0\x03\x01'); word(0); output.push(0);
    const spriteCanvas = document.createElement('canvas'); spriteCanvas.width = CELL; spriteCanvas.height = CELL;
    const spriteCtx = spriteCanvas.getContext('2d', { willReadFrequently: true });
    const encoderCanvas = document.createElement('canvas'); encoderCanvas.width = width; encoderCanvas.height = height;
    const encoderCtx = encoderCanvas.getContext('2d', { willReadFrequently: true });
    encoderCtx.imageSmoothingEnabled = false;
    for (const itemFrame of currentAnimation().frames) {
      drawFrame(spriteCtx, itemFrame);
      encoderCtx.clearRect(0, 0, width, height);
      encoderCtx.drawImage(spriteCanvas, 0, 0, width, height);
      const delay = Math.max(2, Math.round(itemFrame.duration / 10));
      output.push(0x21, 0xf9, 0x04, 0x09, delay & 255, delay >> 8, 0, 0);
      output.push(0x2c, 0, 0, 0, 0); word(width); word(height); output.push(0);
      const compressed = lzw(gifIndices(encoderCtx.getImageData(0, 0, width, height).data, width, height), 6);
      output.push(6);
      for (let i = 0; i < compressed.length; i += 255) {
        const chunk = compressed.slice(i, i + 255);
        output.push(chunk.length, ...chunk);
      }
      output.push(0);
    }
    output.push(0x3b);
    return new Uint8Array(output);
  }
  const verifyGif = (blob) => new Promise((resolve, reject) => {
    const image = new Image(); const url = URL.createObjectURL(blob);
    image.onload = () => { URL.revokeObjectURL(url); resolve(); };
    image.onerror = () => { URL.revokeObjectURL(url); reject(new Error('GIF не прошёл проверку браузером.')); };
    image.src = url;
  });
  async function exportGif() {
    const button = $('export-gif'); const label = button.textContent;
    button.disabled = true; button.textContent = 'Собираю GIF…';
    try {
      const blob = new Blob([gifBytes(4)], { type: 'image/gif' });
      await verifyGif(blob);
      const animationName = { idle: 'idle', attack: 'attack', hurt: 'hurt', death: 'death' }[state.currentAnimation] || 'animation';
      download(blob, `beast_${animationName}_preview.gif`);
      showToast('Скачан GIF-превью ×4: его можно отправлять на просмотр.');
    } catch (error) {
      showToast(error.message || 'Не удалось собрать GIF.');
    } finally {
      button.disabled = false; button.textContent = label;
    }
  }

  function wireEvents() {
    document.querySelectorAll('#library-tabs .tab').forEach((button) => button.addEventListener('click', () => {
      libraryMode = button.dataset.library;
      document.querySelectorAll('#library-tabs .tab').forEach((tab) => {
        const active = tab === button;
        tab.classList.toggle('is-active', active); tab.setAttribute('aria-selected', String(active));
      });
      renderLibrary();
    }));
    assetGrid.addEventListener('click', (event) => {
      const button = event.target.closest('[data-asset]'); if (!button) return;
      const asset = assets.get(button.dataset.asset);
      change(() => {
        const extra = asset.group === 'effects' ? { y: 18 } : {};
        const item = layer(asset.id, asset.name, extra);
        currentFrame().layers.push(item); selectedLayerId = item.id;
      });
    });
    layerList.addEventListener('click', (event) => {
      const row = event.target.closest('[data-layer]'); if (!row) return;
      const item = currentFrame().layers.find((entry) => entry.id === row.dataset.layer); if (!item) return;
      const action = event.target.closest('button')?.dataset.action || 'select';
      if (action === 'select') { selectedLayerId = item.id; crop = null; renderAll(); return; }
      change(() => {
        const list = currentFrame().layers; const index = list.indexOf(item);
        if (action === 'visibility') item.visible = !item.visible;
        if (action === 'delete') { list.splice(index, 1); selectedLayerId = list.at(-1)?.id || null; }
        if (action === 'up' && index < list.length - 1) [list[index], list[index + 1]] = [list[index + 1], list[index]];
        if (action === 'down' && index > 0) [list[index], list[index - 1]] = [list[index - 1], list[index]];
      });
    });
    $('delete-layer').addEventListener('click', () => change(() => {
      const list = currentFrame().layers; const index = list.findIndex((item) => item.id === selectedLayerId);
      if (index >= 0) list.splice(index, 1);
      selectedLayerId = list.at(-1)?.id || null; crop = null;
    }));
    $('add-empty-layer').addEventListener('click', () => change(() => {
      const item = layer(null, 'Пустой слой'); currentFrame().layers.push(item); selectedLayerId = item.id;
    }));
    $('cut-part').addEventListener('click', () => {
      const item = selectedLayer(); if (!item || !crop) return;
      change(() => {
        const fragment = layer(item.assetId, `${item.name} — фрагмент`, { crop: deepClone(crop), x: item.x, y: item.y, hue: item.hue, brightness: item.brightness, saturation: item.saturation, tint: item.tint, recolors: deepClone(item.recolors || []) });
        item.cutouts.push(deepClone(crop));
        const index = currentFrame().layers.indexOf(item); currentFrame().layers.splice(index + 1, 0, fragment);
        selectedLayerId = fragment.id; crop = null; tool = 'select';
      });
      showToast('Фрагмент стал отдельным слоем — его можно двигать и красить.');
    });
    $('flip-x').addEventListener('click', () => change(() => { const item = selectedLayer(); if (item) item.flipX = !item.flipX; }));
    document.querySelectorAll('#inspector [data-prop]').forEach((input) => {
      input.addEventListener('input', () => {
        const item = selectedLayer(); if (!item) return;
        const key = input.dataset.prop;
        const value = key === 'name' ? input.value : Number(input.value);
        if (['hue', 'brightness', 'saturation'].includes(key)) colorTargets(item).forEach((candidate) => { candidate[key] = value; });
        else item[key] = value;
        if (key === 'opacity') $('opacity-value').textContent = `${item.opacity}%`;
        if (key === 'hue') $('hue-value').textContent = `${item.hue}°`;
        renderStage(); drawOverlay(); renderLayers(); $('selected-name').textContent = item.name;
      });
      input.addEventListener('change', commit);
    });
    $('palette').addEventListener('click', (event) => {
      const button = event.target.closest('[data-color]'); if (!button) return;
      $('palette-color').value = button.dataset.color;
      showToast(`Новый цвет: ${button.dataset.color.toUpperCase()}.`);
    });
    $('add-palette-color').addEventListener('click', () => {
      const color = $('palette-color').value;
      if (palette.includes(color)) return showToast('Этот цвет уже есть в палитре.');
      palette.push(color); renderPalette(); showToast('Цвет добавлен в палитру.');
    });
    $('eyedropper-tool').addEventListener('click', () => {
      tool = 'eyedropper'; crop = null; renderHeader(); drawOverlay();
    });
    $('apply-recolor').addEventListener('click', () => {
      const item = selectedLayer(); if (!item || !pickedColor) return;
      const target = $('palette-color').value;
      if (target.toLowerCase() === pickedColor.hex.toLowerCase()) return showToast('Исходный и новый цвет совпадают.');
      const scope = $('recolor-scope').value; const mode = $('recolor-mode').value;
      change(() => {
        const index = currentFrame().layers.indexOf(item);
        const family = item.assetId?.replace(/-\d+$/, '');
        const targets = scope === 'animation'
          ? currentAnimation().frames.map((itemFrame) => itemFrame.layers[index]).filter((candidate) => candidate && candidate.assetId?.replace(/-\d+$/, '') === family)
          : [item];
        targets.forEach((candidate) => {
          candidate.recolors ||= [];
          candidate.recolors.push({ id: crypto.randomUUID(), from: pickedColor.hex, to: target, mode, seed: mode === 'connected' ? deepClone(pickedColor.seed) : null });
        });
      });
      showToast(scope === 'animation' ? 'Замена применена к этому слою во всех кадрах анимации.' : 'Цвет заменён в выбранном слое.');
      pickedColor = null; renderPalette();
    });
    $('clear-recolors').addEventListener('click', () => change(() => { const item = selectedLayer(); if (item) item.recolors = []; }));
    $('recolor-list').addEventListener('click', (event) => {
      const button = event.target.closest('[data-recolor-index]'); const item = selectedLayer(); if (!button || !item) return;
      change(() => { item.recolors.splice(Number(button.dataset.recolorIndex), 1); });
    });
    $('animation-select').addEventListener('change', (event) => {
      state.currentAnimation = event.target.value; state.currentFrame = 0; selectedLayerId = currentFrame().layers.at(-1)?.id || null; crop = null; renderAll();
    });
    $('new-animation').addEventListener('click', () => {
      const name = window.prompt('Название новой анимации', 'Новая анимация');
      if (!name?.trim()) return;
      const id = `custom-${Date.now()}`;
      change(() => { state.animations[id] = { name: name.trim(), playback: 'loop', frames: [deepClone(currentFrame())] }; state.currentAnimation = id; state.currentFrame = 0; selectedLayerId = currentFrame().layers.at(-1)?.id || null; });
      const option = document.createElement('option'); option.value = id; option.textContent = name.trim(); $('animation-select').append(option); $('animation-select').value = id;
    });
    $('previous-frame').addEventListener('click', () => setFrame(state.currentFrame - 1));
    $('next-frame').addEventListener('click', () => setFrame(state.currentFrame + 1));
    framesEl.addEventListener('click', (event) => { const button = event.target.closest('[data-frame]'); if (button) setFrame(Number(button.dataset.frame)); });
    $('frame-duration').addEventListener('change', (event) => change(() => { currentFrame().duration = Math.max(20, Number(event.target.value) || 90); }));
    $('frame-scale').addEventListener('change', (event) => {
      const scale = Math.max(.25, Math.min(3, Number(event.target.value) || 1));
      const scope = $('frame-scale-scope').value;
      change(() => {
        const targets = scope === 'animation' ? currentAnimation().frames : [currentFrame()];
        targets.forEach((itemFrame) => { itemFrame.scale = scale; });
      });
      showToast(scope === 'animation' ? `Масштаб ${scale}× применён ко всем кадрам анимации.` : `Масштаб кадра: ${scale}×.`);
    });
    $('reset-frame-scale').addEventListener('click', () => {
      const scope = $('frame-scale-scope').value;
      change(() => {
        const targets = scope === 'animation' ? currentAnimation().frames : [currentFrame()];
        targets.forEach((itemFrame) => { itemFrame.scale = 1; });
      });
      showToast(scope === 'animation' ? 'Масштаб всех кадров сброшен.' : 'Масштаб кадра сброшен.');
    });
    $('duplicate-frame').addEventListener('click', () => change(() => {
      const copy = deepClone(currentFrame()); copy.id = `frame-${crypto.randomUUID()}`; copy.layers.forEach((item) => { item.id = `layer-${crypto.randomUUID()}`; });
      currentAnimation().frames.splice(state.currentFrame + 1, 0, copy); state.currentFrame += 1; selectedLayerId = copy.layers.at(-1)?.id || null;
    }));
    $('add-frame').addEventListener('click', () => change(() => {
      const item = frame(currentFrame().duration, []); currentAnimation().frames.splice(state.currentFrame + 1, 0, item); state.currentFrame += 1; selectedLayerId = null;
    }));
    $('remove-frame').addEventListener('click', () => {
      if (currentAnimation().frames.length <= 1) return showToast('В анимации должен остаться хотя бы один кадр.');
      change(() => { currentAnimation().frames.splice(state.currentFrame, 1); state.currentFrame = Math.min(state.currentFrame, currentAnimation().frames.length - 1); selectedLayerId = currentFrame().layers.at(-1)?.id || null; });
    });
    $('play').addEventListener('click', () => { playing ? stopPlayback() : playAnimation(); });
    $('speed').addEventListener('input', (event) => { speed = Number(event.target.value); });
    $('grid-toggle').addEventListener('click', () => { gridVisible = !gridVisible; renderHeader(); drawOverlay(); });
    $('onion-toggle').addEventListener('click', () => { onionVisible = !onionVisible; renderHeader(); renderStage(); drawOverlay(); });
    document.querySelectorAll('[data-tool]').forEach((button) => button.addEventListener('click', () => {
      tool = button.dataset.tool; crop = null;
      document.querySelectorAll('[data-tool]').forEach((entry) => entry.classList.toggle('is-active', entry === button));
      renderHeader(); drawOverlay(); updateInspector();
    }));
    $('undo').addEventListener('click', () => { if (historyIndex > 0) restoreHistory(historyIndex - 1); });
    $('redo').addEventListener('click', () => { if (historyIndex < history.length - 1) restoreHistory(historyIndex + 1); });
    $('project-name').addEventListener('change', (event) => change(() => { state.title = event.target.value || 'Без названия'; }));
    $('export-png').addEventListener('click', exportPng);
    $('export-frames').addEventListener('click', () => { exportAllPngFrames().catch((error) => showToast(error.message)); });
    $('export-gif').addEventListener('click', exportGif);
    $('import-image').addEventListener('click', () => $('file-input').click());
    $('file-input').addEventListener('change', (event) => {
      const file = event.target.files?.[0]; if (!file) return;
      const reader = new FileReader();
      reader.onload = () => {
        const id = `custom-${crypto.randomUUID()}`;
        const asset = { id, path: reader.result, name: file.name.replace(/\.[^.]+$/, ''), group: 'custom' };
        assets.set(id, asset); loadImage(asset).then(() => { libraryMode = 'custom'; document.querySelector('[data-library="custom"]').click(); showToast('Спрайт добавлен в библиотеку.'); });
      };
      reader.readAsDataURL(file); event.target.value = '';
    });
    overlay.addEventListener('pointerdown', (event) => {
      overlay.setPointerCapture(event.pointerId); const point = getPoint(event);
      if (tool === 'eyedropper') { pickColorAtStage(point); return; }
      if (tool === 'crop') { crop = { x: point.x, y: point.y, w: 0, h: 0 }; pointer = { kind: 'crop', x: point.x, y: point.y }; drawOverlay(); updateInspector(); return; }
      const item = selectedLayer(); if (!item) return;
      pointer = { kind: 'move', x: point.x, y: point.y, baseX: item.x, baseY: item.y, changed: false };
    });
    overlay.addEventListener('pointermove', (event) => {
      if (!pointer) return; const point = getPoint(event);
      if (pointer.kind === 'crop') {
        crop = { x: Math.min(pointer.x, point.x), y: Math.min(pointer.y, point.y), w: Math.abs(point.x - pointer.x), h: Math.abs(point.y - pointer.y) };
        drawOverlay(); updateInspector(); return;
      }
      const item = selectedLayer(); if (!item) return;
      item.x = pointer.baseX + point.x - pointer.x; item.y = pointer.baseY + point.y - pointer.y; pointer.changed = true;
      renderStage(); drawOverlay(); updateInspector();
    });
    overlay.addEventListener('pointerup', () => { if (pointer?.kind === 'move' && pointer.changed) commit(); pointer = null; });
    document.addEventListener('keydown', (event) => {
      if (event.target.matches('input, textarea, select')) return;
      const item = selectedLayer(); if (!item || tool !== 'select') return;
      const amount = event.shiftKey ? 5 : 1;
      const keys = { ArrowLeft: ['x', -amount], ArrowRight: ['x', amount], ArrowUp: ['y', -amount], ArrowDown: ['y', amount] };
      if (!keys[event.key]) return;
      event.preventDefault(); item[keys[event.key][0]] += keys[event.key][1]; commit(); renderAll();
    });
  }

  function renderPalette() {
    const root = $('palette'); root.innerHTML = '';
    palette.forEach((color) => {
      const button = document.createElement('button'); button.className = 'swatch'; button.style.background = color; button.dataset.color = color; button.title = `Использовать как новый цвет: ${color}`; root.append(button);
    });
    const item = selectedLayer();
    $('picked-color').textContent = pickedColor ? `Выбран: ${pickedColor.hex.toUpperCase()}` : 'Выберите цвет на спрайте';
    $('picked-swatch').style.background = pickedColor?.hex || '';
    $('apply-recolor').disabled = !item || !pickedColor;
    $('clear-recolors').disabled = !item?.recolors?.length;
    const list = $('recolor-list'); list.innerHTML = '';
    (item?.recolors || []).forEach((replacement, index) => {
      const row = document.createElement('div'); row.className = 'recolor-chip';
      row.innerHTML = `<span class="color-dot" style="background:${replacement.from}"></span><span>→</span><span class="color-dot" style="background:${replacement.to}"></span><span>${replacement.mode === 'connected' ? 'участок' : 'все'}</span><button data-recolor-index="${index}" title="Убрать замену">×</button>`;
      list.append(row);
    });
  }
  function stopPlayback() { playing = false; $('play').textContent = '▶ Воспроизвести'; }
  function playAnimation() {
    playing = true; $('play').textContent = '■ Остановить';
    const tick = () => {
      if (!playing) return;
      const atEnd = state.currentFrame >= currentAnimation().frames.length - 1;
      if (atEnd && !$('loop').checked) { stopPlayback(); return; }
      setFrame(atEnd ? 0 : state.currentFrame + 1);
      setTimeout(tick, currentFrame().duration / speed);
    };
    setTimeout(tick, currentFrame().duration / speed);
  }

  async function boot() {
    state = defaultState();
    const saved = localStorage.getItem('sprite-workshop-project');
    if (saved) {
      try { state = JSON.parse(saved); } catch { /* Ignore incompatible local copy. */ }
    }
    if (!state.animations.death) state.animations.death = defaultAnimation('death', 8, [100, 80, 90, 110, 120, 160, 180, 240]);
    Object.values(state.animations).forEach((animation) => animation.frames.forEach((itemFrame) => {
      if (itemFrame.scale === undefined) itemFrame.scale = 1;
      itemFrame.layers.forEach((item) => { if (!item.recolors) item.recolors = []; });
    }));
    const loads = [...assets.values()].map(loadImage);
    await Promise.all(loads);
    selectedLayerId = currentFrame().layers.at(-1)?.id || null;
    commit(); wireEvents(); renderPalette(); renderAll();
  }
  boot();
})();
