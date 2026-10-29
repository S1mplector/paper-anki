"""Read suspended ::Notes decks without changing cards or annotations."""
import html
import json
from pathlib import Path

from aqt import mw
from aqt.overview import Overview, OverviewBottomBar

ROOT = Path(__file__).parent


def is_notes():
    return bool(mw.col and mw.col.decks.current()['name'].endswith('::Notes'))


def json_script(value):
    return json.dumps(value, ensure_ascii=False).replace('<', '\\u003c')


def reader_html():
    deck = mw.col.decks.current()['name']
    notes = [mw.col.get_note(nid) for nid in mw.col.find_notes('deck:' + json.dumps(deck))]
    notes = sorted((note for note in notes if 'Title' in note and 'Body' in note),
                   key=lambda note: note['Title'])
    pages = []
    for note in notes:
        def field(name):
            return note[name] if name in note else ''
        # Match the desktop article's text order, so saved highlight offsets remain valid.
        article = ('<article class="reading"><div class="meta">'
                   + html.escape(field('Course') + ' · ' + field('Lecture'))
                   + '</div><h1>' + html.escape(note['Title']) + '</h1>'
                   + note['Body'] + field('Visuals')
                   + '<div class="source">' + field('Source') + '</div></article>')
        annotations = mw.col.get_config('study_annotations_' + note.guid, [])
        pages.append({'title': note['Title'], 'html': article,
                      'annotations': annotations if isinstance(annotations, list) else []})
    body = '''<nav class="reader-nav" aria-label="Notes pages">
<button id="previous" aria-label="Previous note">←</button>
<span id="counter" aria-live="polite"></span>
<button id="next" aria-label="Next note">→</button>
<select id="contents" aria-label="Choose note"></select></nav>
<main id="reader"></main>
<aside id="annotations" aria-label="Saved annotations"></aside>
<dialog id="image-zoom"><button id="close-zoom" aria-label="Close illustration">×</button><img alt=""></dialog>'''
    body += '<script>const pages=' + json_script(pages) + ';' + (ROOT / 'notes_reader.js').read_text() + '</script>'
    head = '<base href="' + html.escape(mw.serverURL(), quote=True) + '"><style>' + (ROOT / 'notes_reader.css').read_text() + '</style>'
    return body, head


original_page = Overview._renderPage
original_bottom = Overview._renderBottom


def render_page(self):
    if not is_notes():
        return original_page(self)
    body, head = reader_html()
    self.mw.web.stdHtml(body, head=head, context=self)


def render_bottom(self):
    if not is_notes():
        return original_bottom(self)
    self.bottom.draw(buf='', link_handler=self._linkHandler, web_context=OverviewBottomBar(self))


Overview._renderPage = render_page
Overview._renderBottom = render_bottom
