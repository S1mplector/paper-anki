#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickPaintedItem>
#include <QTcpSocket>
#include <QTimer>
#include <QPainter>
#include <QMouseEvent>
#include <QtEndian>
#include <QRegion>
#include <QProcess>
#include <QQmlExtensionPlugin>

class Desktop : public QQuickPaintedItem {
    Q_OBJECT
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)
public:
    explicit Desktop(QQuickItem *parent=nullptr) : QQuickPaintedItem(parent) {
        setAcceptedMouseButtons(Qt::LeftButton);
        setAntialiasing(false);
        connect(&socket, &QTcpSocket::readyRead, this, [this]{ buffer += socket.readAll(); parse(); });
        connect(&socket, &QTcpSocket::errorOccurred, this, [this]{ if(!closing) { setStatus("Opening Anki…"); retryTimer.start(1000); } });
        connect(&socket, &QTcpSocket::disconnected, this, [this]{ state=0; waiting=false; rects=-1; remaining=0; buffer.clear(); if(!closing) { setStatus("Anki is closed. Tap Refresh to reopen, or Exit."); retryTimer.start(1000); } });
        retryTimer.setSingleShot(true);
        connect(&retryTimer, &QTimer::timeout, this, [this]{ if(!closing && socket.state()==QAbstractSocket::UnconnectedState) socket.connectToHost("127.0.0.1",5907); });
        connect(&requestTimer, &QTimer::timeout, this, [this]{ requestFrame(true); });
        requestTimer.setSingleShot(true);
        QTimer::singleShot(0, this, [this]{ socket.connectToHost("127.0.0.1", 5907); });
    }
    ~Desktop() override { closeDesktop(); }
    Q_INVOKABLE void startDesktop() {
        if(qEnvironmentVariableIsSet("PAPER_ANKI_PREVIEW"))return;
        closing=false;
        QProcess::startDetached("/home/root/anki-desktop/start-runtime.sh", {});
        retryTimer.start(500);
    }
    Q_INVOKABLE void closeDesktop() {
        if(qEnvironmentVariableIsSet("PAPER_ANKI_PREVIEW"))return;
#ifdef PAPER_ANKI_PLUGIN
        if(closing)return;
        closing=true; retryTimer.stop(); requestTimer.stop();
        QProcess::startDetached("/home/root/anki-desktop/close-runtime.sh", {});
#endif
    }
    QString status() const { return message; }
    void paint(QPainter *p) override {
        p->fillRect(boundingRect(), Qt::white);
        if (!frame.isNull()) p->drawImage(boundingRect(), frame);
    }
    Q_INVOKABLE void key(int sym) { keyEvent(sym,true); keyEvent(sym,false); }
    Q_INVOKABLE void text(const QString &text) {
        for (auto c : text.toUcs4()) key(c <= 255 ? c : (0x01000000 | c));
    }
    Q_INVOKABLE void refresh() { if(socket.state()!=QAbstractSocket::ConnectedState) startDesktop(); else requestFrame(false); update(); }
    Q_INVOKABLE void scroll(int direction) {
        pointer(lastX,lastY,direction>0 ? 8 : 16); pointer(lastX,lastY,0);
    }
    Q_INVOKABLE void screenshot() { if (!frame.isNull()) frame.save("/home/root/anki-desktop/logs/desktop.png"); }
signals:
    void statusChanged();
protected:
    void mousePressEvent(QMouseEvent *e) override { mouse(e,1); }
    void mouseMoveEvent(QMouseEvent *e) override { mouse(e,e->buttons().testFlag(Qt::LeftButton)?1:0); }
    void mouseReleaseEvent(QMouseEvent *e) override { mouse(e,0); }
