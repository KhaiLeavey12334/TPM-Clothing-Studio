const app = document.querySelector('.app');
const closeButton = document.querySelector('#closeButton');
const pageTitle = document.querySelector('#pageTitle');
const navItems = [...document.querySelectorAll('.nav__item')];
const pages = [...document.querySelectorAll('[data-page-panel]')];
const slotSelect = document.querySelector('#slotSelect');
const drawableInput = document.querySelector('#drawableInput');
const textureInput = document.querySelector('#textureInput');
const modeLabel = document.querySelector('#modeLabel');
const selectionLabel = document.querySelector('#selectionLabel');
const drawableMetric = document.querySelector('#drawableMetric');
const textureMetric = document.querySelector('#textureMetric');
const collectionMetric = document.querySelector('#collectionMetric');
const filenameMetric = document.querySelector('#filenameMetric');

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

function updateState(state) {
    currentMode = state.mode;
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
    collectionMetric.textContent = state.collection;
    filenameMetric.textContent = `${state.mode}_${String(state.mode === 'prop' ? state.propId : state.componentId).padStart(3, '0')}_${String(state.drawable).padStart(3, '0')}_${String(state.texture).padStart(3, '0')}.jpg`;
}

function setMode(mode) {
    fillSlots(mode);

    const eventName = mode === 'prop' ? 'clothing:setProp' : 'clothing:setComponent';
    const key = mode === 'prop' ? 'propId' : 'componentId';

    postNui(eventName, { [key]: Number(slotSelect.value) });
}

window.addEventListener('message', (event) => {
    if (event.data?.type === 'studio:visibility') {
        setVisible(Boolean(event.data.visible));
    }

    if (event.data?.type === 'clothing:state') {
        updateState(event.data.payload);
    }
});

navItems.forEach((item) => {
    item.addEventListener('click', () => setPage(item.dataset.page));
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
        postNui(eventName, { [field]: Number(input.value) });
    });
});

slotSelect.addEventListener('change', () => setMode(currentMode));
drawableInput.addEventListener('change', () => postNui('clothing:setDrawable', { drawable: Number(drawableInput.value) }));
textureInput.addEventListener('change', () => postNui('clothing:setTexture', { texture: Number(textureInput.value) }));

closeButton.addEventListener('click', () => {
    setVisible(false);
    postNui('studio:close');
});

fillSlots(currentMode);
