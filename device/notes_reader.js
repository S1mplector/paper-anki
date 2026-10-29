// No collection writes or grading: this reader only displays synced content.
let position = 0;
const reader = document.getElementById('reader');
const annotations = document.getElementById('annotations');
const contents = document.getElementById('contents');
const zoom = document.getElementById('image-zoom');
pages.forEach((page, i) => contents.add(new Option(page.title, String(i))));

function highlight(entry, index) {
    const root = reader.querySelector('.reading');
    if (!root || !Number.isInteger(entry.start) || !Number.isInteger(entry.end) ||
        entry.start < 0 || entry.end <= entry.start ||
        root.textContent.slice(entry.start, entry.end) !== entry.quote) return;
    const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
    const nodes = [];
    while (walker.nextNode()) nodes.push(walker.currentNode);
    let offset = 0;
    for (const node of nodes) {
        const end = offset + node.length;
        if (end > entry.start && offset < entry.end) {
            const range = document.createRange();
            range.setStart(node, Math.max(0, entry.start - offset));
            range.setEnd(node, Math.min(node.length, entry.end - offset));
            const mark = document.createElement('mark');
            mark.tabIndex = 0;
            mark.setAttribute('role', 'button');
            mark.setAttribute('aria-label', 'Read saved annotation');
            mark.dataset.annotation = String(index);
            range.surroundContents(mark);
        }
        offset = end;
    }
}
function show(i) {
    position = Math.max(0, Math.min(pages.length - 1, i));
    const page = pages[position];
    reader.innerHTML = page?.html || '<article class="reading">No notes in this deck yet.</article>';
    document.getElementById('counter').textContent = pages.length ? `${position + 1} / ${pages.length}` : '0 / 0';
    document.getElementById('previous').disabled = position <= 0;
    document.getElementById('next').disabled = position >= pages.length - 1;
    contents.value = String(position);
    annotations.replaceChildren();
    const entries = (page?.annotations || []).filter(entry => entry && typeof entry === 'object');
    annotations.hidden = !entries.length;
    if (entries.length) {
        const heading = document.createElement('h2');
        heading.textContent = 'Saved annotations';
        annotations.appendChild(heading);
    }
    entries.forEach((entry, index) => {
        const section = document.createElement('section');
        section.id = `annotation-${index}`;
        const quote = document.createElement('blockquote');
        quote.textContent = typeof entry.quote === 'string' ? entry.quote : '';
        const text = document.createElement('p');
        text.textContent = typeof entry.text === 'string' ? entry.text : '';
        section.append(quote, text);
        annotations.appendChild(section);
        highlight(entry, index);
    });
    window.scrollTo(0, 0);
}
function step(direction) { show(position + direction); }
document.getElementById('previous').onclick = () => step(-1);
document.getElementById('next').onclick = () => step(1);
contents.onchange = () => show(Number(contents.value));
reader.addEventListener('click', event => {
    const mark = event.target.closest('mark[data-annotation]');
    if (mark) {
        document.getElementById(`annotation-${mark.dataset.annotation}`)?.scrollIntoView({block: 'center'});
    } else if (event.target.tagName === 'IMG') {
        const image = zoom.querySelector('img');
        image.src = event.target.src;
        image.alt = event.target.alt;
        zoom.showModal();
    }
});
reader.addEventListener('keydown', event => {
    if (event.target.matches('mark[data-annotation]') && ['Enter', ' '].includes(event.key)) {
        event.preventDefault(); event.stopPropagation(); event.target.click();
    }
});
document.getElementById('close-zoom').onclick = () => zoom.close();
zoom.onclick = event => { if (event.target === zoom || event.target.tagName === 'IMG') zoom.close(); };
document.addEventListener('keydown', event => {
    if (zoom.open || event.target.isContentEditable ||
        ['SELECT', 'INPUT', 'TEXTAREA', 'BUTTON', 'MARK'].includes(event.target.tagName)) return;
    if (event.key === 'ArrowRight' || event.key === ' ') { event.preventDefault(); step(1); }
    if (event.key === 'ArrowLeft') { event.preventDefault(); step(-1); }
});
show(0);
