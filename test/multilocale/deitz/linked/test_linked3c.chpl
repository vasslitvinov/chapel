var cs: [0..numLocales-1] domain(1);

forall loc in Locales do
    cs[loc.id] = {0..loc.id};

writeln(cs);
