# LITTLE SEOUL - the scripts

(c) 2026 Cyborg Unicorn Pty Ltd - MIT License

You are Seoul's newest postie (man or woman: the player's choice, with their own name and face). Every
working day for four weeks (20 days) you leave the **Central Post Office** in Myeongdong with a bag
of letters and parcels and walk them round a little Seoul - real districts where they really are
(Hongdae, Insadong, Bukchon, Gangnam, Jamsil, Yeouido...), real landmarks (Gyeongbokgung, N Seoul
Tower, the Han river and its bridges, the 63 Building, COEX, Namdaemun market...), shops you can go
into, apartment blocks with lifts, a subway. Crazy Taxi on foot: the clock runs from 9:00 to 18:00.

The hundred people of the town (KPOP GROUP MANAGER's people: fictional) live at real addresses
(flats, villas, hanok houses) and walk the streets of their districts. Shopkeepers serve you.
Strangers mostly ignore you.

## The format

```
# a comment
=== SCENE              a scene (its name: the lists below; they must be in this order)
- text                 the narrator (no face)
"text                  the person speaking (a closing " is optional)
@Y @N @B @X            who speaks next: Y you, N them (whoever you're talking to: the person, the
                       shopkeeper), B the boss (the Postmaster), X your colleague (the senior postie)
:mood                  their face: smile open cat o grin smirk; :heart :broken :sparkle :note :star
                       float an icon
? option               a choice (2 or 3 options, at most 2 choices a scene); the lines indented two
                       spaces under it happen if it's picked
+N / -N                (anywhere) how THEY (@N) feel about you: -20 .. 20
$N / $-N               money, in thousands of won ($-5 = pay 5,000 won)
!STAT N                ENERGY (0-100: food), SPEED (minutes of walking fast: coffee), BOSS (what the
                       Postmaster thinks of you), REP (the town's view of you: tips), TIME (minutes
                       that pass: eating takes time), and things the game does after: LOOKUP 1
                       (a PC shows your round's addresses), APP 1 (the map app: an arrow), HAIR 1
                       (a new hairdo), LOOK 1 (new clothes), HANBOK 1 (you wear a hanbok), FLOWERS 1
                       (you've bought flowers), ASK 1 (the police tell you where someone lives)
```

Tokens: `{P}` you, `{N}` them, `{X}` your colleague, `{B}` the boss, `{PLACE}` where you are (the
shop's name, CHEONG CAFE...), `{D}` the district, `{I}` what you're delivering (LETTER or PARCEL),
`{T}` who it's from (MUM, A BANK...), `{H}` someone's address.

Rules:
- Text is printed in capitals; 34 letters a line, 5 lines a page, so keep a line of speech to about
  150 letters. Letters you can use: A-Z 0-9 and ! " # $ % & ' ( ) * + , - . / : ; < = > ? @ [ ] _
  (no accents, no curly quotes, no em dashes - use " - ").
- Fictional people only: no real celebrities, idols, politicians, brands or companies (no
  Starbucks, Samsung, Lotte, Olive Young, GS25...). Real places are good: districts, streets, palaces,
  markets, mountains, the river, subway lines, landmarks, Korean food and customs.
- Short and funny. Korean words in plain romanisation are good (ANNYEONGHASEYO, AIGOO, PALLI PALLI,
  HWAITING, GAMSAHAMNIDA, DAEBAK, OPPA, EONNI, AJUSSHI, AJUMMA, MAKNAE, JJAN!).
- A choice's options are short (under 30 letters).
- Nothing mean about real groups; the jokes are on the job, the city, the weather, the hills, the
  lifts that never come, the cats.
