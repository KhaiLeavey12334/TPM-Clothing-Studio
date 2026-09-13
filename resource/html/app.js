const app = document.querySelector('.app');
const closeButton = document.querySelector('#closeButton');
const minimizeButton = document.querySelector('#minimizeButton');
const dockButton = document.querySelector('#dockButton');
const dockStatus = document.querySelector('#dockStatus');
const dockCount = document.querySelector('#dockCount');
const dockEta = document.querySelector('#dockEta');
const dockProgress = document.querySelector('#dockProgress');
const fullscreenButton = document.querySelector('#fullscreenButton');
const fullscreenToggle = document.querySelector('#fullscreenToggle');
const themeSelect = document.querySelector('#themeSelect');
const screenshotKeySelect = document.querySelector('#screenshotKeySelect');
const packNameInput = document.querySelector('#packNameInput');
const savePackNameButton = document.querySelector('#savePackNameButton');
const captureButton = document.querySelector('#captureButton');
const pageTitle = document.querySelector('#pageTitle');
const navItems = [...document.querySelectorAll('.nav__item')];
const pages = [...document.querySelectorAll('[data-page-panel]')];
const slotSelect = document.querySelector('#slotSelect');
const packSelect = document.querySelector('#packSelect');
const drawableInput = document.querySelector('#drawableInput');
const textureInput = document.querySelector('#textureInput');
const modeLabel = document.querySelector('#modeLabel');
const selectionLabel = document.querySelector('#selectionLabel');
const drawableMetric = document.querySelector('#drawableMetric');
const textureMetric = document.querySelector('#textureMetric');
const collectionMetric = document.querySelector('#collectionMetric');
const browserDrawableCount = document.querySelector('#browserDrawableCount');
const browserTextureCount = document.querySelector('#browserTextureCount');
const browserPackLabel = document.querySelector('#browserPackLabel');
const packMetric = document.querySelector('#packMetric');
const packCollectionMetric = document.querySelector('#packCollectionMetric');
const packResourceMetric = document.querySelector('#packResourceMetric');
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
const limitModal = document.querySelector('#limitModal');
const limitModalText = document.querySelector('#limitModalText');
const limitInput = document.querySelector('#limitInput');
const limitCancelButton = document.querySelector('#limitCancelButton');
const limitStartButton = document.querySelector('#limitStartButton');
const welcomeModal = document.querySelector('#welcomeModal');
const welcomeLearnButton = document.querySelector('#welcomeLearnButton');
const welcomeDiveButton = document.querySelector('#welcomeDiveButton');
const welcomeUnderstoodButton = document.querySelector('#welcomeUnderstoodButton');

const slots = {
    component: [
        ['0', 'Face'],
        ['1', 'Mask'],
        ['2', 'Hair'],
        ['3', 'Arms'],
        ['4', 'Legs'],
        ['5', 'Bags'],
        ['6', 'Shoes'],
        ['7', 'Accessories'],
        ['8', 'Undershirt'],
        ['9', 'Body Armor'],
        ['10', 'Decals'],
        ['11', 'Tops']
    ],
    prop: [
        ['0', 'Hats'],
        ['1', 'Glasses'],
        ['2', 'Ear Pieces'],
        ['6', 'Watches'],
        ['7', 'Bracelets']
    ]
};

let currentMode = 'component';
let isFullscreen = localStorage.getItem('tpmFullscreen') === 'true';
let isMinimized = localStorage.getItem('tpmMinimized') === 'true';
let toastTimer = 0;
let lastSavePath = '';
let packName = localStorage.getItem('tpmPackName') || '';
let packs = [];
let activePackId = 'base';
let hasSeenWelcome = sessionStorage.getItem('tpmWelcomeSeen') === 'true';
let currentClothingState = {
    drawableCount: 0,
    textureCount: 0
};
let autoState = {
    active: false,
    paused: false,
    total: 0,
    completed: 0
};

