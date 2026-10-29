from pathlib import Path
from aqt import mw, gui_hooks
from aqt.qt import QTimer, Qt

ROOT = Path(__file__).parent
PAPER_STYLE = '<style>' + (ROOT / 'paper.css').read_text() + '</style>'
close_request = Path('/home/anki/.paper-anki-close')

def configure():
    mw.menuBar().hide()
    mw.setWindowFlag(Qt.WindowType.FramelessWindowHint, True)
    mw.showMaximized()

def simplify(web_content, context):
    web_content.head += PAPER_STYLE

def simplify_card(text, card, kind):
    return text + PAPER_STYLE


def poll_close():
    if close_request.exists():
        close_request.unlink(missing_ok=True)
        mw.close()

from . import notes_reader

gui_hooks.card_will_show.append(simplify_card)
gui_hooks.profile_did_open.append(configure)
gui_hooks.webview_will_set_content.append(simplify)
timer = QTimer(mw)
timer.timeout.connect(poll_close)
timer.start(500)

# Small local health record for diagnosing the tablet integration.
def write_status():
    import json, time
    try:
        data = {'profile': mw.pm.name, 'state': mw.state, 'time': int(time.time())}
        if mw.col and mw.col.db:
            data.update(cards=mw.col.db.scalar('select count(*) from cards'),
                        reviews=mw.col.db.scalar('select count(*) from revlog'),
                        media_sync_active=mw.col.media_sync_status().active)
        Path('/home/anki/paper-anki-status.json').write_text(json.dumps(data))
    except Exception:
        pass

status_timer = QTimer(mw)
status_timer.timeout.connect(write_status)
status_timer.start(5000)
