{"version":5,"vars":[{"containerName":"","line":7,"name":"warnings","kind":2},{"kind":2,"containerName":"","name":"strict","line":7},{"name":"Socket","line":8,"containerName":"IO","kind":2},{"kind":14,"line":10,"definition":1,"name":"VERSION","containerName":"main::"},{"kind":12,"children":[{"kind":13,"localvar":"my","name":"$class","containerName":"client","line":12,"definition":"my"},{"kind":13,"name":"$config","line":12,"containerName":"client"},{"containerName":"client","name":"%self","line":12,"kind":13},{"name":"$config","line":13,"containerName":"client","kind":13},{"containerName":"client","line":13,"name":"$config","kind":13},{"containerName":"client","line":14,"name":"$self","kind":13},{"kind":12,"line":14,"name":"new","containerName":"client"},{"containerName":"client","line":18,"name":"$config","kind":13},{"containerName":"client","line":23,"name":"$self","kind":13},{"name":"new","line":23,"containerName":"client","kind":12},{"kind":13,"containerName":"client","line":23,"name":"$self"}],"signature":{"label":"client($class,$config,%self)","parameters":[{"label":"$class"},{"label":"$config"},{"label":"%self"}],"documentation":""},"range":{"start":{"character":0,"line":12},"end":{"character":9999,"line":23}},"name":"client","containerName":"main::","detail":"($class,$config,%self)","definition":"sub","line":12},{"name":"CNFParser","line":14,"kind":12},{"kind":12,"name":"Domain","line":18},{"kind":12,"line":18,"name":"AF_INET"},{"line":18,"name":"Type","kind":12},{"name":"SOCK_STREAM","line":18,"kind":12},{"kind":12,"name":"Proto","line":18},{"kind":12,"containerName":"Socket","line":23,"name":"IO"},{"kind":13,"line":25,"name":"%self","containerName":null},{"line":25,"name":"$class","containerName":null,"kind":13},{"kind":13,"name":"%self","line":26,"containerName":null},{"name":"server","range":{"end":{"character":9999,"line":32},"start":{"line":29,"character":0}},"signature":{"documentation":"","parameters":[{"label":"$class"},{"label":"$config"},{"label":"%self"}],"label":"server($class,$config,%self)"},"kind":12,"children":[{"kind":13,"localvar":"my","name":"$class","containerName":"server","line":29,"definition":"my"},{"line":29,"name":"$config","containerName":"server","kind":13},{"containerName":"server","name":"%self","line":29,"kind":13},{"name":"$config","line":30,"containerName":"server","kind":13},{"name":"$config","line":30,"containerName":"server","kind":13},{"containerName":"server","line":31,"name":"$self","kind":13},{"line":31,"name":"new","containerName":"server","kind":12},{"name":"$config","line":31,"containerName":"server","kind":13},{"kind":13,"containerName":"server","name":"$self","line":32},{"kind":12,"line":32,"name":"new","containerName":"server"},{"containerName":"server","line":32,"name":"$self","kind":13}],"line":29,"definition":"sub","detail":"($class,$config,%self)","containerName":"main::"},{"kind":12,"line":31,"name":"CNFParser"},{"name":"Domain","line":31,"kind":12},{"name":"AF_INET","line":31,"kind":12},{"line":31,"name":"Type","kind":12},{"kind":12,"line":31,"name":"SOCK_STREAM"},{"kind":12,"name":"Proto","line":31},{"kind":12,"line":32,"name":"IO","containerName":"Socket"},{"line":34,"name":"%self","containerName":null,"kind":13},{"kind":13,"name":"$class","line":34,"containerName":null},{"kind":13,"containerName":null,"name":"%self","line":35},{"kind":12,"children":[{"name":"dumpENV","line":39,"containerName":"configDumpENV","kind":12}],"range":{"start":{"line":38,"character":0},"end":{"line":40,"character":9999}},"name":"configDumpENV","containerName":"main::","line":38,"definition":"sub"},{"line":39,"name":"parser","kind":12},{"detail":"($sip,$srange)","definition":"sub","line":43,"containerName":"main::","children":[{"name":"$sip","localvar":"my","kind":13,"definition":"my","line":44,"containerName":"checkIPrange"},{"kind":13,"line":44,"name":"$srange","containerName":"checkIPrange"},{"containerName":"checkIPrange","definition":"my","line":45,"name":"@ip","kind":13,"localvar":"my"},{"containerName":"checkIPrange","line":45,"name":"$sip","kind":13},{"definition":"my","line":46,"containerName":"checkIPrange","localvar":"my","kind":13,"name":"@range"},{"kind":13,"name":"$srange","line":46,"containerName":"checkIPrange"},{"kind":13,"containerName":"checkIPrange","line":47,"name":"@ip"},{"kind":13,"containerName":"checkIPrange","line":47,"name":"@range"},{"name":"$i","localvar":"my","kind":13,"definition":"my","line":48,"containerName":"checkIPrange"},{"line":48,"name":"$i","containerName":"checkIPrange","kind":13},{"line":48,"name":"@ip","containerName":"checkIPrange","kind":13},{"kind":13,"containerName":"checkIPrange","name":"$i","line":48},{"kind":13,"line":49,"name":"$range","containerName":"checkIPrange"},{"containerName":"checkIPrange","name":"$i","line":49,"kind":13},{"name":"$n","kind":13,"localvar":"my","containerName":"checkIPrange","definition":"my","line":50},{"containerName":"checkIPrange","name":"$range","line":50,"kind":13},{"kind":13,"name":"$i","line":50,"containerName":"checkIPrange"},{"kind":13,"name":"$n","line":51,"containerName":"checkIPrange"},{"kind":13,"name":"$n","line":51,"containerName":"checkIPrange"},{"kind":13,"containerName":"checkIPrange","name":"$n","line":52},{"kind":13,"name":"$ip","line":52,"containerName":"checkIPrange"},{"containerName":"checkIPrange","name":"$i","line":52,"kind":13}],"kind":12,"name":"checkIPrange","signature":{"label":"checkIPrange($sip,$srange)","parameters":[{"label":"$sip"},{"label":"$srange"}],"documentation":""},"range":{"start":{"character":0,"line":43},"end":{"line":59,"character":9999}}},{"detail":"($self,@col)","definition":"sub","line":61,"containerName":"main::","name":"loadConfigs","signature":{"label":"loadConfigs($self,@col)","parameters":[{"label":"$self"},{"label":"@col"}],"documentation":""},"range":{"end":{"line":85,"character":9999},"start":{"line":61,"character":0}},"kind":12,"children":[{"line":61,"definition":"my","containerName":"loadConfigs","name":"$self","localvar":"my","kind":13},{"containerName":"loadConfigs","name":"@col","line":61,"kind":13},{"definition":"my","line":62,"containerName":"loadConfigs","name":"%configs","localvar":"my","kind":13},{"name":"$cnf","kind":13,"localvar":"my","containerName":"loadConfigs","definition":"my","line":63},{"kind":13,"name":"$self","line":63,"containerName":"loadConfigs"},{"name":"$c","kind":13,"localvar":"my","containerName":"loadConfigs","definition":"my","line":64},{"containerName":"loadConfigs","line":64,"name":"$cnf","kind":13},{"kind":12,"containerName":"loadConfigs","name":"collection","line":64},{"kind":13,"line":65,"name":"$c","containerName":"loadConfigs"},{"kind":13,"name":"@col","line":66,"containerName":"loadConfigs"},{"kind":13,"containerName":"loadConfigs","line":66,"name":"$c"},{"name":"$self","line":67,"containerName":"loadConfigs","kind":13},{"line":67,"name":"%configs","containerName":"loadConfigs","kind":13},{"name":"$file","kind":13,"localvar":"my","containerName":"loadConfigs","line":68,"definition":"my"},{"kind":13,"name":"@col","line":68,"containerName":"loadConfigs"},{"kind":13,"localvar":"my","name":"$path","containerName":"loadConfigs","definition":"my","line":69},{"name":"$path","line":71,"containerName":"loadConfigs","kind":13},{"line":72,"name":"$configs","containerName":"loadConfigs","kind":13},{"name":"$file","line":72,"containerName":"loadConfigs","kind":13},{"kind":13,"containerName":"loadConfigs","name":"$configs","line":74},{"kind":13,"name":"$file","line":74,"containerName":"loadConfigs"},{"containerName":"loadConfigs","name":"new","line":74,"kind":12},{"name":"$path","line":74,"containerName":"loadConfigs","kind":13},{"kind":13,"localvar":"my","name":"$CNF_PATH","containerName":"loadConfigs","line":82,"definition":"my"},{"containerName":"loadConfigs","name":"$cnf","line":82,"kind":13}]},{"kind":12,"name":"CNFParser","line":74}]}