private:
    QTcpSocket socket;
    QTimer requestTimer, retryTimer;
    QRegion dirty;
    bool closing=false;
    QByteArray buffer;
    QImage frame;
    QString message="Connecting to Anki…";
    int state=0, rects=-1, rx=0,ry=0,rw=0,rh=0,remaining=0,lastX=0,lastY=0;
    bool waiting=false;
    quint16 u16(int off) { return qFromBigEndian<quint16>(reinterpret_cast<const uchar*>(buffer.constData()+off)); }
    quint32 u32(int off) { return qFromBigEndian<quint32>(reinterpret_cast<const uchar*>(buffer.constData()+off)); }
    void setStatus(QString s) { message=s; emit statusChanged(); }
    void fail(const QString &s) { setStatus(s); socket.abort(); state=-1; }
    static void add16(QByteArray &b, quint16 n) { b.append(char(n>>8));b.append(char(n)); }
    static void add32(QByteArray &b, quint32 n) { for(int shift=24;shift>=0;shift-=8)b.append(char(n>>shift)); }
    void keyEvent(quint32 sym,bool down) {
        if(state!=5)return;
        QByteArray b; b.append(char(4));b.append(char(down));add16(b,0);add32(b,sym);socket.write(b);
    }
    void pointer(int x,int y,int buttons) {
        if(state!=5)return;
        QByteArray b;b.append(char(5));b.append(char(buttons));add16(b,x);add16(b,y);socket.write(b);
    }
    void mouse(QMouseEvent *e,int buttons) {
        if(frame.isNull())return;
        lastX=qBound(0,int(e->position().x()*frame.width()/width()),frame.width()-1);
        lastY=qBound(0,int(e->position().y()*frame.height()/height()),frame.height()-1);
        pointer(lastX,lastY,buttons); e->accept();
    }
    void requestFrame(bool incremental) {
        if(state!=5 || waiting || frame.isNull())return;
        QByteArray b;b.append(char(3));b.append(char(incremental));add16(b,0);add16(b,0);add16(b,frame.width());add16(b,frame.height());socket.write(b);waiting=true;
    }
    void finishFrame() {
        rects=-1; waiting=false;
        if(!dirty.isEmpty()) {
            QRect r=dirty.boundingRect();
            update(QRect(int(r.x()*width()/frame.width()),int(r.y()*height()/frame.height()),int(r.width()*width()/frame.width())+2,int(r.height()*height()/frame.height())+2));
            dirty=QRegion();
        }
        if(qEnvironmentVariableIsSet("PAPER_ANKI_CAPTURE")) frame.save("/home/root/anki-desktop/logs/desktop.png"); requestTimer.start(50);
    }
    void parse() {
        for (;;) {
            if(state==0) {
                if(buffer.size()<12)return;
                if(!buffer.startsWith("RFB 003.")){fail("Invalid desktop protocol");return;}
                buffer.remove(0,12);socket.write("RFB 003.008\n",12);state=1;
            } else if(state==1) {
                if(buffer.isEmpty())return;
                int n=quint8(buffer[0]);if(!n){fail("Desktop rejected connection");return;}
                if(buffer.size()<n+1)return;
                if(!buffer.mid(1,n).contains(char(1))){fail("Local desktop authentication mismatch");return;}
                buffer.remove(0,n+1);socket.write(QByteArray(1,char(1)));state=2;
            } else if(state==2) {
                if(buffer.size()<4)return;
                if(u32(0)!=0){fail("Desktop authentication failed");return;}
                buffer.remove(0,4);socket.write(QByteArray(1,char(1)));state=3;
            } else if(state==3) {
                if(buffer.size()<24)return;
                auto nameLength=u32(20);if(nameLength>65536){fail("Invalid desktop header");return;}
                if(buffer.size()<24+int(nameLength))return;
                int w=u16(0),h=u16(2); if(w<1||h<1||w>4096||h>4096){fail("Unsupported desktop size");return;}
                frame=QImage(w,h,QImage::Format_RGB32);frame.fill(Qt::white);
                buffer.remove(0,24+nameLength);
                QByteArray pf(4,char(0));pf.append(char(32));pf.append(char(24));pf.append(char(0));pf.append(char(1));
                add16(pf,255);add16(pf,255);add16(pf,255);pf.append(char(16));pf.append(char(8));pf.append(char(0));pf.append(QByteArray(3,char(0)));socket.write(pf);
                QByteArray enc;enc.append(char(2));enc.append(char(0));add16(enc,1);add32(enc,0);socket.write(enc);
                state=5;setStatus("");requestFrame(false);
            } else if(state==5) {
                if(remaining) {
                    if(buffer.size()<remaining)return;
                    for(int y=0;y<rh;y++) memcpy(frame.scanLine(ry+y)+rx*4,buffer.constData()+y*rw*4,rw*4);
                    dirty+=QRect(rx,ry,rw,rh);
                    buffer.remove(0,remaining);remaining=0;
                    if(--rects==0) finishFrame();
                } else if(rects>0) {
                    if(buffer.size()<12)return;
                    rx=u16(0);ry=u16(2);rw=u16(4);rh=u16(6);qint32 enc=qint32(u32(8));
                    if(enc!=0||rw<=0||rh<=0||rx+rw>frame.width()||ry+rh>frame.height()){fail("Unsupported desktop update");return;}
                    buffer.remove(0,12);remaining=rw*rh*4;
                } else {
                    if(buffer.isEmpty())return;
                    int type=quint8(buffer[0]);
                    if(type==0) {
                        if(buffer.size()<4)return;
                        rects=u16(2);buffer.remove(0,4);if(!rects)finishFrame();
                    } else if(type==2) buffer.remove(0,1);
                    else if(type==3) {
                        if(buffer.size()<8)return;
                        auto len=u32(4);if(len>1048576){fail("Clipboard too large");return;}
                        if(buffer.size()<8+int(len))return;buffer.remove(0,8+len);
                    } else {fail("Unsupported desktop message");return;}
                }
            } else return;
        }
    }
};
class PaperAnkiPlugin : public QQmlExtensionPlugin {
    Q_OBJECT
    Q_PLUGIN_METADATA(IID QQmlExtensionInterface_iid)
public:
    void registerTypes(const char *uri) override { qmlRegisterType<Desktop>(uri,1,0,"Desktop"); }
};
#include "desktop.moc"
