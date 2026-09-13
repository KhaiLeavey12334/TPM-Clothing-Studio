const app = document.querySelector('.app');
const bootLoader = document.querySelector('#bootLoader');
const bootLoaderText = document.querySelector('#bootLoaderText');
const bootLoaderProgress = document.querySelector('#bootLoaderProgress');
const closeButton = document.querySelector('#closeButton');
const fullscreenButton = document.querySelector('#fullscreenButton');
const windowedButton = document.querySelector('#windowedButton');
const screenshotKeySelect = document.querySelector('#screenshotKeySelect');
const packNameInput = document.querySelector('#packNameInput');
const savePackNameButton = document.querySelector('#savePackNameButton');
const captureButton = document.querySelector('#captureButton');
const pageTitle = document.querySelector('#pageTitle');
const navItems = [...document.querySelectorAll('.nav__item')];
const pages = [...document.querySelectorAll('[data-page-panel]')];
const slotSelect = document.querySelector('#slotSelect');
const drawableInput = document.querySelector('#drawableInput');
const textureInput = document.querySelector('#textureInput');
const pedSelect = document.querySelector('#pedSelect');
const pedApplyButton = document.querySelector('#pedApplyButton');
const modeLabel = document.querySelector('#modeLabel');
const selectionLabel = document.querySelector('#selectionLabel');
const drawableMetric = document.querySelector('#drawableMetric');
const textureMetric = document.querySelector('#textureMetric');
const collectionMetric = document.querySelector('#collectionMetric');
const browserDrawableCount = document.querySelector('#browserDrawableCount');
const browserTextureCount = document.querySelector('#browserTextureCount');
const browserPackLabel = document.querySelector('#browserPackLabel');
const filenameMetric = document.querySelector('#filenameMetric');
const autoMetric = document.querySelector('#autoMetric');
const etaMetric = document.querySelector('#etaMetric');
const autoProgress = document.querySelector('#autoProgress');
const autoActions = document.querySelector('#autoActions');
const autoStartButton = document.querySelector('#autoStartButton');
const autoPauseButton = document.querySelector('#autoPauseButton');
const autoResumeButton = document.querySelector('#autoResumeButton');
const autoEndButton = document.querySelector('#autoEndButton');
const toast = document.querySelector('#toast');
const toastTitle = document.querySelector('#toastTitle');
const toastBody = document.querySelector('#toastBody');
const toastProgress = document.querySelector('#toastProgress');
const rangeModal = document.querySelector('#rangeModal');
const rangeTitle = document.querySelector('#rangeTitle');
const rangeBody = document.querySelector('#rangeBody');
const rangeInput = document.querySelector('#rangeInput');
const rangeCancelButton = document.querySelector('#rangeCancelButton');
const rangeNextButton = document.querySelector('#rangeNextButton');

const slots = {
    component: [['0', 'Face'], ['1', 'Mask'], ['2', 'Hair'], ['3', 'Arms'], ['4', 'Legs'], ['5', 'Bags'], ['6', 'Shoes'], ['7', 'Accessories'], ['8', 'Undershirt'], ['9', 'Body Armor'], ['10', 'Decals'], ['11', 'Tops']],
    prop: [['0', 'Hats'], ['1', 'Glasses'], ['2', 'Ear Pieces'], ['6', 'Watches'], ['7', 'Bracelets']]
};

let currentMode = 'component';
let isFullscreen = localStorage.getItem('tpmFullscreen') === 'true';
let toastTimer = 0;
let packName = localStorage.getItem('tpmPackName') || '';
let activePackLabel = 'Base GTA';
let rangeStart = 0;
let bootComplete = false;
let bootRunning = false;
let currentClothingState = { drawableCount: 0, textureCount: 0 };
let autoState = { active: false, paused: false, total: 0, completed: 0 };
const bootSteps = [
    'Loading player profile...',
    'Matching freemode body data...',
    'Indexing drawable slots...',
    'Preparing texture scanner...',
    'Syncing screenshot queue...',
    'Calibrating studio camera...',
    'Finalising TPM interface...'
];

function audioTone(kind = 'press') {
    const AudioContext = window.AudioContext || window.webkitAudioContext;
    if (!AudioContext) return;

    const audio = new AudioContext();
    const oscillator = audio.createOscillator();
    const gain = audio.createGain();
    const map = {
        press: [520, 760, 0.08, 0.04],
        open: [280, 620, 0.18, 0.055],
        close: [520, 180, 0.16, 0.045],
        done: [420, 880, 0.26, 0.07]
    };
    const [from, to, length, volume] = map[kind] || map.press;

    oscillator.type = kind === 'done' ? 'triangle' : 'sine';
    oscillator.frequency.setValueAtTime(from, audio.currentTime);
    oscillator.frequency.exponentialRampToValueAtTime(to, audio.currentTime + length);
    gain.gain.setValueAtTime(0.0001, audio.currentTime);
    gain.gain.exponentialRampToValueAtTime(volume, audio.currentTime + 0.018);
    gain.gain.exponentialRampToValueAtTime(0.0001, audio.currentTime + length);
    oscillator.connect(gain);
    gain.connect(audio.destination);
    oscillator.start();
    oscillator.stop(audio.currentTime + length + 0.02);
    window.setTimeout(() => audio.close(), 350);
}