function playPressSound() {
    const AudioContext = window.AudioContext || window.webkitAudioContext;

    if (!AudioContext) {
        return;
    }

    const audio = new AudioContext();
    const oscillator = audio.createOscillator();
    const gain = audio.createGain();

    oscillator.type = 'sine';
    oscillator.frequency.setValueAtTime(520, audio.currentTime);
    oscillator.frequency.exponentialRampToValueAtTime(760, audio.currentTime + 0.045);
    gain.gain.setValueAtTime(0.0001, audio.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.045, audio.currentTime + 0.012);
    gain.gain.exponentialRampToValueAtTime(0.0001, audio.currentTime + 0.085);
    oscillator.connect(gain);
    gain.connect(audio.destination);
    oscillator.start();
    oscillator.stop(audio.currentTime + 0.09);
    window.setTimeout(() => audio.close(), 180);
}

function showToast(title, body, options = {}) {
    window.clearTimeout(toastTimer);
    toastTitle.textContent = title;
    toastBody.textContent = body || '';
    toast.dataset.visible = 'true';
    toast.classList.toggle('has-progress', options.progress !== undefined);

    if (options.progress !== undefined) {
        toastProgress.value = Math.max(0, Math.min(100, options.progress));
    }

    if (options.timeout !== 0) {
        toastTimer = window.setTimeout(() => {
            toast.dataset.visible = 'false';
        }, options.timeout || 6500);
    }
}

function renderAutoActions(state) {
    autoActions.classList.toggle('is-running', state.active);
    autoStartButton.hidden = state.active;
    autoPauseButton.hidden = !state.active || state.paused;
    autoResumeButton.hidden = !state.active || !state.paused;
    autoEndButton.hidden = !state.active;
}

function renderDock(state) {
    const total = Math.max(1, state.total || 0);
    const completed = state.completed || 0;
    const percent = Math.max(0, Math.min(100, Math.floor((completed / total) * 100)));

    dockStatus.textContent = state.active ? (state.paused ? 'Paused' : 'Running') : 'Idle';
    dockCount.textContent = state.total ? `${completed}/${state.total}` : '0/0';
    dockEta.textContent = state.active && !state.paused ? formatEta(state.etaSeconds) : '--';
    dockProgress.style.height = `${percent}%`;
}

function setLimitModalVisible(visible) {
    limitModal.dataset.visible = String(visible);
}

function setWelcomeVisible(visible) {
    welcomeModal.dataset.visible = String(visible);
}

function dismissWelcome() {
    hasSeenWelcome = true;
    sessionStorage.setItem('tpmWelcomeSeen', 'true');
    setWelcomeVisible(false);
}

function startAutoPreview(limit = 0) {
    return action('autoPreview:start', { limit }).then((response) => response.json()).then((result) => {
        if (!result.ok) {
            showToast('Auto Preview did not start', result.error || 'Check F8/client console and server console for a TPM Clothing Studio error.', {
                timeout: 9000
            });
        }
    }).catch(() => {
        showToast('Auto Preview error', 'The menu could not talk to the FiveM client callback.', {
            timeout: 9000
        });
    });
}

function applyTheme(theme) {
    document.documentElement.dataset.theme = theme;
    localStorage.setItem('tpmTheme', theme);
}

function sanitizePackName(value) {
    return String(value || '').replace(/[^\w-]/g, '_').toLowerCase();
}

function setFullscreen(enabled) {
    isFullscreen = enabled;
    app.classList.toggle('is-fullscreen', enabled);
    fullscreenToggle.checked = enabled;
    fullscreenButton.textContent = enabled ? 'Windowed' : 'Full Screen';
    localStorage.setItem('tpmFullscreen', String(enabled));
}

function setMinimized(enabled) {
    isMinimized = enabled;
    app.classList.toggle('is-minimized', enabled);
    localStorage.setItem('tpmMinimized', String(enabled));
    renderDock(autoState);
}

