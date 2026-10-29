#include <QGuiApplication>
#include <QQuickView>
#include <QQmlError>
#include <QResource>
#include <QTimer>
#include <QDebug>
int main(int argc,char **argv) {
    if(argc!=3)return 2;
    qputenv("PAPER_ANKI_PREVIEW","1");
    QGuiApplication app(argc,argv);
    if(!QResource::registerResource(argv[1],"/probe"))return 3;
    QQuickView view;
    view.setResizeMode(QQuickView::SizeRootObjectToView);
    view.resize(1404,1872);
    view.setSource(QUrl("qrc:/probe/paperanki/AppLoad.qml"));
    if(view.status()==QQuickView::Error){for(const auto &e:view.errors())qWarning()<<e;return 4;}
    view.show();
    QTimer::singleShot(1800,&app,[&]{bool ok=view.grabWindow().save(argv[2]);app.exit(ok?0:5);});
    return app.exec();
}
