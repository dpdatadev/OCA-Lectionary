4-8-2026
Time to transition to beta and polish this up as a useful project that I'm proud of. Removing the Go servers.
That was just kinda fun to learn how to interact with them I guess. This needs to be in one language. Nokogiri and SQLITE is fast enough.
I'd also like a CLI option and the ability to import it into a Rails app (possibly).

4-8-2026
This was fun to write and the go servers have their use, but to release this for others to use, why introduce another program to run and network IO is slower
than local SQLITE queries - way slower. SQLITE is the way to go for the Lectionary project. I'll get Biblebot to work or improve the Verse parser in Ruby.
It works alright as it is anyway.

4-8-2026
If we aren't using the GoBible server to actually parse the references fed, then whats the point? We are still relying on Ruby to provide the reference,
then at that point we just continue using the local KJV database to quickly give the data, if this is ever expected to be used by others it must be fully contained
in Ruby, we can't provide two executables to run alongside. Not really a good idea the more I think about it. Though, those two servers have uses on their own (for me).

4-2-2026
We now have the "verseserve" executable which runs a GoBible service for parsing verses.
So the BibleBot ruby gem or hacky workarounds are no longer a concern.
todo, behavior seems different once the verseserve executable is deployed compared to running in local mode,
has a potential issue running the data/KJV.json file, so verseserve may need to be ran from it's own cloned 
directory.

3-30-2026
I can't get the Biblebot parse engine in Ruby to work right
But the GoBible module works very well and we're already querying a Go server..
I could offload even more to HTTParty web requests (or just keep the whole thing in Go) 
...it would certainly make handling multiple verses easier.