const app = document.querySelector('.app');
const closeButton = document.querySelector('#closeButton');

function setVisible(visible) {
    app.dataset.visible = String(visible);
}

function postNui(eventName, payload = {}) {
    const resourceName = window.GetParentResourceName ? window.GetParentResourceName() : 'tpm-clothing-studio';

    return fetch(`https://${resourceName}/${eventName}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8'
        },
        body: JSON.stringify(payload)
    });
}

window.addEventListener('message', (event) => {
    if (event.data?.type === 'studio:visibility') {
        setVisible(Boolean(event.data.visible));
    }
});

closeButton.addEventListener('click', () => {
    setVisible(false);
    postNui('studio:close');
});
