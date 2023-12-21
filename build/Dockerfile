FROM containers.intersystems.com/intersystems/iris-community:2023.1

USER root

# Japanese language pack (optional)
RUN apt -y update && DEBIAN_FRONTEND=noninteractive apt -y install language-pack-ja-base language-pack-ja

USER $ISC_PACKAGE_IRISUSER

RUN echo 'export LANG=ja_JP.UTF-8' >> ~/.bashrc && echo 'export LANGUAGE="ja_JP:ja"' >> ~/.bashrc 
RUN pip install pandas matplotlib

ARG COMMIT_ID="unknown"

ENV SRCDIR=src
ENV SQLDIR=sql

COPY --chown=$ISC_PACKAGE_IRISUSER:$ISC_PACKAGE_IRISGROUP src/ $SRCDIR/
COPY --chown=$ISC_PACKAGE_IRISUSER:$ISC_PACKAGE_IRISGROUP sql/ $SQLDIR/

RUN  iris start $ISC_PACKAGE_INSTANCENAME \ 
 && printf 'Do ##class(Config.NLS.Locales).Install("jpuw") h\n' | iris session $ISC_PACKAGE_INSTANCENAME -U %SYS \
 && printf 'Set tSC=$system.OBJ.Load("'$HOME/$SRCDIR'/MyApps/Installer.cls","ck") Do:+tSC=0 $SYSTEM.Process.Terminate($JOB,1) h\n' | iris session $ISC_PACKAGE_INSTANCENAME \
 && printf 'Set tSC=##class(MyApps.Installer).setup() Do:+tSC=0 $SYSTEM.Process.Terminate($JOB,1) h\n' | iris session $ISC_PACKAGE_INSTANCENAME \
 && iris stop $ISC_PACKAGE_INSTANCENAME quietly

RUN iris start $ISC_PACKAGE_INSTANCENAME nostu quietly \
 && printf "kill ^%%SYS(\"JOURNAL\") kill ^SYS(\"NODE\") h\n" | iris session $ISC_PACKAGE_INSTANCENAME -B | cat \
 && iris stop $ISC_PACKAGE_INSTANCENAME quietly bypass \
 && rm -f $ISC_PACKAGE_INSTALLDIR/mgr/journal.log \
 && rm -f $ISC_PACKAGE_INSTALLDIR/mgr/IRIS.WIJ \
 && rm -f $ISC_PACKAGE_INSTALLDIR/mgr/iris.ids \
 && rm -f $ISC_PACKAGE_INSTALLDIR/mgr/alerts.log \
 && rm -f $ISC_PACKAGE_INSTALLDIR/mgr/journal/* \
 && rm -f $ISC_PACKAGE_INSTALLDIR/mgr/messages.log \
 && touch $ISC_PACKAGE_INSTALLDIR/mgr/messages.log \
 && rm -rf $SRCDIR \
 && echo $COMMIT_ID > $HOME/commit.txt
