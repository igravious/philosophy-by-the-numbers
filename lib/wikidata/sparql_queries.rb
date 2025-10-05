# frozen_string_literal: true

module Wikidata
  module SparqlQueries
    ###
    #
    # SPARQLy
    #
    ###

    # Optimized philosopher query with sitelink counting
    THESE_PHILOSOPHERS = "
    PREFIX wd: <http://www.wikidata.org/entity/>
    PREFIX wdt: <http://www.wikidata.org/prop/direct/>
    PREFIX wikibase: <http://wikiba.se/ontology#>
    PREFIX p: <http://www.wikidata.org/prop/>
    PREFIX ps: <http://www.wikidata.org/prop/statement/>
    PREFIX pq: <http://www.wikidata.org/prop/qualifier/>
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX bd: <http://www.bigdata.com/rdf#>
    PREFIX schema: <http://schema.org/>

    SELECT ?entity ?entityLabel ?linkcount WHERE {
      {
        SELECT ?entity (COUNT(DISTINCT ?sitelink) AS ?linkcount) WHERE {
          ?entity wdt:P31 wd:Q5 .
          {{?entity p:P106 ?l0 . ?l0 ps:P106 wd:Q4964182 .} UNION {?entity p:P101 ?l0 . ?l0 ps:P101 wd:Q4964182 .} UNION {?entity p:P39 ?l0 . ?l0 ps:P39 wd:Q4964182 .}}
          OPTIONAL {
            ?sitelink schema:about ?entity .
          }
        }
        GROUP BY ?entity
      }
      SERVICE wikibase:label {
        bd:serviceParam wikibase:language 'en, nl, fr, de, es, it, sv, da, ru, ca, ja, hu, pl, fi, cs, zh, fa, sk, uk, ar, he, et, sl, bg, el, hr, la, hy, zh-cn, sr, az, lv, krc' .
      }
    }
    ORDER BY DESC(?linkcount)
    LIMIT 10000
    ".freeze

    # bd:serviceParam wikibase:language 'en','nl','fr','de','es','it','sv','nb','da','nn','ru','ca','ja','hu','pl','pt','fi','cs','zh','fa','sk','eo','uk','ar','tr','ro','he','et','eu','sl','oc','cy','ko','gl','bg','id','el','hr','la' .

    #Works of type philosophy
    THESE_PHILOSOPHICAL_WORKS = "
    #Works of type philosophy (Q5891 = philosophy) (Q22811234 = branch of philosophy)
    # what = what sort of work it is: literary work, written work, scholarly article, review article, et cetera
    # genre = the branch of philosophy of the work
    # TODO handle multiple whats and multiple genres :/
    SELECT DISTINCT ?item ?itemLabel ?work ?workLabel (strlen(str(?workLabel)) AS ?len) ?linkCount # ?what ?whatLabel ?genre ?genreLabel 
    WHERE {
      {
        SELECT ?work ?genre ?item ?what (COUNT(?sitelink) AS ?linkCount) WHERE {
          ?work wdt:P136 ?genre.
          ?genre wdt:P31 wd:Q5891.
          ?work wdt:P50 ?item.
          OPTIONAL {?work wdt:P31 ?what.}
          OPTIONAL {?sitelink schema:about ?work.}
        } GROUP BY ?work ?genre ?item ?what
      }
      UNION
      {
        SELECT ?work ?genre ?item ?what (COUNT(?sitelink) AS ?linkCount) WHERE {
          ?work wdt:P136 ?genre.
          ?genre wdt:P279 wd:Q5891.
          ?work wdt:P50 ?item.
          OPTIONAL {?work wdt:P31 ?what.}
          OPTIONAL {?sitelink schema:about ?work.}
        } GROUP BY ?work ?genre ?item ?what
      }
      UNION
      {
        SELECT ?work ?genre ?item ?what (COUNT(?sitelink) AS ?linkCount) WHERE {
          ?work wdt:P136 ?genre.
          ?genre wdt:P279 ?subgenre.
          ?subgenre wdt:P279 wd:Q5891.
          ?work wdt:P50 ?item.
          OPTIONAL {?work wdt:P31 ?what.}
          OPTIONAL {?sitelink schema:about ?work.}
        } GROUP BY ?work ?genre ?item ?what
      }
      UNION
      {
        SELECT ?work ?genre ?item ?what (COUNT(?sitelink) AS ?linkCount) WHERE {
          ?work wdt:P136 ?genre.
          ?genre wdt:P31 wd:Q22811234.
          ?work wdt:P50 ?item.
          OPTIONAL {?work wdt:P31 ?what.}
          OPTIONAL {?sitelink schema:about ?work.}
        } GROUP BY ?work ?genre ?item ?what
      }
      UNION
      {
        SELECT ?work ?genre ?item ?what (COUNT(?sitelink) AS ?linkCount) WHERE {
          ?work wdt:P921 ?genre.
          ?genre wdt:P31 wd:Q5891.
          ?work wdt:P50 ?item.
          OPTIONAL {?work wdt:P31 ?what.}
          OPTIONAL {?sitelink schema:about ?work.}
        } GROUP BY ?work ?genre ?item ?what
      }
      UNION
      {
        SELECT ?work ?genre ?item ?what (COUNT(?sitelink) AS ?linkCount) WHERE {
          ?work wdt:P921 ?genre.
          ?genre wdt:P279 wd:Q5891.
          ?work wdt:P50 ?item.
          OPTIONAL {?work wdt:P31 ?what.}
          OPTIONAL {?sitelink schema:about ?work.}
        } GROUP BY ?work ?genre ?item ?what
      }
      UNION
      {
        SELECT ?work ?genre ?item ?what (COUNT(?sitelink) AS ?linkCount) WHERE {
          ?work wdt:P921 ?genre.
          ?genre wdt:P279 ?subgenre.
          ?subgenre wdt:P279 wd:Q5891.
          ?work wdt:P50 ?item.
          OPTIONAL {?work wdt:P31 ?what.}
          OPTIONAL {?sitelink schema:about ?work.}
        } GROUP BY ?work ?genre ?item ?what
      }
      UNION
      {
        SELECT ?work ?genre ?item ?what (COUNT(?sitelink) AS ?linkCount) WHERE {
          ?work wdt:P921 ?genre.
          ?genre wdt:P31 wd:Q22811234.
          ?work wdt:P50 ?item.
          OPTIONAL {?work wdt:P31 ?what.}
          OPTIONAL {?sitelink schema:about ?work.}
        } GROUP BY ?work ?genre ?item ?what 
      }
      FILTER (?genre != wd:Q9350) # genre != yoga
      FILTER (?what != wd:Q13442814) # && ?linkCount != 0) # isn't a \"scholarly\" article
      FILTER (?what != wd:Q7318358) # isn't a review article
      FILTER (?what != wd:Q871232) # isn't an editorial
      FILTER (?what != wd:Q1348305) # isn't an erratum
      FILTER (?linkCount != 0)
      SERVICE wikibase:label { bd:serviceParam wikibase:language 'en'. }
    }
    ".freeze
    
    OLD_DEEZ_PHIL_VURKS = "
    #Works of type philosophy (Q5891 = philosophy) (Q22811234 = branch of philosophy)
    SELECT DISTINCT ?item ?itemLabel ?work ?workLabel (strlen(str(?workLabel)) AS ?len) ?genre ?genreLabel ?linkCount WHERE {
      {
        SELECT ?work ?genre ?item (COUNT(?sitelink) AS ?linkCount) WHERE {
          ?work wdt:P136 ?genre.
          ?genre wdt:P279 wd:Q5891.
          ?work wdt:P50 ?item.
          OPTIONAL {?sitelink schema:about ?work.}
        } GROUP BY ?work ?genre ?item
      }
      UNION
      {
        SELECT ?work ?genre ?item (COUNT(?sitelink) AS ?linkCount) WHERE {
          ?work wdt:P136 ?genre.
          ?genre wdt:P31 wd:Q22811234.
          ?work wdt:P50 ?item.
          OPTIONAL {?sitelink schema:about ?work.}
        } GROUP BY ?work ?genre ?item
      }
      UNION
      {
        SELECT ?work ?genre ?item (COUNT(?sitelink) AS ?linkCount) WHERE {
          ?work wdt:P921 ?genre.
          ?genre wdt:P279 wd:Q5891.
          ?work wdt:P50 ?item.
          OPTIONAL {?sitelink schema:about ?work.}
        } GROUP BY ?work ?genre ?item
      }
      UNION
      {
        SELECT ?work ?genre ?item (COUNT(?sitelink) AS ?linkCount) WHERE {
          ?work wdt:P921 ?genre.
          ?genre wdt:P31 wd:Q22811234.
          ?work wdt:P50 ?item.
          OPTIONAL {?sitelink schema:about ?work.}
        } GROUP BY ?work ?genre ?item
      }
      SERVICE wikibase:label { bd:serviceParam wikibase:language 'en'. }
    }
    ".freeze
    
    # (COUNT(DISTINCT ?wLabel) AS ?whatCount) # 'ow many whats
    # notable works by philosophers from Wikidata
    THESE_WORKS_BY_PHILOSOPHERS = "
    # notable works by philosophers from Wikidata
    SELECT DISTINCT
      ?item
      ?work ?workLabel
      # ?wLabel
      (strlen(str(?workLabel)) AS ?len)
      (COUNT(DISTINCT ?sitelink) AS ?linkCount) # indication of how well known
      # (SAMPLE(?wLabel) AS ?whatLabel)
      (GROUP_CONCAT(DISTINCT ?wLabel; separator=\"; \") AS ?whatLabel)  # concat what sort of thing it is labels
      # (SAMPLE(?v) AS ?viaf) # some have more than one viaf? ignore all but one
      # (GROUP_CONCAT(DISTINCT ?v; separator=\"; \") AS ?viaf)  # pick one label
      (MIN(?v) AS ?viaf)
    WHERE {
      ?item wdt:P31 wd:Q5 . # is a human
      {{?item p:P106 ?l0. ?l0 ps:P106 wd:Q4964182.} UNION {?item p:P101 ?l0. ?l0 ps:P101 wd:Q4964182.} UNION {?item p:P39 ?l0. ?l0 ps:P39 wd:Q4964182.}} # a philosopher who is human
      { ?item wdt:P800 ?work .} UNION { ?work p:P50  ?c0 . ?c0 ps:P50 ?item .} # notable work UNION authored
      { ?work rdfs:label ?workLabel . FILTER (lang(?workLabel) = 'en') } # only get works with English titles, why?
      OPTIONAL { ?work p:P214  ?c0 . ?c0 ps:P214 ?v .} # viaf ID
      OPTIONAL { ?sitelink schema:about ?work .} # count these for a measure of noteworthiness
      OPTIONAL { ?work wdt:P31 ?w . ?w rdfs:label ?wLabel . FILTER (lang(?wLabel) = 'en') }
      FILTER (?w != wd:Q3305213) FILTER (?w != wd:Q2263612) FILTER (?w != wd:Q219423) # ignore visual arts
      FILTER (?w != wd:Q23058953) FILTER (?w != wd:Q23058950) FILTER (?w != wd:Q23011722) # ignore Ted talks
      FILTER (?w != wd:Q5292) FILTER (?w != wd:Q3331189) # ignore editions
    }
    GROUP BY ?item ?work ?workLabel # ?wLabel
    ORDER BY ?len DESC(?linkCount)
    ".freeze

    # interpolated entities !

    ATTR_ = "
    PREFIX wd: <http://www.wikidata.org/entity/>
    PREFIX wdt: <http://www.wikidata.org/prop/direct/>
    PREFIX schema: <http://schema.org/>
    PREFIX wikibase: <http://wikiba.se/ontology#>

    SELECT ?same
        (GROUP_CONCAT(DISTINCT ?birth;separator=';') AS ?births)
        (GROUP_CONCAT(DISTINCT ?death;separator=';') AS ?deaths)
        ?viaf ?floruit ?period ?gender
        ?work_lang ?pub_dates ?title ?country ?copyright ?image
        ?britannica ?philtopic ?philrecord
        ?qLabel (COUNT(DISTINCT ?sitelink) AS ?linkcount)
    WHERE {
      BIND (wd:%{interpolated_entity} AS ?q)
      OPTIONAL { ?q owl:sameAs ?same .}
      OPTIONAL {{?q p:P569  ?c00 . ?c00 ps:P569  ?birth .} UNION {?q wdt:P569 ?birth .} }
      OPTIONAL {{?q p:P570  ?c01 . ?c01 ps:P570  ?death .} UNION {?q wdt:P570 ?death .} }
      OPTIONAL { ?q p:P1317 ?c02 . ?c02 ps:P1317 ?floruit   .}
      OPTIONAL { ?q p:P2348 ?c03 . ?c03 ps:P2348 ?period    .}
      OPTIONAL { ?q p:P21   ?c04 . ?c04 ps:P21   ?gender    .}
      OPTIONAL { ?q p:P27   ?c05 . ?c05 ps:P27   ?citizen   .}
      OPTIONAL { ?q p:P214  ?c06 . ?c06 ps:P214  ?viaf      .}
      OPTIONAL { ?q p:P407  ?c10 . ?c10 ps:P407  ?work_lang .} #
      OPTIONAL { ?q p:P577  ?c11 . ?c11 ps:P577  ?pub_dates .} #
      OPTIONAL { ?q p:P1476 ?c12 . ?c12 ps:P1476 ?title     .} #
      OPTIONAL { ?q p:P495  ?c13 . ?c13 ps:P495  ?country   .} # country of origin of work
      OPTIONAL { ?q p:P6216 ?c14 . ?c14 ps:P6216 ?copyright .} #
      OPTIONAL { ?q p:P18   ?c15 . ?c15 ps:P18   ?image     .} #
      OPTIONAL { ?q p:P1417 ?c16 . ?c16 ps:P1417 ?britannica.}
      OPTIONAL { ?q p:P3235 ?c17 . ?c17 ps:P3235 ?philtopic .}
      OPTIONAL { ?q p:P3732 ?c18 . ?c18 ps:P3732 ?philrecord.}
      OPTIONAL { ?sitelink schema:about ?q .}
      SERVICE wikibase:label {
        bd:serviceParam wikibase:language 'en,nl,fr,de,es,it,sv,da,ru,ca,ja,hu,pl,fi,cs,zh,fa,sk,uk,ar,he,et,sl,bg,el,hr,la,hy,zh-cn,sr,az,lv,krc' .
        ?q rdfs:label ?qLabel .
      }
    }
    GROUP BY ?same ?births ?deaths ?viaf ?floruit ?period ?gender ?work_lang ?pub_dates ?title ?country ?copyright ?image ?britannica ?philtopic ?philrecord ?qLabel
    ".freeze

    # SUBJECT_
    # PREDICATE_
    # OBJECT_
    DATUM_ = "
    PREFIX wd: <http://www.wikidata.org/entity/>
    PREFIX wdt: <http://www.wikidata.org/prop/direct/>
    PREFIX p: <http://www.wikidata.org/prop/>
    PREFIX ps: <http://www.wikidata.org/prop/statement/>
    PREFIX schema: <http://schema.org/>
    PREFIX wikibase: <http://wikiba.se/ontology#>

    SELECT
      ?same
      ?q
      ?qLabel
      ?datum
      ?datumLabel
    WHERE {
      BIND (wd:%{interpolated_entity}    AS ?q)
      BIND (p:%{interpolated_property}   AS ?p)
      BIND (ps:%{interpolated_property} AS ?ps)
      OPTIONAL { ?q owl:sameAs ?same        .}
      OPTIONAL { ?q ?p ?c00 . ?c00 ?ps ?datum.}
      SERVICE wikibase:label {
        bd:serviceParam wikibase:language 'en,nl,fr,de,es,it,sv,da,ru,ca,ja,hu,pl,fi,cs,zh,fa,sk,uk,ar,he,et,sl,bg,el,hr,la,hy,zh-cn,sr,az,lv,krc' .
        ?q rdfs:label ?qLabel .
        ?datum rdfs:label ?datumLabel .
      }
    }
    GROUP BY ?same ?q ?qLabel ?datum ?datumLabel
    ".freeze

    # ?data has been check to not be null :/
    DATUM_INSTANCE_ = "
    PREFIX wd: <http://www.wikidata.org/entity/>
    PREFIX wdt: <http://www.wikidata.org/prop/direct/>
    PREFIX schema: <http://schema.org/>
    PREFIX wikibase: <http://wikiba.se/ontology#>

    SELECT
      ?same
      ?q
      ?qLabel
      ?data
      ?dataLabel
      ?instance
      ?instanceLabel
    WHERE {
      BIND (wd:%{interpolated_entity}    AS ?q)
      BIND (p:%{interpolated_property}   AS ?p)
      BIND (ps:%{interpolated_property} AS ?ps)
      OPTIONAL { ?q owl:sameAs ?same        .}
      OPTIONAL { ?q ?p ?c00 . ?c00 ?ps ?data.}
      OPTIONAL { ?data wdt:P31 ?instance    .}
      SERVICE wikibase:label {
        bd:serviceParam wikibase:language 'en,nl,fr,de,es,it,sv,da,ru,ca,ja,hu,pl,fi,cs,zh,fa,sk,uk,ar,he,et,sl,bg,el,hr,la,hy,zh-cn,sr,az,lv,krc' .
        ?q rdfs:label ?qLabel .
        ?data rdfs:label ?dataLabel .
        ?instance rdfs:label ?instanceLabel .
      }
    }
    GROUP BY ?same ?q ?qLabel ?data ?dataLabel ?instance ?instanceLabel
    ".freeze

    ASSOC_COUNTRY_ = "
    PREFIX wd: <http://www.wikidata.org/entity/>
    PREFIX wdt: <http://www.wikidata.org/prop/direct/>
    PREFIX schema: <http://schema.org/>
    PREFIX wikibase: <http://wikiba.se/ontology#>

    SELECT DISTINCT
      ?q
      ?qLabel
      ?connector
      ?connectorLabel
    WHERE {
      BIND (wd:%{interpolated_entity} AS ?q)
      { ?q ?foo ?connector. ?connector wdt:P31 wd:Q6256}
      SERVICE wikibase:label {
        bd:serviceParam wikibase:language 'en,nl,fr,de,es,it,sv,da,ru,ca,ja,hu,pl,fi,cs,zh,fa,sk,uk,ar,he,et,sl,bg,el,hr,la,hy,zh-cn,sr,az,lv,krc' .
        ?q rdfs:label ?qLabel .
        ?connector rdfs:label ?connectorLabel .
        ?foo rdfs:label ?fooLabel .
      }
    }
    GROUP BY ?same ?q ?qLabel ?connector ?connectorLabel ?foo ?fooLabel
    ".freeze

    ROLE_ = "
    PREFIX wd: <http://www.wikidata.org/entity/>
    PREFIX wdt: <http://www.wikidata.org/prop/direct/>
    PREFIX schema: <http://schema.org/>
    PREFIX wikibase: <http://wikiba.se/ontology#>

    SELECT ?same
        ?role
        ?qLabel
        ?roleLabel
    WHERE {
      BIND (wd:%{interpolated_entity} AS ?q)
      OPTIONAL { ?q owl:sameAs ?same .}
      OPTIONAL {
        { ?q p:P106  ?stmt1 . ?stmt1 ps:P106  ?role .}
        UNION
        { ?q p:P101  ?stmt2 . ?stmt2 ps:P101  ?role .}
        UNION
        { ?q p:P106  ?stmt3 . ?stmt3 pq:P101  ?role .}
        UNION
        { ?q p:P101  ?stmt4 . ?stmt4 pq:P106  ?role .}
      }
      OPTIONAL { ?sitelink schema:about ?q .}
      SERVICE wikibase:label {
        bd:serviceParam wikibase:language 'en,nl,fr,de,es,it,sv,da,ru,ca,ja,hu,pl,fi,cs,zh,fa,sk,uk,ar,he,et,sl,bg,el,hr,la,hy,zh-cn,sr,az,lv,krc' .
        ?q rdfs:label ?qLabel .
        ?role rdfs:label ?roleLabel .
      }
    }
    GROUP BY ?same ?role ?roleLabel ?qLabel
    ".freeze

    LABEL = "
    SELECT ?label ?linkcount WHERE {
      {
        SELECT (COUNT(DISTINCT ?sitelink) AS ?linkcount) WHERE {
          ?sitelink schema:about wd:%{interpolated_entity} .
        }
      }
      {
        SELECT ?label WHERE {
          wd:%{interpolated_entity} rdfs:label ?label .
        }
      }
    }
    ".freeze

    HITS1 = "
    PREFIX wd: <http://www.wikidata.org/entity/>
    PREFIX schema: <http://schema.org/>

    SELECT (COUNT(DISTINCT ?desc) AS ?hits) WHERE {
      wd:%{interpolated_entity} schema:description ?desc . FILTER (CONTAINS(lcase(str(?desc)),'%{interpolated_filter}')) .
    }
    ".freeze

    HITS2 = "
    PREFIX wd: <http://www.wikidata.org/entity/>
    PREFIX schema: <http://schema.org/>

    SELECT (COUNT(DISTINCT ?desc) AS ?hits) WHERE {
      wd:%{interpolated_entity} schema:description ?desc . FILTER(%{interpolated_filter}) .
    }
    ".freeze

    FIND_BY_NAME = "
    #old method for sitelink count
    SELECT ?s ?same ?birth ?death ?floruit ?period ?desc (COUNT(DISTINCT ?sitelink) as ?linkcount)
    WHERE
    {
      ?s wdt:P31 wd:Q5 .
      ?s rdfs:label \"%{interpolated_entity}\"@en .
      OPTIONAL { ?s owl:sameAs ?same }
      OPTIONAL { {?s p:P569 ?c1 . ?c1 ps:P569  ?birth .} UNION {?s wdt:P569 ?birth .} }
      OPTIONAL { {?s p:P570 ?c2 . ?c2 ps:P570  ?death .} UNION {?s wdt:P570 ?death .} }
      OPTIONAL { ?s p:P1317 ?c3 . ?c3 ps:P1317 ?floruit .}
      OPTIONAL { ?s p:P2348 ?c4 . ?c4 ps:P2348 ?period .}
      OPTIONAL { ?sitelink schema:about ?s .}
      OPTIONAL { ?s rdfs:label ?desc filter (lang(?desc) = 'en'). }
    } GROUP BY ?s ?same ?birth ?death ?floruit ?period ?desc ORDER BY DESC(?linkcount) LIMIT 1
    ".freeze

    FIND_BY_ID = "
    #old method for sitelink count
    SELECT ?s ?same ?birth ?death ?floruit ?period ?desc (COUNT(DISTINCT ?sitelink) as ?linkcount)
    WHERE
    {
      BIND (wd:%{interpolated_entity} AS ?s)
      OPTIONAL { ?s owl:sameAs ?same }
      OPTIONAL { {?s p:P569 ?c1 . ?c1 ps:P569  ?birth .} UNION {?s wdt:P569 ?birth .} }
      OPTIONAL { {?s p:P570 ?c2 . ?c2 ps:P570  ?death .} UNION {?s wdt:P570 ?death .} }
      OPTIONAL { ?s p:P1317 ?c3 . ?c3 ps:P1317 ?floruit .}
      OPTIONAL { ?s p:P2348 ?c4 . ?c4 ps:P2348 ?period .}
      OPTIONAL { ?sitelink schema:about ?s .}
      OPTIONAL { ?s rdfs:label ?desc filter (lang(?desc) = 'en'). }
    } GROUP BY ?s ?same ?birth ?death ?floruit ?period ?desc ORDER BY DESC(?linkcount) LIMIT 1
    ".freeze
  end
end