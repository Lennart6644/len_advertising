const RESOURCE = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'len_advertising';
const root = document.documentElement;
const $ = (id) => document.getElementById(id);

const app = $('app');
const panel = $('panel');
const messageEl = $('message');
const timeEl = $('time');
const importantEl = $('important');
const fxLayer = $('fx');

const STACKS = {
    'top-center': $('stack-top-center'),
    'top-right': $('stack-top-right'),
    'bottom-right': $('stack-bottom-right'),
    'bottom-left': $('stack-bottom-left'),
};

const state = {
    mode: 'private',
    data: null,
    strings: {},
    pricing: { enabled: false },
    minChars: 2,
};

let fxTimer = null;

function post(name, body = {}) {
    fetch(`https://${RESOURCE}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
    }).catch(() => {});
}

function hexToRgb(hex) {
    let h = hex.replace('#', '');
    if (h.length === 3) h = h.split('').map((c) => c + c).join('');
    const v = parseInt(h.padEnd(6, '0').slice(0, 6), 16);
    return `${(v >> 16) & 255}, ${(v >> 8) & 255}, ${v & 255}`;
}

function t(key) {
    return state.strings[key] ?? key;
}

function applyTheme(theme) {
    if (!theme) return;
    root.style.setProperty('--glass-alpha', theme.glassOpacity);
    root.style.setProperty('--radius', `${theme.borderRadius}px`);
    root.style.setProperty('--anim-ms', `${theme.animationSpeed}ms`);
    root.style.setProperty('--font', theme.font);
}

function applyAccent(color) {
    root.style.setProperty('--accent', color);
    root.style.setProperty('--accent-rgb', hexToRgb(color));
}

function buildCard(o) {
    const card = document.createElement('div');
    card.className = `notify-card style-${o.style || 'glass'}`;
    if (o.important) card.classList.add('is-important');
    if (o.effect) card.classList.add('is-admin');
    card.style.setProperty('--c', o.color || '#ffffff');

    const icon = document.createElement('div');
    icon.className = 'notify-icon';
    const i = document.createElement('i');
    i.className = `fas fa-${o.icon || 'bullhorn'}`;
    icon.appendChild(i);

    const body = document.createElement('div');
    body.className = 'notify-body';
    const title = document.createElement('div');
    title.className = 'notify-title';
    title.textContent = o.title || '';
    const text = document.createElement('p');
    text.className = 'notify-text';
    text.textContent = o.message || '';
    body.append(title, text);

    card.append(icon, body);

    if (o.duration) {
        const progress = document.createElement('div');
        progress.className = 'notify-progress';
        const bar = document.createElement('span');
        bar.style.animationDuration = `${o.duration}ms`;
        progress.appendChild(bar);
        card.appendChild(progress);
    }

    return card;
}

function renderPrice() {
    if (state.mode !== 'private' || !state.pricing.enabled) return;
    const p = state.pricing;
    const time = parseInt(timeEl.value, 10);
    let total = p.base + time * p.perSecond;
    if (messageEl.value.trim().length >= p.charThreshold) total += p.charExtra;
    if (importantEl.checked) total += p.vip;
    $('price-value').textContent = `${total}${p.currency}`;
}

function renderPreview() {
    const d = state.data;
    if (!d) return;
    const text = messageEl.value.trim() || t('preview_text');
    const card = buildCard({
        title: d.title,
        message: text,
        icon: d.icon,
        color: state.mode === 'private' && importantEl.checked ? d.vipColor || d.color : d.color,
        style: state.mode === 'job' ? 'sharp' : 'glass',
        important: importantEl.checked,
    });
    $('preview-card').replaceChildren(card);
}

function refreshAll() {
    $('char-count').textContent = messageEl.value.length;
    $('time-value').textContent = timeEl.value;
    const min = parseInt(timeEl.min, 10);
    const max = parseInt(timeEl.max, 10);
    const pct = ((parseInt(timeEl.value, 10) - min) / (max - min)) * 100;
    timeEl.style.setProperty('--pct', `${pct}%`);
    renderPreview();
    renderPrice();
}

function autosize() {
    messageEl.style.height = 'auto';
    messageEl.style.height = `${messageEl.scrollHeight}px`;
}

function openUI(d) {
    state.mode = d.mode;
    state.data = d;
    state.strings = d.strings || {};
    state.pricing = d.pricing || { enabled: false };
    state.minChars = d.minChars || 2;

    applyTheme(d.theme);
    applyAccent(d.color);

    app.className = `mode-${d.mode}`;
    $('panel-icon').className = `fas fa-${d.icon}`;
    $('panel-title').textContent = d.title;

    document.querySelectorAll('[data-i18n]').forEach((el) => {
        el.textContent = t(el.dataset.i18n);
    });

    const isJob = d.mode === 'job';
    $('toggle-title').textContent = t(isJob ? 'important_title' : 'vip_title');
    $('toggle-desc').textContent = t(isJob ? 'important_desc' : 'vip_desc');
    $('toggle-row').classList.toggle('hidden', !d.allowImportant);
    $('price').classList.toggle('hidden', isJob || !state.pricing.enabled);
    messageEl.placeholder = t('message_placeholder');
    messageEl.maxLength = d.maxChars;
    $('char-max').textContent = d.maxChars;

    timeEl.min = d.minTime;
    timeEl.max = d.maxTime;
    timeEl.value = d.defaultTime;
    $('time-min').textContent = `${d.minTime}s`;
    $('time-max').textContent = `${d.maxTime}s`;

    messageEl.value = '';
    importantEl.checked = false;
    autosize();

    app.classList.remove('hidden');
    refreshAll();
}

function hideUI() {
    app.classList.add('hidden');
}

function closeUI() {
    post('close');
    hideUI();
}

function resetForm() {
    messageEl.value = '';
    timeEl.value = state.data ? state.data.defaultTime : timeEl.value;
    importantEl.checked = false;
    autosize();
    refreshAll();
}

function shake() {
    panel.classList.remove('shake');
    void panel.offsetWidth;
    panel.classList.add('shake');
    setTimeout(() => panel.classList.remove('shake'), 500);
}

function submitAd() {
    const message = messageEl.value.trim();
    if (message.length < state.minChars) {
        shake();
        return;
    }
    post('submit', {
        message,
        time: parseInt(timeEl.value, 10),
        important: importantEl.checked,
    });
    hideUI();
}

function pushNotify(d) {
    applyTheme(d.theme);
    const stack = STACKS[d.position] || STACKS['bottom-right'];
    const card = buildCard({
        title: d.title,
        message: d.message,
        icon: d.icon,
        color: d.color,
        style: d.style,
        important: d.important,
        effect: d.effect,
        duration: d.duration,
    });

    stack.appendChild(card);

    const maxVisible = d.maxVisible || 4;
    while (stack.children.length > maxVisible) {
        stack.firstElementChild.remove();
    }

    const fade = d.fadeOut || 400;
    setTimeout(() => {
        card.classList.add('leaving');
        setTimeout(() => card.remove(), fade);
    }, d.duration);
}

function startFx(d) {
    root.style.setProperty('--fx-rgb', hexToRgb(d.color));
    root.style.setProperty('--fx-strength', d.strength);
    fxLayer.classList.add('active');
    clearTimeout(fxTimer);
    fxTimer = setTimeout(() => fxLayer.classList.remove('active'), d.duration);
}

messageEl.addEventListener('input', () => {
    autosize();
    refreshAll();
});

timeEl.addEventListener('input', refreshAll);
importantEl.addEventListener('change', refreshAll);
$('btn-close').addEventListener('click', closeUI);
$('btn-reset').addEventListener('click', resetForm);
$('btn-submit').addEventListener('click', submitAd);

document.addEventListener('keyup', (e) => {
    if (e.key === 'Escape' && !app.classList.contains('hidden')) closeUI();
});

window.addEventListener('message', (e) => {
    const msg = e.data;
    if (!msg || !msg.action) return;
    if (msg.action === 'open') openUI(msg.data);
    if (msg.action === 'notify') pushNotify(msg.data);
    if (msg.action === 'adminFx') startFx(msg.data);
});