function setVisible(visible) {
    app.dataset.visible = String(visible);
}

function getResourceName() {
    return window.GetParentResourceName ? window.GetParentResourceName() : 'tpm-clothing-studio';
}

function postNui(eventName, payload = {}) {
    return fetch(`https://${getResourceName()}/${eventName}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8'
        },
        body: JSON.stringify(payload)
    });
}

function action(eventName, payload = {}) {
    playPressSound();
    return postNui(eventName, payload);
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

function fillPacks(nextPacks = []) {
    packs = Array.isArray(nextPacks) && nextPacks.length ? nextPacks : packs;

    if (!packs.length) {
        return;
    }

    packSelect.innerHTML = '';

    packs.forEach((pack) => {
        const option = document.createElement('option');
        option.value = pack.id;
        option.textContent = pack.label;
        packSelect.append(option);
    });

    packSelect.value = activePackId;
}

function findActivePack() {
    return packs.find((pack) => pack.id === activePackId) || packs[0] || {
        label: 'Default / Base GTA',
        collection: '',
        resource: ''
    };
}

function selectedSlotLabel() {
    return slotSelect.options[slotSelect.selectedIndex]?.textContent || 'Unknown';
}

function updateState(state) {
    currentClothingState = state;
    currentMode = state.mode;
    activePackId = state.packId || activePackId;
    fillSlots(state.mode);
    fillPacks(state.packs);

    slotSelect.value = String(state.mode === 'prop' ? state.propId : state.componentId);
    drawableInput.value = state.drawable;
    textureInput.value = state.texture;
    drawableInput.max = Math.max(0, state.drawableCount - 1);
    textureInput.max = Math.max(0, state.textureCount - 1);

    modeLabel.textContent = state.mode === 'prop' ? 'Prop' : 'Component';
    selectionLabel.textContent = selectedSlotLabel();
    drawableMetric.textContent = `${state.drawable} / ${Math.max(0, state.drawableCount - 1)}`;
    textureMetric.textContent = `${state.texture} / ${Math.max(0, state.textureCount - 1)}`;
    collectionMetric.textContent = state.collection;
    const activePack = findActivePack();
    browserDrawableCount.textContent = String(state.drawableCount || 0);
    browserTextureCount.textContent = String(state.textureCount || 0);
    browserPackLabel.textContent = state.packLabel || activePack.label;
    packMetric.textContent = `${state.packLabel || activePack.label}${activePack.started === false ? ' (not started)' : ''}`;
    packCollectionMetric.textContent = state.collection || 'base';
    packResourceMetric.textContent = activePack.resource ? `${activePack.resource}${activePack.started === false ? ' stopped' : ''}` : '--';
    filenameMetric.textContent = `${packName ? `${packName}_` : ''}${state.mode}_${String(state.mode === 'prop' ? state.propId : state.componentId).padStart(3, '0')}_${String(state.drawable).padStart(3, '0')}_${String(state.texture).padStart(3, '0')}.jpg`;
}

function formatEta(seconds) {
    if (!Number.isFinite(seconds) || seconds <= 0) {
        return '--';
    }

    const minutes = Math.floor(seconds / 60);
    const remainder = seconds % 60;

    return `${minutes}m ${remainder}s`;
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
    renderDock(state);

    if (state.active) {
        showToast('Screenshots in progress', `${completed} of ${state.total} captured`, {
            progress: percent,
            timeout: 0
        });
    }
}

function setMode(mode) {
    fillSlots(mode);

    const eventName = mode === 'prop' ? 'clothing:setProp' : 'clothing:setComponent';
    const key = mode === 'prop' ? 'propId' : 'componentId';

    action(eventName, { [key]: Number(slotSelect.value) });
}

window.addEventListener('message', (event) => {
    if (event.data?.type === 'studio:visibility') {
        setVisible(Boolean(event.data.visible));
        if (event.data.visible && !hasSeenWelcome) {
            setWelcomeVisible(true);
        }
    }

    if (event.data?.type === 'clothing:state') {
        updateState(event.data.payload);
    }

    if (event.data?.type === 'autoPreview:state') {
        updateAutoPreview(event.data.payload);
    }

    if (event.data?.type === 'screenshot:result') {
        const result = event.data.payload || {};
        lastSavePath = result.path || lastSavePath;
        captureButton.disabled = false;

        if (result.context === 'manual') {
            showToast(result.success ? 'Screenshot taken' : 'Screenshot failed', result.success ? `Save Location: ${lastSavePath}` : result.message, {
                timeout: result.success ? 9000 : 12000
            });
        }
    }

    if (event.data?.type === 'autoPreview:complete') {
        showToast('Task Complete', `Save Location: ${lastSavePath || 'Check the server console for screenshot-basic output.'}`, {
            progress: 100,
            timeout: 12000
        });
    }

    if (event.data?.type === 'autoPreview:stopped') {
        showToast('Auto Preview ended', lastSavePath ? `Last Save Location: ${lastSavePath}` : 'Stopped before a screenshot was saved.', {
            timeout: 8000
        });
    }

    if (event.data?.type === 'settings:keySaved') {
        const key = event.data.payload?.key || screenshotKeySelect.value;
        showToast('Screenshot key saved', `${key} will apply after restarting tpm_clothing_studio.`, {
            timeout: 6500
        });
    }

    if (event.data?.type === 'settings:packSaved') {
        packName = event.data.payload?.packName || '';
        localStorage.setItem('tpmPackName', packName);
        showToast('Pack name saved', packName ? `Screenshots will use ${packName}_ as the filename prefix.` : 'Pack name cleared.', {
            timeout: 6500
        });
    }
});

navItems.forEach((item) => {
    item.addEventListener('click', () => {
        playPressSound();
        setPage(item.dataset.page);
    });
});

document.querySelectorAll('[data-mode]').forEach((button) => {
    button.addEventListener('click', () => setMode(button.dataset.mode));
});

document.querySelectorAll('[data-step]').forEach((button) => {
    button.addEventListener('click', () => {
        const [field, rawDelta] = button.dataset.step.split(':');
        const delta = Number(rawDelta);
        const input = field === 'drawable' ? drawableInput : textureInput;
        const eventName = field === 'drawable' ? 'clothing:setDrawable' : 'clothing:setTexture';

        input.value = Number(input.value) + delta;
        action(eventName, { [field]: Number(input.value) });
    });
});

document.querySelectorAll('[data-auto]').forEach((button) => {
    button.addEventListener('click', () => {
        if (button.dataset.auto === 'start' && currentClothingState.drawableCount > 50) {
            const total = Math.max(1, currentClothingState.drawableCount || 0);
            limitModalText.textContent = `This slot has ${total} drawables. How many screenshots do you want to take?`;
            limitInput.max = String(total);
            limitInput.value = String(Math.min(50, total));
            setLimitModalVisible(true);
            playPressSound();
            return;
        }

        if (button.dataset.auto === 'resume' && (!autoState.active || !autoState.paused)) {
            showToast('Auto Preview is not paused', 'Start a task first, then pause it before using Resume.');
            return;
        }

        if (button.dataset.auto === 'pause' && (!autoState.active || autoState.paused)) {
            showToast('Auto Preview is not running', 'Start a task before using Pause.');
            return;
        }

        if (button.dataset.auto === 'stop' && !autoState.active) {
            showToast('Auto Preview is idle', 'There is no active task to end.');
            return;
        }

        if (button.dataset.auto === 'start') {
            startAutoPreview();
            return;
        }

        action(`autoPreview:${button.dataset.auto}`).then((response) => response.json()).then((result) => {
            if (!result.ok) {
                showToast('Auto Preview action failed', result.error || 'The Auto Preview action could not run.', {
                    timeout: 9000
                });
            }
        }).catch(() => {
            showToast('Auto Preview error', 'The menu could not talk to the FiveM client callback.', {
                timeout: 9000
            });
        });
    });
});

limitCancelButton.addEventListener('click', () => {
    playPressSound();
    setLimitModalVisible(false);
});

limitStartButton.addEventListener('click', () => {
    const max = Number(limitInput.max || currentClothingState.drawableCount || 1);
    const limit = Math.max(1, Math.min(max, Number(limitInput.value || 1)));

    setLimitModalVisible(false);
    startAutoPreview(limit);
});

welcomeLearnButton.addEventListener('click', () => {
    playPressSound();
    setPage('info');
    welcomeLearnButton.hidden = true;
    welcomeDiveButton.hidden = true;
    welcomeUnderstoodButton.hidden = false;
});

welcomeDiveButton.addEventListener('click', () => {
    playPressSound();
    dismissWelcome();
});

welcomeUnderstoodButton.addEventListener('click', () => {
    playPressSound();
    dismissWelcome();
});

slotSelect.addEventListener('change', () => setMode(currentMode));
packSelect.addEventListener('change', () => {
    action('pack:setActive', { packId: packSelect.value }).then((response) => response.json()).then((result) => {
        if (!result.ok) {
            showToast('Pack not available', 'That pack is not configured correctly yet.', {
                timeout: 8000
            });
        }
    }).catch(() => {
        showToast('Pack switch failed', 'The menu could not talk to the pack callback.', {
            timeout: 8000
        });
    });
});
drawableInput.addEventListener('change', () => action('clothing:setDrawable', { drawable: Number(drawableInput.value) }));
textureInput.addEventListener('change', () => action('clothing:setTexture', { texture: Number(textureInput.value) }));

closeButton.addEventListener('click', () => {
    playPressSound();
    setVisible(false);
    postNui('studio:close');
});

minimizeButton.addEventListener('click', () => {
    playPressSound();
    setMinimized(true);
});

dockButton.addEventListener('click', () => {
    playPressSound();
    setMinimized(false);
});

fullscreenButton.addEventListener('click', () => {
    playPressSound();
    setFullscreen(!isFullscreen);
});

fullscreenToggle.addEventListener('change', () => {
    playPressSound();
    setFullscreen(fullscreenToggle.checked);
});

themeSelect.addEventListener('change', () => {
    playPressSound();
    applyTheme(themeSelect.value);
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

    const clothingState = {
        mode: currentMode,
        componentId: Number(slotSelect.value || 11),
        propId: Number(slotSelect.value || 0),
        drawable: Number(drawableInput.value || 0),
        texture: Number(textureInput.value || 0),
        drawableCount: Number(drawableInput.max || 0) + 1,
        textureCount: Number(textureInput.max || 0) + 1,
        collection: collectionMetric.textContent || 'base'
    };
    updateState(clothingState);
});

captureButton.addEventListener('click', () => {
    showToast('Taking screenshot', 'Hiding the menu and saving the current item...', { timeout: 0 });
    captureButton.disabled = true;

    action('screenshot:capture').then((response) => response.json()).then((result) => {
        if (!result.ok) {
            showToast('Screenshot did not start', result.error || 'The FiveM client rejected the screenshot request.', {
                timeout: 9000
            });
            captureButton.disabled = false;
        }
    }).catch(() => {
        showToast('Screenshot error', 'The menu could not talk to the screenshot callback.', {
            timeout: 9000
        });
        captureButton.disabled = false;
    });
});

const savedTheme = localStorage.getItem('tpmTheme') || 'tpm';
const savedScreenshotKey = localStorage.getItem('tpmScreenshotKey') || 'F13';
themeSelect.value = savedTheme;
screenshotKeySelect.value = savedScreenshotKey;
packNameInput.value = packName;
applyTheme(savedTheme);
setFullscreen(isFullscreen);
setMinimized(isMinimized);
fillSlots(currentMode);
renderAutoActions(autoState);
renderDock(autoState);
