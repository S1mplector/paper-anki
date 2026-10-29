"""Run with Anki's bundled Python while Anki is CLOSED. Uses Hardware Test only."""
from pathlib import Path
from anki.collection import Collection

profile = Path('/home/anki/Anki/Hardware Test')
profile.mkdir(parents=True, exist_ok=True)
col = Collection(str(profile / 'collection.anki2'))
try:
    if col.find_notes('tag:paper_anki_fixture'):
        print('Fixture already exists; scheduling is preserved.')
    else:
        basic = col.models.new('Paper Anki QA Basic')
        for name in ('Front', 'Back'):
            col.models.add_field(basic, col.models.new_field(name))
        template = col.models.new_template('Card')
        template['qfmt'] = '<div class="study"><div class="question">{{Front}}</div></div>'
        template['afmt'] = '<div class="study"><div class="answer">{{Back}}</div></div>'
        col.models.add_template(basic, template)
        basic['css'] = '''html{background:#222 url("missing-wallpaper.jpg") center/cover}
.card{font:24px/1.5 Arial;color:white;background:#222}
.study{background:#222;color:white;padding:25px;border-radius:25px;box-shadow:0 8px 30px black}'''
        col.models.add(basic)
        did = col.decks.id('Paper Anki QA · Test')
        for front, back in [('What runs on this tablet?', 'The full Anki desktop app.'),
                            ('What is 2 + 2?', '4')]:
            note = col.new_note(basic)
            note['Front'], note['Back'] = front, back
            note.tags = ['paper_anki_fixture']
            col.add_note(note, did)
        model = col.models.new('Paper Anki QA Notes')
        for name in ('Title', 'Body', 'Course', 'Lecture', 'Visuals', 'Source'):
            col.models.add_field(model, col.models.new_field(name))
        template = col.models.new_template('Reading')
        template['qfmt'], template['afmt'] = '{{Title}}', '{{Body}}'
        col.models.add_template(model, template)
        col.models.add(model)
        did = col.decks.id('Paper Anki QA::Notes')
        for index in range(2):
            note = col.new_note(model)
            note['Title'] = f'{index + 1}. Reading on paper'
            note['Body'] = '<p>Notes are for reading. They do not need to be graded.</p><h2>Keep the useful details</h2><p>Illustrations and saved annotations stay with your notes.</p>'
            note['Course'], note['Lecture'] = 'Example course', 'Example chapter'
            note['Visuals'] = '<figure><svg viewBox="0 0 600 180" xmlns="http://www.w3.org/2000/svg"><rect x="20" y="30" width="180" height="100" rx="14" fill="#eee" stroke="#333"/><path d="M210 80H380m-20-15 20 15-20 15" fill="none" stroke="#333" stroke-width="4"/><rect x="390" y="30" width="180" height="100" rx="14" fill="#eee" stroke="#333"/><text x="110" y="90" text-anchor="middle" font-size="24">Read</text><text x="480" y="90" text-anchor="middle" font-size="24">Understand</text></svg><figcaption>A simple reading workflow.</figcaption></figure>'
            note['Source'] = 'Synthetic example for integration testing.'
            note.tags = ['paper_anki_fixture']
            col.add_note(note, did)
            col.sched.suspend_cards(col.find_cards('nid:' + str(note.id)))
            prefix = note['Course'] + ' · ' + note['Lecture'] + note['Title']
            quote = 'Notes are for reading.'
            col.set_config('study_annotations_' + note.guid, [{'id':'example', 'start':len(prefix), 'end':len(prefix)+len(quote), 'quote':quote, 'text':'This annotation was saved on another device.'}])
        print('Created synthetic cards and suspended Notes. No sync credentials are added.')
finally:
    col.close()