function getResourceName() {
    return window.GetParentResourceName ? window.GetParentResourceName() : 'tpm_clothing_studio';
}

function postNui(eventName, payload = {}) {
    return fetch(`https://${getResourceName()}/${eventName}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(payload)
    });
}

function action(eventName, payload = {}) {
    audioTone('press');
    return postNui(eventName, payload);
}

function showToast(title, body, options = {}) {
    window.clearTimeout(toastTimer);
    toastTitle.textContent = title;
    toastBody.textContent = body || '';
    toast.classList.toggle('has-progress', options.progress !== undefined);
    toast.dataset.visible = 'true';

    if (options.progress !== undefined) {
        toastProgress.value = Math.max(0, Math.min(100, options.progress));
    }

    if (options.timeout !== 0) {
        toastTimer = window.setTimeout(() => {
            toast.dataset.visible = 'false';
        }, options.timeout || 6000);
    }
}

function setPage(pageName) {
    navItems.forEach((item) => item.classList.toggle('is-active', item.dataset.page === pageName));
    pages.forEach((page) => page.classList.toggle('is-active', page.dataset.pagePanel === pageName));
    pageTitle.textContent = pageName.charAt(0).toUpperCase() + pageName.slice(1);
}

function fillSlots(mode) {
    currentMode = mode;
    slotSelect.innerHTML = '';
    slots[mode].forEach(([id, label]) => {
        const option = document.createElement('option');
        option.value = id;
        option.textContent = label;
        slotSelect.append(option);
    });
}

function selectedSlotLabel() {
    return slotSelect.options[slotSelect.selectedIndex]?.textContent || 'Unknown';
}

function sanitizePackName(value) {
    return String(value || '').replace(/[^\w-]/g, '_').toLowerCase();
}

function formatEta(seconds) {
    if (!Number.isFinite(seconds) || seconds <= 0) return '--';
    return `${Math.floor(seconds / 60)}m ${seconds % 60}s`;
}

function updateFilename(state) {
    const slot = state.mode === 'prop' ? state.propId : state.componentId;
    filenameMetric.textContent = `${packName ? `${packName}_` : ''}${state.mode}_${String(slot).padStart(3, '0')}_${String(state.drawable).padStart(3, '0')}_${String(state.texture).padStart(3, '0')}.jpg`;
}

function updateState(state) {
    currentClothingState = state;
    currentMode = state.mode;
    activePackLabel = state.packLabel || activePackLabel;
    fillSlots(state.mode);

    slotSelect.value = String(state.mode === 'prop' ? state.propId : state.componentId);
    drawableInput.value = state.drawable;
    textureInput.value = state.texture;
    drawableInput.max = Math.max(0, state.drawableCount - 1);
    textureInput.max = Math.max(0, state.textureCount - 1);
    modeLabel.textContent = state.mode === 'prop' ? 'Prop' : 'Component';
    selectionLabel.textContent = selectedSlotLabel();
    drawableMetric.textContent = `${state.drawable} / ${Math.max(0, state.drawableCount - 1)}`;
    textureMetric.textContent = `${state.texture} / ${Math.max(0, state.textureCount - 1)}`;
    collectionMetric.textContent = state.collection || 'base';
    browserDrawableCount.textContent = String(state.drawableCount || 0);
    browserTextureCount.textContent = String(state.textureCount || 0);
    browserPackLabel.textContent = activePackLabel;
    updateFilename(state);
}

function renderAutoActions(state) {
    autoStartButton.hidden = state.active;
    autoPauseButton.hidden = !state.active || state.paused;
    autoResumeButton.hidden = !state.active || !state.paused;
    autoEndButton.hidden = !state.active;
    autoActions.classList.toggle('is-running', state.active);
}

function updateAutoPreview(state) {
    autoState = state;
    const total = Math.max(1, state.total || 0);
    const completed = state.completed || 0;
    const percent = Math.floor((completed / total) * 100);

    autoProgress.value = percent;
    autoMetric.textContent = state.active ? `${completed} / ${state.total}` : 'Idle';
    etaMetric.textContent = state.paused ? 'Paused' : formatEta(state.etaSeconds);
    renderAutoActions(state);

    if (state.active) {
        showToast('Screenshots in progress', `${completed} of ${state.total} captured`, { progress: percent, timeout: 0 });
    }
}

function setFullscreen(enabled) {
    isFullscreen = enabled;
    app.classList.toggle('is-fullscreen', enabled);
    localStorage.setItem('tpmFullscreen', String(enabled));
}

function setVisible(visible) {
    app.dataset.visible = String(visible);
    if (!visible) {
        bootLoader.dataset.visible = 'false';
        app.classList.remove('is-booting');
        return;
    }

    if (bootComplete) {
        audioTone('open');
        return;
    }

    runBootLoader();
}

function runBootLoader() {
    if (bootRunning) return;

    bootRunning = true;
    app.classList.add('is-booting');
    bootLoader.dataset.visible = 'true';
    bootLoaderProgress.value = 0;
    bootLoaderText.textContent = bootSteps[0];

    const startedAt = Date.now();
    const duration = 6000;
    const timer = window.setInterval(() => {
        const elapsed = Date.now() - startedAt;
        const percent = Math.min(100, Math.floor((elapsed / duration) * 100));
        const stepIndex = Math.min(bootSteps.length - 1, Math.floor((percent / 100) * bootSteps.length));

        bootLoaderProgress.value = percent;
        bootLoaderText.textContent = bootSteps[stepIndex];

        if (percent >= 100) {
            window.clearInterval(timer);
            bootComplete = true;
            bootRunning = false;
            bootLoader.dataset.visible = 'false';
            app.classList.remove('is-booting');
            audioTone('open');
        }
    }, 80);
}

function openRangeModal() {
    const maxDrawable = Math.max(0, (currentClothingState.drawableCount || 1) - 1);
    rangeModal.dataset.visible = 'true';
    rangeModal.dataset.step = 'start';
    rangeTitle.textContent = 'Auto Screenshot Range';
    rangeBody.textContent = 'What drawable number do you want to start at?';
    rangeInput.min = '0';
    rangeInput.max = String(maxDrawable);
    rangeInput.value = String(Number(drawableInput.value || 0));
    rangeNextButton.textContent = 'Next';
    rangeInput.focus();
    rangeInput.select();
}

function submitRangeStep() {
    const maxDrawable = Math.max(0, (currentClothingState.drawableCount || 1) - 1);
    const value = Math.max(0, Math.min(maxDrawable, Number(rangeInput.value || 0)));

    if (rangeModal.dataset.step === 'start') {
        rangeStart = value;
        rangeModal.dataset.step = 'end';
        rangeBody.textContent = `Starting at drawable ${rangeStart}. What drawable number do you want to end at?`;
        rangeInput.min = String(rangeStart);
        rangeInput.max = String(maxDrawable);
        rangeInput.value = String(rangeStart);
        rangeNextButton.textContent = 'Start';
        rangeInput.focus();
        rangeInput.select();
        return;
    }

    rangeModal.dataset.visible = 'false';
    action('autoPreview:start', { startDrawable: rangeStart, endDrawable: value }).then((response) => response.json()).then((result) => {
        if (!result.ok) {
            showToast('Auto Screenshot did not start', result.error || 'Check F8 for details.', { timeout: 9000 });
        }
    });
}

function fillPeds(peds = []) {
    pedSelect.innerHTML = '';
    peds.forEach((ped) => {
        const option = document.createElement('option');
        option.value = ped.model;
        option.textContent = `${ped.label}${ped.started === false ? ' (stopped)' : ''}`;
        pedSelect.append(option);
    });
}

window.addEventListener('message', (event) => {
    if (event.data?.type === 'studio:visibility') setVisible(Boolean(event.data.visible));
    if (event.data?.type === 'clothing:state') updateState(event.data.payload);
    if (event.data?.type === 'autoPreview:state') updateAutoPreview(event.data.payload);
    if (event.data?.type === 'peds:update') fillPeds(event.data.payload);

    if (event.data?.type === 'screenshot:result') {
        const result = event.data.payload || {};
        captureButton.disabled = false;
        if (result.context === 'manual') {
            showToast(result.success ? 'Screenshot taken' : 'Screenshot failed', result.success ? `Save Location: ${result.path}` : result.message, { timeout: result.success ? 9000 : 12000 });
        }
    }

    if (event.data?.type === 'autoPreview:complete') {
        audioTone('done');
        showToast('Task Complete', 'Auto screenshots finished successfully.', { progress: 100, timeout: 12000 });
    }

    if (event.data?.type === 'autoPreview:stopped') {
        audioTone('close');
        showToast('Auto Screenshot ended', 'The task was cancelled.', { timeout: 8000 });
    }

    if (event.data?.type === 'settings:keySaved') {
        showToast('Screenshot key saved', `${event.data.payload?.key || screenshotKeySelect.value} will apply after restarting the resource.`);
    }

    if (event.data?.type === 'settings:packSaved') {
        packName = event.data.payload?.packName || '';
        localStorage.setItem('tpmPackName', packName);
        showToast('Pack name saved', packName ? `Screenshots will use ${packName}_ as the filename prefix.` : 'Pack name cleared.');
    }
});

navItems.forEach((item) => item.addEventListener('click', () => {
    audioTone('press');
    setPage(item.dataset.page);
}));

document.querySelectorAll('[data-mode]').forEach((button) => button.addEventListener('click', () => {
    fillSlots(button.dataset.mode);
    const eventName = button.dataset.mode === 'prop' ? 'clothing:setProp' : 'clothing:setComponent';
    const key = button.dataset.mode === 'prop' ? 'propId' : 'componentId';
    action(eventName, { [key]: Number(slotSelect.value) });
}));

document.querySelectorAll('[data-step]').forEach((button) => button.addEventListener('click', () => {
    const [field, rawDelta] = button.dataset.step.split(':');
    const delta = Number(rawDelta);
    const input = field === 'drawable' ? drawableInput : textureInput;
    input.value = Number(input.value) + delta;
    action(field === 'drawable' ? 'clothing:setDrawable' : 'clothing:setTexture', { [field]: Number(input.value) });
}));

document.querySelectorAll('[data-auto]').forEach((button) => button.addEventListener('click', () => {
    if (button.dataset.auto === 'start') {
        audioTone('press');
        openRangeModal();
        return;
    }

    action(`autoPreview:${button.dataset.auto}`);
}));

document.querySelectorAll('[data-ped-model]').forEach((button) => button.addEventListener('click', () => {
    action('ped:setModel', { model: button.dataset.pedModel }).then((response) => response.json()).then((result) => {
        if (!result.ok) showToast('Ped failed', result.error || 'Could not apply that ped.');
    });
}));

pedApplyButton.addEventListener('click', () => {
    action('ped:setModel', { model: pedSelect.value }).then((response) => response.json()).then((result) => {
        if (!result.ok) showToast('Ped failed', result.error || 'Could not apply that ped.');
    });
});

slotSelect.addEventListener('change', () => {
    action(currentMode === 'prop' ? 'clothing:setProp' : 'clothing:setComponent', { [currentMode === 'prop' ? 'propId' : 'componentId']: Number(slotSelect.value) });
});
drawableInput.addEventListener('change', () => action('clothing:setDrawable', { drawable: Number(drawableInput.value) }));
textureInput.addEventListener('change', () => action('clothing:setTexture', { texture: Number(textureInput.value) }));

closeButton.addEventListener('click', () => {
    audioTone('close');
    postNui('studio:close');
});
fullscreenButton.addEventListener('click', () => setFullscreen(true));
windowedButton.addEventListener('click', () => setFullscreen(false));
rangeCancelButton.addEventListener('click', () => {
    audioTone('close');
    rangeModal.dataset.visible = 'false';
});
rangeNextButton.addEventListener('click', submitRangeStep);
rangeInput.addEventListener('keydown', (event) => {
    if (event.key === 'Enter') submitRangeStep();
});

screenshotKeySelect.addEventListener('change', () => {
    localStorage.setItem('tpmScreenshotKey', screenshotKeySelect.value);
    action('settings:screenshotKey', { key: screenshotKeySelect.value });
});

savePackNameButton.addEventListener('click', () => {
    packName = sanitizePackName(packNameInput.value);
    packNameInput.value = packName;
    localStorage.setItem('tpmPackName', packName);
    action('settings:packName', { packName });
    updateFilename({
        mode: currentMode,
        componentId: Number(slotSelect.value || 11),
        propId: Number(slotSelect.value || 0),
        drawable: Number(drawableInput.value || 0),
        texture: Number(textureInput.value || 0)
    });
});

captureButton.addEventListener('click', () => {
    showToast('Taking screenshot', 'Hiding the menu and saving the current item...', { timeout: 0 });
    captureButton.disabled = true;
    action('screenshot:capture').then((response) => response.json()).then((result) => {
        if (!result.ok) {
            showToast('Screenshot did not start', result.error || 'The client rejected the screenshot request.', { timeout: 9000 });
            captureButton.disabled = false;
        }
    });
});

document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') {
        audioTone('close');
        postNui('studio:close');
    }
});

screenshotKeySelect.value = localStorage.getItem('tpmScreenshotKey') || 'F13';
packNameInput.value = packName;
setFullscreen(isFullscreen);
fillSlots(currentMode);
renderAutoActions(autoState);
