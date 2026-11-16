local _, addon = ...

-- User-facing text, keyed by the English fallback. Keep format arguments in order.
addon.Locales.deDE = {
    ["Auto"] = "Auto",
    ["Own scans"] = "Eigene Scans",
    ["Off"] = "Aus",
    ["ready"] = "bereit",
    ["unavailable"] = "nicht verfügbar",
    ["Crate prices and shopping. Green: lowest known filling cost. Click an option to choose a different bundle."] = "Kistenpreise und Einkauf. Grün: niedrigste bekannte Füllkosten. Klicke auf eine Option, um ein anderes Paket zu wählen.",
    ["Scan bags"] = "Taschen scannen",
    ["Scan hovered"] = "Gezeigte scannen",
    ["Full AH scan"] = "Auktionshaus scannen",
    ["Stop scan"] = "Scan stoppen",
    ["Copy diagnostics"] = "Diagnose kopieren",
    ["Settings"] = "Einstellungen",
    ["Hover a crate"] = "Kiste ansehen",
    ["Hover a crate to choose a bundle"] = "Kiste ansehen, um ein Paket zu wählen",
    ["Search all alternatives"] = "Alle Alternativen suchen",
    ["Shop selected option"] = "Gewähltes Paket kaufen",
    ["Scan tracked crates"] = "Erfasste Kisten scannen",
    ["Inventory snapshots"] = "Inventarstände",
    ["Auto refresh scans only missing/stale tracked requirements while this panel is open. Stop pauses it for this auction visit."] = "Die automatische Aktualisierung scannt fehlende oder alte Preise erfasster Materialien, solange dieses Fenster offen ist. Stopp pausiert sie für diesen Auktionshausbesuch.",
    ["Prices: %s (change)"] = "Preise: %s (ändern)",
    ["TSM: Market value (change)"] = "TSM: Marktwert (ändern)",
    ["TSM: Min buyout (change)"] = "TSM: Sofortkauf (ändern)",
    ["Reading the auction-house snapshot..."] = "Auktionsdaten werden gelesen...",
    ["Scanning %d/%d: %s\n%d updated, %d failed. Hover again for updated prices."] = "Scan %d/%d: %s\n%d aktualisiert, %d fehlgeschlagen. Für aktuelle Preise erneut ansehen.",
    ["Auction house open. Ready to scan."] = "Auktionshaus geöffnet. Bereit zum Scannen.",
    ["Open an auction house to scan."] = "Zum Scannen das Auktionshaus öffnen.",
    ["\nProfile: %s; Auctionator: %s; TSM: %s"] = "\nProfil: %s; Auctionator: %s; TSM: %s",
    ["%s (cycle tracked crates)"] = "%s (erfasste Kisten wechseln)",
    [" (scan failed)"] = " (Scan fehlgeschlagen)",
    [" (stale)"] = " (veraltet)",
    ["Option %d/%d: %dx %s%s"] = "Option %d/%d: %dx %s%s",
    ["Hover an identified crate to choose a bundle."] = "Identifizierte Kiste ansehen, um ein Paket zu wählen.",
    ["Remembered: %d crates, %d characters, %d visited banks.\nBags update on login; bank contents update when visited."] = "Gespeichert: %d Kisten, %d Charaktere, %d besuchte Banken.\nTaschen werden beim Einloggen aktualisiert, Banken beim Besuch.",
    ["Craftsman's Writs"] = "Handwerksverfügungen",
    ["Waylaid Crates"] = "Abgefangene Kisten",
    ["Waylaid"] = "Lieferungen",
    ["Writ prices: %s"] = "Auftragspreise: %s",
    ["Crate prices: %s"] = "Kistenpreise: %s",
    ["TSM price: %s"] = "TSM-Preis: %s",
    ["Show minimap button"] = "Minikartenknopf anzeigen",
    ["Remember crate and material inventory"] = "Kisten- und Materialbestände speichern",
    ["Include visited character and shared banks"] = "Besuchte Charakter- und Gemeinschaftsbanken einbeziehen",
    ["Include remembered characters on this realm/faction"] = "Gespeicherte Charaktere dieses Realms/dieser Fraktion einbeziehen",
    ["Auto refresh tracked prices in the Crates list"] = "Erfasste Preise in der Kistenliste automatisch aktualisieren",
    ["Auto-scan crate prices on auction open (Auto/Own)"] = "Kistenpreise beim Öffnen des Auktionshauses scannen (Auto/Eigene)",
    ["Always show detailed price tooltips"] = "Immer detaillierte Preistooltips anzeigen",
    ["Crate prices"] = "Kistenpreise",
    ["Writ prices"] = "Auftragspreise",
    ["TSM price"] = "TSM-Preis",
    ["Scan controls"] = "Scansteuerung",
    ["Clear remembered inventory"] = "Inventarstände löschen",
    ["WoW's AddOns settings are unavailable on this client."] = "Die AddOn-Einstellungen sind auf diesem Client nicht verfügbar.",
    ["Waylaid Ledger - select and copy with Ctrl+C / Cmd+C"] = "Waylaid Ledger – markieren und mit Strg+C / Cmd+C kopieren",
    ["No price"] = "Kein Preis",
    ["Purchase + delivery"] = "Kauf + Lieferung",
    ["Purchase (1)"] = "Kauf (1)",
    ["Total"] = "Gesamt",
    ["Scanning %d/%d"] = "Scan %d/%d",
    ["%d priced / %d items"] = "%d mit Preis / %d Artikel",
    ["Refresh"] = "Erneuern",
    ["Refresh list"] = "Liste aktualisieren",
    ["Refresh saved prices; scan missing or stale prices when providers have no current data."] = "Gespeicherte Preise aktualisieren; fehlende oder alte Preise scannen, wenn die Preisanbieter keine aktuellen Daten haben.",
    ["Scan prices"] = "Preise scannen",
    ["Stop"] = "Stopp",
    ["Item / delivery goods"] = "Artikel / Lieferwaren",
    ["Purchase"] = "Kauf",
    ["Delivery"] = "Lieferung",
    ["Total (lowest first)"] = "Gesamt (aufsteigend)",
    [" (%d owned)"] = " (%d im Besitz)",
    ["Not scanned"] = "Nicht gescannt",
    [" (buy %d)"] = " (%d kaufen)",
    ["None listed"] = "Keine Angebote",
    ["Only %d"] = "Nur %d",
    [" failed"] = " fehlgeschlagen",
    ["%dm"] = "%d Min.",
    ["%dd"] = "%d T.",
    [", age unknown"] = ", Alter unbekannt",
    [", own scan failed"] = ", eigener Scan fehlgeschlagen",
    ["Identify this shipment first to compare its filling costs."] = "Identifiziere diese Lieferung zuerst, um ihre Füllkosten zu vergleichen.",
    ["Delivery requirements unresolved. Run a full AH scan, then hover this item again."] = "Lieferbedarf unbekannt. Führe einen vollständigen Auktionshausscan aus und sieh den Artikel erneut an.",
    ["Waylaid Ledger - delivery estimate"] = "Waylaid Ledger – Lieferkosten",
    ["Incomplete prices"] = "Preise unvollständig",
    ["Left-click: open | Right-click: settings"] = "Linksklick: öffnen | Rechtsklick: Einstellungen",
    ["Drag to move around the minimap"] = "Ziehen, um den Knopf zu verschieben",
    ["Open the auction house first."] = "Öffne zuerst das Auktionshaus.",
    ["Item information is loading. Try again in a moment."] = "Artikeldaten werden geladen. Versuche es gleich erneut.",
    ["Auction searches are throttled. Try again shortly."] = "Auktionssuchen sind begrenzt. Versuche es gleich erneut.",
    ["Could not open the auction search: %s"] = "Auktionssuche konnte nicht geöffnet werden: %s",
    ["The auction house's buying UI is unavailable."] = "Die Kaufoberfläche des Auktionshauses ist nicht verfügbar.",
    ["Waylaid shopping basket"] = "Waylaid-Einkaufskorb",
    ["Compare these alternatives; buy only one bundle."] = "Vergleiche die Alternativen und kaufe nur ein Paket.",
    ["Open each item and buy the quantity shown. Purchases use the auction house's confirmation."] = "Öffne jeden Artikel und kaufe die angegebene Menge. Käufe werden im Auktionshaus bestätigt.",
    ["Delivery requirements unresolved. Run a full AH scan."] = "Lieferbedarf unbekannt. Führe einen vollständigen Auktionshausscan aus.",
    ["Writ prices are disabled in settings."] = "Auftragspreise sind in den Einstellungen deaktiviert.",
    ["Scan crate materials or update Auctionator/TSM prices to choose a filling option."] = "Scanne Kistenmaterialien oder aktualisiere Auctionator-/TSM-Preise, um ein Füllpaket zu wählen.",
    ["Delivery price unavailable"] = "Lieferpreis unbekannt",
    ["Unknown item."] = "Unbekannter Artikel.",
    ["An item name is still loading. Try the search again in a moment."] = "Ein Artikelname wird noch geladen. Versuche die Suche gleich erneut.",
    ["Automatic refresh paused."] = "Automatische Aktualisierung pausiert.",
    ["Scan stopped for shopping."] = "Scan für den Einkauf gestoppt.",
    ["Auction house closed; completed prices were kept."] = "Auktionshaus geschlossen; erfasste Preise bleiben gespeichert.",
    ["A scan is already running. Stop it before starting another."] = "Ein Scan läuft bereits. Stoppe ihn, bevor du einen neuen startest.",
    ["No recognized crates found. Use Scan all or hover a crate first."] = "Keine bekannten Kisten gefunden. Scanne alles oder sieh zuerst eine Kiste an.",
    ["Scanning..."] = "Scan läuft...",
    ["Scan stopped; completed prices were kept."] = "Scan gestoppt; erfasste Preise bleiben gespeichert.",
    ["Scan stopped because another auction search started. Scan again when the auction house is idle."] = "Scan wegen einer anderen Auktionssuche gestoppt. Scanne erneut, wenn das Auktionshaus bereit ist.",
    ["Full scan did not complete. Retry when the auction house is idle."] = "Vollständiger Scan nicht abgeschlossen. Versuche es erneut, wenn das Auktionshaus bereit ist.",
    ["Full scan data could not be read: %s"] = "Scandaten konnten nicht gelesen werden: %s",
    ["Reading full scan: %d / %d auctions"] = "Scan wird gelesen: %d / %d Auktionen",
    ["Wait for the full scan to finish or stop it first."] = "Warte auf den vollständigen Scan oder stoppe ihn zuerst.",
    ["An auction scan is already running."] = "Ein Auktionsscan läuft bereits.",
    ["Full-scan cooldown: using saved prices. /wll scan deep refreshes known delivery items."] = "Vollständiger Scan hat Abklingzeit: gespeicherte Preise werden verwendet. /wll scan deep aktualisiert bekannte Lieferwaren.",
    ["Requesting one full auction-house snapshot..."] = "Vollständige Auktionsdaten werden angefordert...",
    ["Full scan could not start: %s"] = "Vollständiger Scan konnte nicht starten: %s",
    ["Full scan returned an invalid auction count."] = "Vollständiger Scan meldete eine ungültige Auktionsanzahl.",
    ["No matching writs or crates to scan."] = "Keine passenden Aufträge oder Kisten zum Scannen.",
    ["Auction-open scan disabled."] = "Scan beim Öffnen des Auktionshauses deaktiviert.",
    ["Automatic refresh disabled."] = "Automatische Aktualisierung deaktiviert.",
    ["Automatic scan stopped for the selected price source."] = "Automatischer Scan für die gewählte Preisquelle gestoppt.",
    ["Use /wll source auto, auctionator, tsm, or own."] = "Verwende /wll source auto, auctionator, tsm oder own.",
    ["Use /wll writsource auto, auctionator, tsm, own, or off."] = "Verwende /wll writsource auto, auctionator, tsm, own oder off.",
    ["Use /wll tsmkey DBMinBuyout or DBMarket."] = "Verwende /wll tsmkey DBMinBuyout oder DBMarket.",
    ["Hover an identified Waylaid Crate first."] = "Sieh zuerst eine identifizierte abgefangene Kiste an.",
    ["Open the auction house to shop."] = "Öffne zum Einkaufen das Auktionshaus.",
    ["Choose an option between 1 and %d."] = "Wähle eine Option zwischen 1 und %d.",
    ["Searching all alternatives in Auctionator. Buy only one bundle to fill the crate."] = "Alle Alternativen werden in Auctionator gesucht. Kaufe nur ein Paket zum Füllen der Kiste.",
    ["Opened the selected bundle in Auctionator. Review the listings before buying."] = "Gewähltes Paket in Auctionator geöffnet. Prüfe die Angebote vor dem Kauf.",
    ["Stop the current scan first."] = "Stoppe zuerst den aktuellen Scan.",
    ["Choose Auto or Own scans for this category in Settings."] = "Wähle in den Einstellungen Auto oder Eigene Scans für diese Kategorie.",
    ["Price source: %s. Options: auto, auctionator, tsm, own."] = "Preisquelle: %s. Optionen: auto, auctionator, tsm, own.",
    ["Writ source: %s. Options: auto, auctionator, tsm, own, off."] = "Auftragsquelle: %s. Optionen: auto, auctionator, tsm, own, off.",
    ["TSM source: %s. Options: DBMinBuyout, DBMarket."] = "TSM-Quelle: %s. Optionen: DBMinBuyout, DBMarket.",
    ["Use /wll shop [option number]."] = "Verwende /wll shop [Optionsnummer].",
    ["Use /wll %s on or off, or /wll settings."] = "Verwende /wll %s on oder off, oder /wll settings.",
    ["Debug logging enabled."] = "Diagnoseprotokoll aktiviert.",
    ["Debug logging disabled."] = "Diagnoseprotokoll deaktiviert.",
    ["Stopped to clear this market's prices."] = "Scan zum Löschen der Marktpreise gestoppt.",
    ["Cached prices cleared for this market profile."] = "Gespeicherte Preise dieses Marktprofils gelöscht.",
    ["Current profile: %s. Change with /wll market <name>."] = "Aktuelles Profil: %s. Ändern mit /wll market <Name>.",
    ["Stopped because the market profile changed."] = "Scan wegen eines Marktprofilwechsels gestoppt.",
    ["Market profile: %s. Scan this auction house to populate its prices."] = "Marktprofil: %s. Scanne dieses Auktionshaus, um Preise zu erfassen.",
    ["Use a profile name of 1-40 letters, digits, underscores or hyphens."] = "Verwende einen Profilnamen mit 1–40 Buchstaben, Ziffern, Unterstrichen oder Bindestrichen.",
    ["This client has no supported C_AuctionHouse API. Please send its /dump GetBuildInfo() output."] = "Dieser Client unterstützt die C_AuctionHouse-API nicht. Bitte sende die Ausgabe von /dump GetBuildInfo().",
    ["No supported tooltip hook found. Use /wll report to collect diagnostics."] = "Kein unterstützter Tooltip-Hook gefunden. Verwende /wll report für die Diagnose.",
    ["Loaded. /wll opens scans, price sources, and shopping."] = "Geladen. /wll öffnet Scans, Preisquellen und Einkauf.",
    ["TSM market"] = "TSM-Marktwert",
    ["TSM min buyout"] = "TSM-Sofortkauf",
    ["Auctionator's shopping API is unavailable. Install/enable a compatible Auctionator release."] = "Auctionators Einkaufs-API ist nicht verfügbar. Installiere oder aktiviere eine kompatible Version.",
    ["Auctionator could not convert the search: %s"] = "Auctionator konnte die Suche nicht umwandeln: %s",
    ["Auctionator could not start the search: %s"] = "Auctionator konnte die Suche nicht starten: %s",
    ["AH full scan"] = "AH-Gesamtscan",
    ["Own scan"] = "Eigener Scan",
    ["Automatic refresh paused after closing the panel."] = "Automatische Aktualisierung pausiert.",
    ["Automatic refresh paused after leaving the list."] = "Automatische Aktualisierung pausiert.",
    ["Automatic refresh paused after leaving the crates list."] = "Automatische Aktualisierung pausiert.",
    ["Automatic refresh paused after changing category."] = "Automatische Aktualisierung pausiert.",
    ["Stopped to open a basket item in the auction house."] = "Scan für den Einkauf gestoppt.",
    ["Stopped to open the built-in shopping basket."] = "Scan für den Einkauf gestoppt.",
    ["Stopped to hand the search to Auctionator."] = "Scan für den Einkauf gestoppt.",
    ["Stopped to hand the complete basket to Auctionator."] = "Scan für den Einkauf gestoppt.",
    ["Refresh: Own + Auctionator"] = "Aktualisieren: Eigen + Auctionator",
    ["Refresh: Own scan"] = "Aktualisieren: Eigener Scan",
    ["Refresh mode"] = "Aktualisierungsmodus",
    ["TSM group export"] = "TSM-Gruppe exportieren",
    ["Starting a new scoped refresh."] = "Neue gezielte Aktualisierung wird gestartet.",
    ["Refreshing %d unique items for the current %s list."] = "%d unterschiedliche Artikel der Liste %s werden aktualisiert.",
    ["Select Auto or Own to display our scan results; the selected provider keeps its own data."] = "Wähle Auto oder Eigene Scans, um unsere Ergebnisse zu sehen; der gewählte Anbieter behält seine eigenen Daten.",
    ["No matching items to scan."] = "Keine passenden Artikel zum Scannen.",
    ["Auctionator scans are disabled for custom market profiles."] = "Auctionator-Scans sind für eigene Marktprofile deaktiviert.",
    ["Auctionator's limited-search API is unavailable."] = "Auctionators API für gezielte Suchen ist nicht verfügbar.",
    ["Handing the limited item search to Auctionator."] = "Gezielte Artikelsuche wird an Auctionator übergeben.",
    ["Started a limited search in Auctionator Shopping (%d items)."] = "Gezielte Suche in Auctionator Shopping gestartet (%d Artikel).",
    ["No matching items to export."] = "Keine passenden Artikel zum Exportieren.",
    ["TSM import - copy, import into a group, then run its Shopping scan"] = "TSM-Import – kopieren, in eine Gruppe importieren und deren Shopping-Scan starten",
    ["Exported %d items. Import into TSM and start its group Shopping scan manually."] = "%d Artikel exportiert. Importiere sie in TSM und starte den Shopping-Scan der Gruppe manuell.",
    ["Item names are loading; retry the Auctionator scan shortly."] = "Artikelnamen werden geladen; versuche den Auctionator-Scan gleich erneut.",
    ["Refresh prices for this list. Uses a full AH snapshot when supported; otherwise scans its items."] = "Preise dieser Liste aktualisieren. Nutzt vollständige Auktionsdaten, falls unterstützt; sonst werden die Artikel einzeln gescannt.",
    ["Full AH scans wait for server readiness; saved prices remain available."] = "Vollständige Scans warten auf den Server; gespeicherte Preise bleiben verfügbar.",
    ["Then open a limited Auctionator Shopping search when available."] = "Anschließend eine gezielte Auctionator-Shopping-Suche öffnen, falls verfügbar.",
    ["Own scanner only. Auctionator follow-up is configurable in Settings."] = "Nur eigener Scanner. Die Auctionator-Folgesuche ist in den Einstellungen konfigurierbar.",
}

addon.Locales.frFR = {
    ["Auto"] = "Auto",
    ["Own scans"] = "Mes analyses",
    ["Off"] = "Désactivé",
    ["ready"] = "prêt",
    ["unavailable"] = "indisponible",
    ["Crate prices and shopping. Green: lowest known filling cost. Click an option to choose a different bundle."] = "Prix des caisses et achats. Vert : coût de remplissage connu le plus bas. Cliquez sur une option pour choisir un autre lot.",
    ["Scan bags"] = "Analyser les sacs",
    ["Scan hovered"] = "Analyser le survol",
    ["Full AH scan"] = "Analyse complète",
    ["Stop scan"] = "Arrêter l'analyse",
    ["Copy diagnostics"] = "Copier le diagnostic",
    ["Settings"] = "Options",
    ["Hover a crate"] = "Survolez une caisse",
    ["Hover a crate to choose a bundle"] = "Survolez une caisse pour choisir un lot",
    ["Search all alternatives"] = "Chercher tous les lots",
    ["Shop selected option"] = "Acheter le lot choisi",
    ["Scan tracked crates"] = "Analyser les caisses suivies",
    ["Inventory snapshots"] = "Inventaires mémorisés",
    ["Auto refresh scans only missing/stale tracked requirements while this panel is open. Stop pauses it for this auction visit."] = "L'actualisation automatique analyse les prix manquants ou anciens des composants suivis tant que ce panneau est ouvert. Arrêter la suspend pour cette visite.",
    ["Prices: %s (change)"] = "Prix : %s (modifier)",
    ["TSM: Market value (change)"] = "TSM : valeur du marché",
    ["TSM: Min buyout (change)"] = "TSM : achat immédiat min.",
    ["Reading the auction-house snapshot..."] = "Lecture des données de l'hôtel des ventes...",
    ["Scanning %d/%d: %s\n%d updated, %d failed. Hover again for updated prices."] = "Analyse %d/%d : %s\n%d mis à jour, %d échecs. Survolez à nouveau pour voir les prix.",
    ["Auction house open. Ready to scan."] = "Hôtel des ventes ouvert. Prêt à analyser.",
    ["Open an auction house to scan."] = "Ouvrez l'hôtel des ventes pour analyser.",
    ["\nProfile: %s; Auctionator: %s; TSM: %s"] = "\nProfil : %s ; Auctionator : %s ; TSM : %s",
    ["%s (cycle tracked crates)"] = "%s (changer de caisse suivie)",
    [" (scan failed)"] = " (échec de l'analyse)",
    [" (stale)"] = " (ancien)",
    ["Option %d/%d: %dx %s%s"] = "Option %d/%d : %dx %s%s",
    ["Hover an identified crate to choose a bundle."] = "Survolez une caisse identifiée pour choisir un lot.",
    ["Remembered: %d crates, %d characters, %d visited banks.\nBags update on login; bank contents update when visited."] = "Mémorisés : %d caisses, %d personnages, %d banques visitées.\nLes sacs sont actualisés à la connexion, les banques lors d'une visite.",
    ["Craftsman's Writs"] = "Commissions d'artisan",
    ["Waylaid Crates"] = "Caisses détournées",
    ["Waylaid"] = "Livraisons",
    ["Writ prices: %s"] = "Prix des commissions : %s",
    ["Crate prices: %s"] = "Prix des caisses : %s",
    ["TSM price: %s"] = "Prix TSM : %s",
    ["Show minimap button"] = "Afficher le bouton de minicarte",
    ["Remember crate and material inventory"] = "Mémoriser les caisses et composants",
    ["Include visited character and shared banks"] = "Inclure les banques de personnage et partagées visitées",
    ["Include remembered characters on this realm/faction"] = "Inclure les personnages mémorisés de ce royaume et de cette faction",
    ["Auto refresh tracked prices in the Crates list"] = "Actualiser automatiquement les prix suivis dans la liste des caisses",
    ["Auto-scan crate prices on auction open (Auto/Own)"] = "Analyser les prix des caisses à l'ouverture de l'hôtel des ventes (Auto/Mes analyses)",
    ["Always show detailed price tooltips"] = "Toujours afficher les détails des prix",
    ["Crate prices"] = "Prix des caisses",
    ["Writ prices"] = "Prix des commissions",
    ["TSM price"] = "Prix TSM",
    ["Scan controls"] = "Commandes d'analyse",
    ["Clear remembered inventory"] = "Effacer les inventaires",
    ["WoW's AddOns settings are unavailable on this client."] = "Les options des addons ne sont pas disponibles sur ce client.",
    ["Waylaid Ledger - select and copy with Ctrl+C / Cmd+C"] = "Waylaid Ledger – sélectionner et copier avec Ctrl+C / Cmd+C",
    ["No price"] = "Aucun prix",
    ["Purchase + delivery"] = "Achat + livraison",
    ["Purchase (1)"] = "Achat (1)",
    ["Total"] = "Total",
    ["Scanning %d/%d"] = "Analyse %d/%d",
    ["%d priced / %d items"] = "%d prix connus / %d objets",
    ["Refresh"] = "Actualiser",
    ["Refresh list"] = "Actualiser la liste",
    ["Refresh saved prices; scan missing or stale prices when providers have no current data."] = "Actualise les prix mémorisés ; analyse les prix manquants ou anciens si les fournisseurs n'ont pas de données récentes.",
    ["Scan prices"] = "Analyser les prix",
    ["Stop"] = "Arrêter",
    ["Item / delivery goods"] = "Objet / biens à livrer",
    ["Purchase"] = "Achat",
    ["Delivery"] = "Livraison",
    ["Total (lowest first)"] = "Total (croissant)",
    [" (%d owned)"] = " (%d possédés)",
    ["Not scanned"] = "Non analysé",
    [" (buy %d)"] = " (acheter %d)",
    ["None listed"] = "Aucune offre",
    ["Only %d"] = "Seulement %d",
    [" failed"] = " échec",
    ["%dm"] = "%d min",
    ["%dd"] = "%d j",
    [", age unknown"] = ", ancienneté inconnue",
    [", own scan failed"] = ", échec de mon analyse",
    ["Identify this shipment first to compare its filling costs."] = "Identifiez d'abord cette livraison pour comparer les coûts de remplissage.",
    ["Delivery requirements unresolved. Run a full AH scan, then hover this item again."] = "Livraison non résolue. Analysez tout l'hôtel des ventes, puis survolez à nouveau cet objet.",
    ["Waylaid Ledger - delivery estimate"] = "Waylaid Ledger – estimation de livraison",
    ["Incomplete prices"] = "Prix incomplets",
    ["Left-click: open | Right-click: settings"] = "Clic gauche : ouvrir | Clic droit : options",
    ["Drag to move around the minimap"] = "Faites glisser autour de la minicarte",
    ["Open the auction house first."] = "Ouvrez d'abord l'hôtel des ventes.",
    ["Item information is loading. Try again in a moment."] = "Chargement de l'objet. Réessayez dans un instant.",
    ["Auction searches are throttled. Try again shortly."] = "Recherches d'enchères limitées. Réessayez dans un instant.",
    ["Could not open the auction search: %s"] = "Impossible d'ouvrir la recherche : %s",
    ["The auction house's buying UI is unavailable."] = "L'interface d'achat n'est pas disponible.",
    ["Waylaid shopping basket"] = "Panier de livraison",
    ["Compare these alternatives; buy only one bundle."] = "Comparez les options ; n'achetez qu'un seul lot.",
    ["Open each item and buy the quantity shown. Purchases use the auction house's confirmation."] = "Ouvrez chaque objet et achetez la quantité indiquée. Les achats utilisent la confirmation de l'hôtel des ventes.",
    ["Delivery requirements unresolved. Run a full AH scan."] = "Livraison non résolue. Analysez tout l'hôtel des ventes.",
    ["Writ prices are disabled in settings."] = "Les prix des commissions sont désactivés dans les options.",
    ["Scan crate materials or update Auctionator/TSM prices to choose a filling option."] = "Analysez les composants ou actualisez les prix Auctionator/TSM pour choisir un lot.",
    ["Delivery price unavailable"] = "Prix de livraison indisponible",
    ["Unknown item."] = "Objet inconnu.",
    ["An item name is still loading. Try the search again in a moment."] = "Un nom d'objet est en cours de chargement. Réessayez dans un instant.",
    ["Automatic refresh paused."] = "Actualisation automatique suspendue.",
    ["Scan stopped for shopping."] = "Analyse arrêtée pour les achats.",
    ["Auction house closed; completed prices were kept."] = "Hôtel des ventes fermé ; prix recueillis conservés.",
    ["A scan is already running. Stop it before starting another."] = "Une analyse est en cours. Arrêtez-la avant d'en lancer une autre.",
    ["No recognized crates found. Use Scan all or hover a crate first."] = "Aucune caisse reconnue. Analysez tout ou survolez d'abord une caisse.",
    ["Scanning..."] = "Analyse en cours...",
    ["Scan stopped; completed prices were kept."] = "Analyse arrêtée ; prix recueillis conservés.",
    ["Scan stopped because another auction search started. Scan again when the auction house is idle."] = "Analyse arrêtée par une autre recherche. Réessayez quand l'hôtel des ventes est libre.",
    ["Full scan did not complete. Retry when the auction house is idle."] = "Analyse complète inachevée. Réessayez quand l'hôtel des ventes est libre.",
    ["Full scan data could not be read: %s"] = "Impossible de lire les données de l'analyse : %s",
    ["Reading full scan: %d / %d auctions"] = "Lecture de l'analyse : %d / %d enchères",
    ["Wait for the full scan to finish or stop it first."] = "Attendez la fin de l'analyse complète ou arrêtez-la.",
    ["An auction scan is already running."] = "Une analyse des enchères est en cours.",
    ["Full-scan cooldown: using saved prices. /wll scan deep refreshes known delivery items."] = "Analyse complète en recharge : prix mémorisés utilisés. /wll scan deep actualise les biens à livrer connus.",
    ["Requesting one full auction-house snapshot..."] = "Demande des données complètes de l'hôtel des ventes...",
    ["Full scan could not start: %s"] = "Impossible de lancer l'analyse complète : %s",
    ["Full scan returned an invalid auction count."] = "L'analyse a renvoyé un nombre d'enchères invalide.",
    ["No matching writs or crates to scan."] = "Aucune commission ni caisse à analyser.",
    ["Auction-open scan disabled."] = "Analyse à l'ouverture désactivée.",
    ["Automatic refresh disabled."] = "Actualisation automatique désactivée.",
    ["Automatic scan stopped for the selected price source."] = "Analyse automatique arrêtée pour la source de prix choisie.",
    ["Use /wll source auto, auctionator, tsm, or own."] = "Utilisez /wll source auto, auctionator, tsm ou own.",
    ["Use /wll writsource auto, auctionator, tsm, own, or off."] = "Utilisez /wll writsource auto, auctionator, tsm, own ou off.",
    ["Use /wll tsmkey DBMinBuyout or DBMarket."] = "Utilisez /wll tsmkey DBMinBuyout ou DBMarket.",
    ["Hover an identified Waylaid Crate first."] = "Survolez d'abord une caisse détournée identifiée.",
    ["Open the auction house to shop."] = "Ouvrez l'hôtel des ventes pour acheter.",
    ["Choose an option between 1 and %d."] = "Choisissez une option entre 1 et %d.",
    ["Searching all alternatives in Auctionator. Buy only one bundle to fill the crate."] = "Recherche de toutes les options dans Auctionator. N'achetez qu'un seul lot pour remplir la caisse.",
    ["Opened the selected bundle in Auctionator. Review the listings before buying."] = "Lot choisi ouvert dans Auctionator. Vérifiez les offres avant d'acheter.",
    ["Stop the current scan first."] = "Arrêtez d'abord l'analyse en cours.",
    ["Choose Auto or Own scans for this category in Settings."] = "Choisissez Auto ou Mes analyses pour cette catégorie dans les options.",
    ["Price source: %s. Options: auto, auctionator, tsm, own."] = "Source des prix : %s. Options : auto, auctionator, tsm, own.",
    ["Writ source: %s. Options: auto, auctionator, tsm, own, off."] = "Source des commissions : %s. Options : auto, auctionator, tsm, own, off.",
    ["TSM source: %s. Options: DBMinBuyout, DBMarket."] = "Source TSM : %s. Options : DBMinBuyout, DBMarket.",
    ["Use /wll shop [option number]."] = "Utilisez /wll shop [numéro de l'option].",
    ["Use /wll %s on or off, or /wll settings."] = "Utilisez /wll %s on ou off, ou /wll settings.",
    ["Debug logging enabled."] = "Journal de débogage activé.",
    ["Debug logging disabled."] = "Journal de débogage désactivé.",
    ["Stopped to clear this market's prices."] = "Analyse arrêtée pour effacer les prix du marché.",
    ["Cached prices cleared for this market profile."] = "Prix mémorisés effacés pour ce profil de marché.",
    ["Current profile: %s. Change with /wll market <name>."] = "Profil actuel : %s. Modifiez-le avec /wll market <nom>.",
    ["Stopped because the market profile changed."] = "Analyse arrêtée après le changement de profil.",
    ["Market profile: %s. Scan this auction house to populate its prices."] = "Profil de marché : %s. Analysez cet hôtel des ventes pour obtenir les prix.",
    ["Use a profile name of 1-40 letters, digits, underscores or hyphens."] = "Utilisez un nom de profil de 1 à 40 lettres, chiffres, tirets ou traits de soulignement.",
    ["This client has no supported C_AuctionHouse API. Please send its /dump GetBuildInfo() output."] = "Ce client n'a pas d'API C_AuctionHouse compatible. Envoyez le résultat de /dump GetBuildInfo().",
    ["No supported tooltip hook found. Use /wll report to collect diagnostics."] = "Aucun mécanisme d'infobulle compatible. Utilisez /wll report pour le diagnostic.",
    ["Loaded. /wll opens scans, price sources, and shopping."] = "Chargé. /wll ouvre les analyses, les sources de prix et les achats.",
    ["TSM market"] = "TSM marché",
    ["TSM min buyout"] = "TSM achat immédiat min.",
    ["Auctionator's shopping API is unavailable. Install/enable a compatible Auctionator release."] = "L'API d'achat d'Auctionator est indisponible. Installez ou activez une version compatible.",
    ["Auctionator could not convert the search: %s"] = "Auctionator n'a pas pu convertir la recherche : %s",
    ["Auctionator could not start the search: %s"] = "Auctionator n'a pas pu lancer la recherche : %s",
    ["AH full scan"] = "Analyse complète HV",
    ["Own scan"] = "Mon analyse",
    ["Automatic refresh paused after closing the panel."] = "Actualisation automatique suspendue.",
    ["Automatic refresh paused after leaving the list."] = "Actualisation automatique suspendue.",
    ["Automatic refresh paused after leaving the crates list."] = "Actualisation automatique suspendue.",
    ["Automatic refresh paused after changing category."] = "Actualisation automatique suspendue.",
    ["Stopped to open a basket item in the auction house."] = "Analyse arrêtée pour les achats.",
    ["Stopped to open the built-in shopping basket."] = "Analyse arrêtée pour les achats.",
    ["Stopped to hand the search to Auctionator."] = "Analyse arrêtée pour les achats.",
    ["Stopped to hand the complete basket to Auctionator."] = "Analyse arrêtée pour les achats.",
    ["Refresh: Own + Auctionator"] = "Actualiser : moi + Auctionator",
    ["Refresh: Own scan"] = "Actualiser : mon analyse",
    ["Refresh mode"] = "Mode d'actualisation",
    ["TSM group export"] = "Exporter un groupe TSM",
    ["Starting a new scoped refresh."] = "Nouvelle actualisation ciblée.",
    ["Refreshing %d unique items for the current %s list."] = "Actualisation de %d objets distincts de la liste %s.",
    ["Select Auto or Own to display our scan results; the selected provider keeps its own data."] = "Choisissez Auto ou Mes analyses pour afficher nos résultats ; le fournisseur sélectionné conserve ses données.",
    ["No matching items to scan."] = "Aucun objet correspondant à analyser.",
    ["Auctionator scans are disabled for custom market profiles."] = "Les analyses Auctionator sont désactivées pour les profils de marché personnalisés.",
    ["Auctionator's limited-search API is unavailable."] = "L'API de recherche ciblée d'Auctionator est indisponible.",
    ["Handing the limited item search to Auctionator."] = "Transmission de la recherche ciblée à Auctionator.",
    ["Started a limited search in Auctionator Shopping (%d items)."] = "Recherche ciblée lancée dans Auctionator Shopping (%d objets).",
    ["No matching items to export."] = "Aucun objet correspondant à exporter.",
    ["TSM import - copy, import into a group, then run its Shopping scan"] = "Import TSM – copier, importer dans un groupe, puis lancer son analyse Shopping",
    ["Exported %d items. Import into TSM and start its group Shopping scan manually."] = "%d objets exportés. Importez-les dans TSM et lancez manuellement l'analyse Shopping du groupe.",
    ["Item names are loading; retry the Auctionator scan shortly."] = "Chargement des noms d'objets ; réessayez bientôt l'analyse Auctionator.",
    ["Refresh prices for this list. Uses a full AH snapshot when supported; otherwise scans its items."] = "Actualise les prix de cette liste. Utilise les données complètes de l'hôtel des ventes si possible, sinon analyse les objets.",
    ["Full AH scans wait for server readiness; saved prices remain available."] = "Les analyses complètes attendent que le serveur soit prêt ; les prix mémorisés restent disponibles.",
    ["Then open a limited Auctionator Shopping search when available."] = "Ouvre ensuite une recherche ciblée Auctionator Shopping si disponible.",
    ["Own scanner only. Auctionator follow-up is configurable in Settings."] = "Mon analyse uniquement. La recherche Auctionator suivante se règle dans les options.",
}

addon.Locales.esES = {
    ["Auto"] = "Auto",
    ["Own scans"] = "Análisis propios",
    ["Off"] = "Desactivado",
    ["ready"] = "listo",
    ["unavailable"] = "no disponible",
    ["Crate prices and shopping. Green: lowest known filling cost. Click an option to choose a different bundle."] = "Precios y compras de cajones. Verde: menor coste conocido de llenado. Haz clic en una opción para elegir otro lote.",
    ["Scan bags"] = "Analizar bolsas",
    ["Scan hovered"] = "Analizar selección",
    ["Full AH scan"] = "Análisis completo",
    ["Stop scan"] = "Detener análisis",
    ["Copy diagnostics"] = "Copiar diagnóstico",
    ["Settings"] = "Opciones",
    ["Hover a crate"] = "Señala un cajón",
    ["Hover a crate to choose a bundle"] = "Señala un cajón para elegir un lote",
    ["Search all alternatives"] = "Buscar alternativas",
    ["Shop selected option"] = "Comprar lote elegido",
    ["Scan tracked crates"] = "Analizar cajones seguidos",
    ["Inventory snapshots"] = "Inventarios guardados",
    ["Auto refresh scans only missing/stale tracked requirements while this panel is open. Stop pauses it for this auction visit."] = "La actualización automática analiza precios ausentes o antiguos de materiales seguidos mientras este panel está abierto. Detener la pausa durante esta visita.",
    ["Prices: %s (change)"] = "Precios: %s (cambiar)",
    ["TSM: Market value (change)"] = "TSM: valor de mercado",
    ["TSM: Min buyout (change)"] = "TSM: compra mínima",
    ["Reading the auction-house snapshot..."] = "Leyendo datos de la casa de subastas...",
    ["Scanning %d/%d: %s\n%d updated, %d failed. Hover again for updated prices."] = "Analizando %d/%d: %s\n%d actualizados, %d fallidos. Vuelve a señalar para ver los precios.",
    ["Auction house open. Ready to scan."] = "Casa de subastas abierta. Listo para analizar.",
    ["Open an auction house to scan."] = "Abre la casa de subastas para analizar.",
    ["\nProfile: %s; Auctionator: %s; TSM: %s"] = "\nPerfil: %s; Auctionator: %s; TSM: %s",
    ["%s (cycle tracked crates)"] = "%s (cambiar de cajón seguido)",
    [" (scan failed)"] = " (análisis fallido)",
    [" (stale)"] = " (antiguo)",
    ["Option %d/%d: %dx %s%s"] = "Opción %d/%d: %dx %s%s",
    ["Hover an identified crate to choose a bundle."] = "Señala un cajón identificado para elegir un lote.",
    ["Remembered: %d crates, %d characters, %d visited banks.\nBags update on login; bank contents update when visited."] = "Guardados: %d cajones, %d personajes, %d bancos visitados.\nLas bolsas se actualizan al entrar; los bancos, al visitarlos.",
    ["Craftsman's Writs"] = "Libranzas del artesano",
    ["Waylaid Crates"] = "Cajones saqueados",
    ["Waylaid"] = "Entregas",
    ["Writ prices: %s"] = "Libranzas: %s",
    ["Crate prices: %s"] = "Cajones: %s",
    ["TSM price: %s"] = "Precio TSM: %s",
    ["Show minimap button"] = "Mostrar botón del minimapa",
    ["Remember crate and material inventory"] = "Recordar cajones y materiales",
    ["Include visited character and shared banks"] = "Incluir bancos de personaje y compartidos visitados",
    ["Include remembered characters on this realm/faction"] = "Incluir personajes guardados de este reino y facción",
    ["Auto refresh tracked prices in the Crates list"] = "Actualizar precios seguidos en la lista de cajones",
    ["Auto-scan crate prices on auction open (Auto/Own)"] = "Analizar cajones al abrir la subasta (Auto/Propios)",
    ["Always show detailed price tooltips"] = "Mostrar siempre detalles de precios",
    ["Crate prices"] = "Precios de cajones",
    ["Writ prices"] = "Precios de libranzas",
    ["TSM price"] = "Precio TSM",
    ["Scan controls"] = "Controles de análisis",
    ["Clear remembered inventory"] = "Borrar inventarios",
    ["WoW's AddOns settings are unavailable on this client."] = "Las opciones de addons no están disponibles en este cliente.",
    ["Waylaid Ledger - select and copy with Ctrl+C / Cmd+C"] = "Waylaid Ledger: selecciona y copia con Ctrl+C / Cmd+C",
    ["No price"] = "Sin precio",
    ["Purchase + delivery"] = "Compra + entrega",
    ["Purchase (1)"] = "Compra (1)",
    ["Total"] = "Total",
    ["Scanning %d/%d"] = "Analizando %d/%d",
    ["%d priced / %d items"] = "%d con precio / %d objetos",
    ["Refresh"] = "Actualizar",
    ["Refresh list"] = "Actualizar lista",
    ["Refresh saved prices; scan missing or stale prices when providers have no current data."] = "Actualiza precios guardados; analiza los ausentes o antiguos si los proveedores no tienen datos actuales.",
    ["Scan prices"] = "Analizar precios",
    ["Stop"] = "Detener",
    ["Item / delivery goods"] = "Objeto / mercancía",
    ["Purchase"] = "Compra",
    ["Delivery"] = "Entrega",
    ["Total (lowest first)"] = "Total (menor primero)",
    [" (%d owned)"] = " (%d en posesión)",
    ["Not scanned"] = "Sin analizar",
    [" (buy %d)"] = " (comprar %d)",
    ["None listed"] = "Sin anuncios",
    ["Only %d"] = "Solo %d",
    [" failed"] = " fallido",
    ["%dm"] = "%d min",
    ["%dd"] = "%d d",
    [", age unknown"] = ", antigüedad desconocida",
    [", own scan failed"] = ", análisis propio fallido",
    ["Identify this shipment first to compare its filling costs."] = "Identifica este envío para comparar sus costes de llenado.",
    ["Delivery requirements unresolved. Run a full AH scan, then hover this item again."] = "Requisitos sin resolver. Analiza toda la subasta y vuelve a señalar este objeto.",
    ["Waylaid Ledger - delivery estimate"] = "Waylaid Ledger: coste de entrega",
    ["Incomplete prices"] = "Precios incompletos",
    ["Left-click: open | Right-click: settings"] = "Clic izquierdo: abrir | Clic derecho: opciones",
    ["Drag to move around the minimap"] = "Arrastra para mover por el minimapa",
    ["Open the auction house first."] = "Abre primero la casa de subastas.",
    ["Item information is loading. Try again in a moment."] = "Se está cargando el objeto. Inténtalo en un momento.",
    ["Auction searches are throttled. Try again shortly."] = "Las búsquedas están limitadas. Inténtalo en breve.",
    ["Could not open the auction search: %s"] = "No se pudo abrir la búsqueda: %s",
    ["The auction house's buying UI is unavailable."] = "La interfaz de compra no está disponible.",
    ["Waylaid shopping basket"] = "Cesta de entregas",
    ["Compare these alternatives; buy only one bundle."] = "Compara las alternativas y compra un solo lote.",
    ["Open each item and buy the quantity shown. Purchases use the auction house's confirmation."] = "Abre cada objeto y compra la cantidad indicada. Las compras se confirman en la casa de subastas.",
    ["Delivery requirements unresolved. Run a full AH scan."] = "Requisitos sin resolver. Analiza toda la subasta.",
    ["Writ prices are disabled in settings."] = "Los precios de libranzas están desactivados en opciones.",
    ["Scan crate materials or update Auctionator/TSM prices to choose a filling option."] = "Analiza materiales o actualiza precios de Auctionator/TSM para elegir un lote.",
    ["Delivery price unavailable"] = "Precio de entrega no disponible",
    ["Unknown item."] = "Objeto desconocido.",
    ["An item name is still loading. Try the search again in a moment."] = "Se está cargando un nombre de objeto. Repite la búsqueda en un momento.",
    ["Automatic refresh paused."] = "Actualización automática en pausa.",
    ["Scan stopped for shopping."] = "Análisis detenido para comprar.",
    ["Auction house closed; completed prices were kept."] = "Subasta cerrada; se conservaron los precios obtenidos.",
    ["A scan is already running. Stop it before starting another."] = "Ya hay un análisis en curso. Deténlo antes de iniciar otro.",
    ["No recognized crates found. Use Scan all or hover a crate first."] = "No se encontraron cajones conocidos. Analiza todo o señala un cajón primero.",
    ["Scanning..."] = "Analizando...",
    ["Scan stopped; completed prices were kept."] = "Análisis detenido; precios obtenidos conservados.",
    ["Scan stopped because another auction search started. Scan again when the auction house is idle."] = "Análisis detenido por otra búsqueda. Reintenta cuando la subasta esté libre.",
    ["Full scan did not complete. Retry when the auction house is idle."] = "El análisis completo no terminó. Reintenta cuando la subasta esté libre.",
    ["Full scan data could not be read: %s"] = "No se pudieron leer los datos del análisis: %s",
    ["Reading full scan: %d / %d auctions"] = "Leyendo análisis: %d / %d subastas",
    ["Wait for the full scan to finish or stop it first."] = "Espera a que termine el análisis o deténlo primero.",
    ["An auction scan is already running."] = "Ya hay un análisis de subastas en curso.",
    ["Full-scan cooldown: using saved prices. /wll scan deep refreshes known delivery items."] = "Análisis completo en espera: se usan precios guardados. /wll scan deep actualiza mercancías conocidas.",
    ["Requesting one full auction-house snapshot..."] = "Solicitando todos los datos de la subasta...",
    ["Full scan could not start: %s"] = "No se pudo iniciar el análisis completo: %s",
    ["Full scan returned an invalid auction count."] = "El análisis devolvió un número de subastas no válido.",
    ["No matching writs or crates to scan."] = "No hay libranzas ni cajones para analizar.",
    ["Auction-open scan disabled."] = "Análisis al abrir la subasta desactivado.",
    ["Automatic refresh disabled."] = "Actualización automática desactivada.",
    ["Automatic scan stopped for the selected price source."] = "Análisis automático detenido para la fuente elegida.",
    ["Use /wll source auto, auctionator, tsm, or own."] = "Usa /wll source auto, auctionator, tsm u own.",
    ["Use /wll writsource auto, auctionator, tsm, own, or off."] = "Usa /wll writsource auto, auctionator, tsm, own u off.",
    ["Use /wll tsmkey DBMinBuyout or DBMarket."] = "Usa /wll tsmkey DBMinBuyout o DBMarket.",
    ["Hover an identified Waylaid Crate first."] = "Señala primero un cajón identificado.",
    ["Open the auction house to shop."] = "Abre la casa de subastas para comprar.",
    ["Choose an option between 1 and %d."] = "Elige una opción entre 1 y %d.",
    ["Searching all alternatives in Auctionator. Buy only one bundle to fill the crate."] = "Buscando alternativas en Auctionator. Compra un solo lote para llenar el cajón.",
    ["Opened the selected bundle in Auctionator. Review the listings before buying."] = "Lote elegido abierto en Auctionator. Revisa los anuncios antes de comprar.",
    ["Stop the current scan first."] = "Detén primero el análisis actual.",
    ["Choose Auto or Own scans for this category in Settings."] = "Elige Auto o Análisis propios para esta categoría en opciones.",
    ["Price source: %s. Options: auto, auctionator, tsm, own."] = "Fuente de precios: %s. Opciones: auto, auctionator, tsm, own.",
    ["Writ source: %s. Options: auto, auctionator, tsm, own, off."] = "Fuente de libranzas: %s. Opciones: auto, auctionator, tsm, own, off.",
    ["TSM source: %s. Options: DBMinBuyout, DBMarket."] = "Fuente TSM: %s. Opciones: DBMinBuyout, DBMarket.",
    ["Use /wll shop [option number]."] = "Usa /wll shop [número de opción].",
    ["Use /wll %s on or off, or /wll settings."] = "Usa /wll %s on u off, o /wll settings.",
    ["Debug logging enabled."] = "Registro de depuración activado.",
    ["Debug logging disabled."] = "Registro de depuración desactivado.",
    ["Stopped to clear this market's prices."] = "Análisis detenido para borrar precios del mercado.",
    ["Cached prices cleared for this market profile."] = "Precios guardados borrados para este perfil.",
    ["Current profile: %s. Change with /wll market <name>."] = "Perfil actual: %s. Cámbialo con /wll market <nombre>.",
    ["Stopped because the market profile changed."] = "Análisis detenido por cambio de perfil.",
    ["Market profile: %s. Scan this auction house to populate its prices."] = "Perfil de mercado: %s. Analiza esta subasta para obtener precios.",
    ["Use a profile name of 1-40 letters, digits, underscores or hyphens."] = "Usa un nombre de 1 a 40 letras, números, guiones o guiones bajos.",
    ["This client has no supported C_AuctionHouse API. Please send its /dump GetBuildInfo() output."] = "Este cliente no tiene una API C_AuctionHouse compatible. Envía el resultado de /dump GetBuildInfo().",
    ["No supported tooltip hook found. Use /wll report to collect diagnostics."] = "No se encontró un enlace de tooltip compatible. Usa /wll report para el diagnóstico.",
    ["Loaded. /wll opens scans, price sources, and shopping."] = "Cargado. /wll abre análisis, fuentes de precios y compras.",
    ["TSM market"] = "TSM mercado",
    ["TSM min buyout"] = "TSM compra mínima",
    ["Auctionator's shopping API is unavailable. Install/enable a compatible Auctionator release."] = "La API de compra de Auctionator no está disponible. Instala o activa una versión compatible.",
    ["Auctionator could not convert the search: %s"] = "Auctionator no pudo convertir la búsqueda: %s",
    ["Auctionator could not start the search: %s"] = "Auctionator no pudo iniciar la búsqueda: %s",
    ["AH full scan"] = "Análisis completo",
    ["Own scan"] = "Análisis propio",
    ["Automatic refresh paused after closing the panel."] = "Actualización automática en pausa.",
    ["Automatic refresh paused after leaving the list."] = "Actualización automática en pausa.",
    ["Automatic refresh paused after leaving the crates list."] = "Actualización automática en pausa.",
    ["Automatic refresh paused after changing category."] = "Actualización automática en pausa.",
    ["Stopped to open a basket item in the auction house."] = "Análisis detenido para comprar.",
    ["Stopped to open the built-in shopping basket."] = "Análisis detenido para comprar.",
    ["Stopped to hand the search to Auctionator."] = "Análisis detenido para comprar.",
    ["Stopped to hand the complete basket to Auctionator."] = "Análisis detenido para comprar.",
    ["Refresh: Own + Auctionator"] = "Actualizar: propio + Auctionator",
    ["Refresh: Own scan"] = "Actualizar: análisis propio",
    ["Refresh mode"] = "Modo de actualización",
    ["TSM group export"] = "Exportar grupo TSM",
    ["Starting a new scoped refresh."] = "Iniciando actualización del ámbito elegido.",
    ["Refreshing %d unique items for the current %s list."] = "Actualizando %d objetos distintos de la lista %s.",
    ["Select Auto or Own to display our scan results; the selected provider keeps its own data."] = "Elige Auto o Análisis propios para ver nuestros resultados; el proveedor elegido conserva sus datos.",
    ["No matching items to scan."] = "No hay objetos que analizar.",
    ["Auctionator scans are disabled for custom market profiles."] = "Los análisis de Auctionator están desactivados para perfiles personalizados.",
    ["Auctionator's limited-search API is unavailable."] = "La API de búsqueda limitada de Auctionator no está disponible.",
    ["Handing the limited item search to Auctionator."] = "Enviando la búsqueda limitada a Auctionator.",
    ["Started a limited search in Auctionator Shopping (%d items)."] = "Búsqueda limitada iniciada en Auctionator Shopping (%d objetos).",
    ["No matching items to export."] = "No hay objetos que exportar.",
    ["TSM import - copy, import into a group, then run its Shopping scan"] = "Importación TSM: copia, importa a un grupo e inicia su análisis Shopping",
    ["Exported %d items. Import into TSM and start its group Shopping scan manually."] = "%d objetos exportados. Impórtalos en TSM e inicia manualmente el análisis Shopping del grupo.",
    ["Item names are loading; retry the Auctionator scan shortly."] = "Se están cargando nombres; repite el análisis de Auctionator en breve.",
    ["Refresh prices for this list. Uses a full AH snapshot when supported; otherwise scans its items."] = "Actualiza los precios de esta lista. Usa todos los datos de la subasta si se admite; si no, analiza sus objetos.",
    ["Full AH scans wait for server readiness; saved prices remain available."] = "Los análisis completos esperan a que el servidor esté listo; los precios guardados siguen disponibles.",
    ["Then open a limited Auctionator Shopping search when available."] = "Después abre una búsqueda limitada de Auctionator Shopping, si está disponible.",
    ["Own scanner only. Auctionator follow-up is configurable in Settings."] = "Solo análisis propio. El seguimiento de Auctionator se configura en opciones.",
}

addon.Locales.ptBR = {
    ["Auto"] = "Auto",
    ["Own scans"] = "Buscas próprias",
    ["Off"] = "Desativado",
    ["ready"] = "pronto",
    ["unavailable"] = "indisponível",
    ["Crate prices and shopping. Green: lowest known filling cost. Click an option to choose a different bundle."] = "Preços e compras de caixotes. Verde: menor custo conhecido de preenchimento. Clique em uma opção para escolher outro conjunto.",
    ["Scan bags"] = "Buscar nas bolsas",
    ["Scan hovered"] = "Buscar sob o cursor",
    ["Full AH scan"] = "Busca completa",
    ["Stop scan"] = "Parar busca",
    ["Copy diagnostics"] = "Copiar diagnóstico",
    ["Settings"] = "Configurações",
    ["Hover a crate"] = "Passe sobre um caixote",
    ["Hover a crate to choose a bundle"] = "Passe sobre um caixote para escolher um conjunto",
    ["Search all alternatives"] = "Buscar alternativas",
    ["Shop selected option"] = "Comprar opção escolhida",
    ["Scan tracked crates"] = "Buscar caixotes rastreados",
    ["Inventory snapshots"] = "Inventários salvos",
    ["Auto refresh scans only missing/stale tracked requirements while this panel is open. Stop pauses it for this auction visit."] = "A atualização automática busca preços ausentes ou antigos dos materiais rastreados enquanto este painel está aberto. Parar pausa a busca nesta visita.",
    ["Prices: %s (change)"] = "Preços: %s (alterar)",
    ["TSM: Market value (change)"] = "TSM: valor de mercado",
    ["TSM: Min buyout (change)"] = "TSM: arremate mínimo",
    ["Reading the auction-house snapshot..."] = "Lendo dados da casa de leilões...",
    ["Scanning %d/%d: %s\n%d updated, %d failed. Hover again for updated prices."] = "Buscando %d/%d: %s\n%d atualizados, %d falharam. Passe o cursor novamente para ver os preços.",
    ["Auction house open. Ready to scan."] = "Casa de leilões aberta. Pronto para buscar.",
    ["Open an auction house to scan."] = "Abra a casa de leilões para buscar.",
    ["\nProfile: %s; Auctionator: %s; TSM: %s"] = "\nPerfil: %s; Auctionator: %s; TSM: %s",
    ["%s (cycle tracked crates)"] = "%s (alternar caixotes rastreados)",
    [" (scan failed)"] = " (falha na busca)",
    [" (stale)"] = " (antigo)",
    ["Option %d/%d: %dx %s%s"] = "Opção %d/%d: %dx %s%s",
    ["Hover an identified crate to choose a bundle."] = "Passe sobre um caixote identificado para escolher um conjunto.",
    ["Remembered: %d crates, %d characters, %d visited banks.\nBags update on login; bank contents update when visited."] = "Salvos: %d caixotes, %d personagens, %d bancos visitados.\nAs bolsas atualizam ao entrar; os bancos, ao visitá-los.",
    ["Craftsman's Writs"] = "Escrituras do Artífice",
    ["Waylaid Crates"] = "Caixotes Extraviados",
    ["Waylaid"] = "Entregas",
    ["Writ prices: %s"] = "Escrituras: %s",
    ["Crate prices: %s"] = "Caixotes: %s",
    ["TSM price: %s"] = "Preço TSM: %s",
    ["Show minimap button"] = "Mostrar botão do minimapa",
    ["Remember crate and material inventory"] = "Lembrar caixotes e materiais",
    ["Include visited character and shared banks"] = "Incluir bancos visitados do personagem e da conta",
    ["Include remembered characters on this realm/faction"] = "Incluir personagens salvos deste reino e facção",
    ["Auto refresh tracked prices in the Crates list"] = "Atualizar preços rastreados na lista de caixotes",
    ["Auto-scan crate prices on auction open (Auto/Own)"] = "Buscar preços de caixotes ao abrir o leilão (Auto/Próprias)",
    ["Always show detailed price tooltips"] = "Sempre mostrar detalhes dos preços",
    ["Crate prices"] = "Preços de caixotes",
    ["Writ prices"] = "Preços de escrituras",
    ["TSM price"] = "Preço TSM",
    ["Scan controls"] = "Controles de busca",
    ["Clear remembered inventory"] = "Limpar inventários salvos",
    ["WoW's AddOns settings are unavailable on this client."] = "As configurações de addons estão indisponíveis neste cliente.",
    ["Waylaid Ledger - select and copy with Ctrl+C / Cmd+C"] = "Waylaid Ledger: selecione e copie com Ctrl+C / Cmd+C",
    ["No price"] = "Sem preço",
    ["Purchase + delivery"] = "Compra + entrega",
    ["Purchase (1)"] = "Compra (1)",
    ["Total"] = "Total",
    ["Scanning %d/%d"] = "Buscando %d/%d",
    ["%d priced / %d items"] = "%d com preço / %d itens",
    ["Refresh"] = "Atualizar",
    ["Refresh list"] = "Atualizar lista",
    ["Refresh saved prices; scan missing or stale prices when providers have no current data."] = "Atualiza preços salvos; busca preços ausentes ou antigos quando os provedores não têm dados atuais.",
    ["Scan prices"] = "Buscar preços",
    ["Stop"] = "Parar",
    ["Item / delivery goods"] = "Item / mercadorias",
    ["Purchase"] = "Compra",
    ["Delivery"] = "Entrega",
    ["Total (lowest first)"] = "Total (menor primeiro)",
    [" (%d owned)"] = " (%d em posse)",
    ["Not scanned"] = "Não buscado",
    [" (buy %d)"] = " (comprar %d)",
    ["None listed"] = "Nenhuma oferta",
    ["Only %d"] = "Apenas %d",
    [" failed"] = " falhou",
    ["%dm"] = "%d min",
    ["%dd"] = "%d d",
    [", age unknown"] = ", idade desconhecida",
    [", own scan failed"] = ", busca própria falhou",
    ["Identify this shipment first to compare its filling costs."] = "Identifique esta remessa para comparar os custos de preenchimento.",
    ["Delivery requirements unresolved. Run a full AH scan, then hover this item again."] = "Requisitos não resolvidos. Faça uma busca completa do leilão e passe o cursor neste item novamente.",
    ["Waylaid Ledger - delivery estimate"] = "Waylaid Ledger: estimativa de entrega",
    ["Incomplete prices"] = "Preços incompletos",
    ["Left-click: open | Right-click: settings"] = "Clique esquerdo: abrir | Clique direito: configurações",
    ["Drag to move around the minimap"] = "Arraste para mover ao redor do minimapa",
    ["Open the auction house first."] = "Abra a casa de leilões primeiro.",
    ["Item information is loading. Try again in a moment."] = "Carregando dados do item. Tente novamente em instantes.",
    ["Auction searches are throttled. Try again shortly."] = "As buscas foram limitadas. Tente novamente em breve.",
    ["Could not open the auction search: %s"] = "Não foi possível abrir a busca: %s",
    ["The auction house's buying UI is unavailable."] = "A interface de compra do leilão está indisponível.",
    ["Waylaid shopping basket"] = "Cesta de entregas",
    ["Compare these alternatives; buy only one bundle."] = "Compare as alternativas e compre apenas um conjunto.",
    ["Open each item and buy the quantity shown. Purchases use the auction house's confirmation."] = "Abra cada item e compre a quantidade indicada. As compras usam a confirmação da casa de leilões.",
    ["Delivery requirements unresolved. Run a full AH scan."] = "Requisitos não resolvidos. Faça uma busca completa do leilão.",
    ["Writ prices are disabled in settings."] = "Os preços de escrituras estão desativados nas configurações.",
    ["Scan crate materials or update Auctionator/TSM prices to choose a filling option."] = "Busque materiais ou atualize preços do Auctionator/TSM para escolher um conjunto.",
    ["Delivery price unavailable"] = "Preço de entrega indisponível",
    ["Unknown item."] = "Item desconhecido.",
    ["An item name is still loading. Try the search again in a moment."] = "Um nome de item ainda está carregando. Repita a busca em instantes.",
    ["Automatic refresh paused."] = "Atualização automática pausada.",
    ["Scan stopped for shopping."] = "Busca parada para compras.",
    ["Auction house closed; completed prices were kept."] = "Leilão fechado; preços obtidos foram mantidos.",
    ["A scan is already running. Stop it before starting another."] = "Já há uma busca em andamento. Pare-a antes de iniciar outra.",
    ["No recognized crates found. Use Scan all or hover a crate first."] = "Nenhum caixote reconhecido. Faça uma busca completa ou passe sobre um caixote.",
    ["Scanning..."] = "Buscando...",
    ["Scan stopped; completed prices were kept."] = "Busca parada; preços obtidos mantidos.",
    ["Scan stopped because another auction search started. Scan again when the auction house is idle."] = "Busca parada por outra pesquisa. Tente novamente quando o leilão estiver livre.",
    ["Full scan did not complete. Retry when the auction house is idle."] = "A busca completa não terminou. Tente quando o leilão estiver livre.",
    ["Full scan data could not be read: %s"] = "Não foi possível ler os dados da busca: %s",
    ["Reading full scan: %d / %d auctions"] = "Lendo busca: %d / %d leilões",
    ["Wait for the full scan to finish or stop it first."] = "Aguarde a busca completa terminar ou pare-a primeiro.",
    ["An auction scan is already running."] = "Já há uma busca de leilões em andamento.",
    ["Full-scan cooldown: using saved prices. /wll scan deep refreshes known delivery items."] = "Busca completa em recarga: usando preços salvos. /wll scan deep atualiza mercadorias conhecidas.",
    ["Requesting one full auction-house snapshot..."] = "Solicitando todos os dados do leilão...",
    ["Full scan could not start: %s"] = "Não foi possível iniciar a busca completa: %s",
    ["Full scan returned an invalid auction count."] = "A busca retornou uma contagem inválida de leilões.",
    ["No matching writs or crates to scan."] = "Nenhuma escritura ou caixote para buscar.",
    ["Auction-open scan disabled."] = "Busca ao abrir o leilão desativada.",
    ["Automatic refresh disabled."] = "Atualização automática desativada.",
    ["Automatic scan stopped for the selected price source."] = "Busca automática parada para a fonte escolhida.",
    ["Use /wll source auto, auctionator, tsm, or own."] = "Use /wll source auto, auctionator, tsm ou own.",
    ["Use /wll writsource auto, auctionator, tsm, own, or off."] = "Use /wll writsource auto, auctionator, tsm, own ou off.",
    ["Use /wll tsmkey DBMinBuyout or DBMarket."] = "Use /wll tsmkey DBMinBuyout ou DBMarket.",
    ["Hover an identified Waylaid Crate first."] = "Passe primeiro sobre um caixote identificado.",
    ["Open the auction house to shop."] = "Abra a casa de leilões para comprar.",
    ["Choose an option between 1 and %d."] = "Escolha uma opção entre 1 e %d.",
    ["Searching all alternatives in Auctionator. Buy only one bundle to fill the crate."] = "Buscando alternativas no Auctionator. Compre apenas um conjunto para encher o caixote.",
    ["Opened the selected bundle in Auctionator. Review the listings before buying."] = "Conjunto escolhido aberto no Auctionator. Confira as ofertas antes de comprar.",
    ["Stop the current scan first."] = "Pare a busca atual primeiro.",
    ["Choose Auto or Own scans for this category in Settings."] = "Escolha Auto ou Buscas próprias para esta categoria nas configurações.",
    ["Price source: %s. Options: auto, auctionator, tsm, own."] = "Fonte de preços: %s. Opções: auto, auctionator, tsm, own.",
    ["Writ source: %s. Options: auto, auctionator, tsm, own, off."] = "Fonte de escrituras: %s. Opções: auto, auctionator, tsm, own, off.",
    ["TSM source: %s. Options: DBMinBuyout, DBMarket."] = "Fonte TSM: %s. Opções: DBMinBuyout, DBMarket.",
    ["Use /wll shop [option number]."] = "Use /wll shop [número da opção].",
    ["Use /wll %s on or off, or /wll settings."] = "Use /wll %s on ou off, ou /wll settings.",
    ["Debug logging enabled."] = "Registro de depuração ativado.",
    ["Debug logging disabled."] = "Registro de depuração desativado.",
    ["Stopped to clear this market's prices."] = "Busca parada para limpar preços do mercado.",
    ["Cached prices cleared for this market profile."] = "Preços salvos limpos para este perfil.",
    ["Current profile: %s. Change with /wll market <name>."] = "Perfil atual: %s. Altere com /wll market <nome>.",
    ["Stopped because the market profile changed."] = "Busca parada por mudança de perfil.",
    ["Market profile: %s. Scan this auction house to populate its prices."] = "Perfil de mercado: %s. Busque neste leilão para obter preços.",
    ["Use a profile name of 1-40 letters, digits, underscores or hyphens."] = "Use um nome de 1 a 40 letras, números, sublinhados ou hífens.",
    ["This client has no supported C_AuctionHouse API. Please send its /dump GetBuildInfo() output."] = "Este cliente não tem uma API C_AuctionHouse compatível. Envie o resultado de /dump GetBuildInfo().",
    ["No supported tooltip hook found. Use /wll report to collect diagnostics."] = "Nenhum mecanismo de tooltip compatível. Use /wll report para o diagnóstico.",
    ["Loaded. /wll opens scans, price sources, and shopping."] = "Carregado. /wll abre buscas, fontes de preços e compras.",
    ["TSM market"] = "TSM mercado",
    ["TSM min buyout"] = "TSM arremate mínimo",
    ["Auctionator's shopping API is unavailable. Install/enable a compatible Auctionator release."] = "A API de compras do Auctionator está indisponível. Instale ou ative uma versão compatível.",
    ["Auctionator could not convert the search: %s"] = "O Auctionator não conseguiu converter a busca: %s",
    ["Auctionator could not start the search: %s"] = "O Auctionator não conseguiu iniciar a busca: %s",
    ["AH full scan"] = "Busca completa",
    ["Own scan"] = "Busca própria",
    ["Automatic refresh paused after closing the panel."] = "Atualização automática pausada.",
    ["Automatic refresh paused after leaving the list."] = "Atualização automática pausada.",
    ["Automatic refresh paused after leaving the crates list."] = "Atualização automática pausada.",
    ["Automatic refresh paused after changing category."] = "Atualização automática pausada.",
    ["Stopped to open a basket item in the auction house."] = "Busca parada para compras.",
    ["Stopped to open the built-in shopping basket."] = "Busca parada para compras.",
    ["Stopped to hand the search to Auctionator."] = "Busca parada para compras.",
    ["Stopped to hand the complete basket to Auctionator."] = "Busca parada para compras.",
    ["Refresh: Own + Auctionator"] = "Atualizar: própria + Auctionator",
    ["Refresh: Own scan"] = "Atualizar: busca própria",
    ["Refresh mode"] = "Modo de atualização",
    ["TSM group export"] = "Exportar grupo TSM",
    ["Starting a new scoped refresh."] = "Iniciando atualização do escopo escolhido.",
    ["Refreshing %d unique items for the current %s list."] = "Atualizando %d itens distintos da lista %s.",
    ["Select Auto or Own to display our scan results; the selected provider keeps its own data."] = "Escolha Auto ou Buscas próprias para ver nossos resultados; o provedor escolhido mantém seus próprios dados.",
    ["No matching items to scan."] = "Nenhum item para buscar.",
    ["Auctionator scans are disabled for custom market profiles."] = "Buscas do Auctionator estão desativadas para perfis personalizados.",
    ["Auctionator's limited-search API is unavailable."] = "A API de busca limitada do Auctionator está indisponível.",
    ["Handing the limited item search to Auctionator."] = "Enviando a busca limitada ao Auctionator.",
    ["Started a limited search in Auctionator Shopping (%d items)."] = "Busca limitada iniciada no Auctionator Shopping (%d itens).",
    ["No matching items to export."] = "Nenhum item para exportar.",
    ["TSM import - copy, import into a group, then run its Shopping scan"] = "Importação TSM: copie, importe para um grupo e inicie sua busca Shopping",
    ["Exported %d items. Import into TSM and start its group Shopping scan manually."] = "%d itens exportados. Importe no TSM e inicie manualmente a busca Shopping do grupo.",
    ["Item names are loading; retry the Auctionator scan shortly."] = "Carregando nomes de itens; repita a busca do Auctionator em breve.",
    ["Refresh prices for this list. Uses a full AH snapshot when supported; otherwise scans its items."] = "Atualiza preços desta lista. Usa todos os dados do leilão quando disponível; caso contrário, busca seus itens.",
    ["Full AH scans wait for server readiness; saved prices remain available."] = "Buscas completas aguardam o servidor estar pronto; os preços salvos continuam disponíveis.",
    ["Then open a limited Auctionator Shopping search when available."] = "Depois abre uma busca limitada no Auctionator Shopping, se disponível.",
    ["Own scanner only. Auctionator follow-up is configurable in Settings."] = "Apenas busca própria. A busca seguinte do Auctionator é configurável nas configurações.",
}

addon.Locales.ruRU = {
    ["Auto"] = "Авто",
    ["Own scans"] = "Свои сканирования",
    ["Off"] = "Выкл.",
    ["ready"] = "готов",
    ["unavailable"] = "недоступно",
    ["Crate prices and shopping. Green: lowest known filling cost. Click an option to choose a different bundle."] = "Цены ящиков и покупки. Зелёным отмечена самая низкая известная стоимость заполнения. Нажмите вариант, чтобы выбрать другой комплект.",
    ["Scan bags"] = "Сканировать сумки",
    ["Scan hovered"] = "Сканировать выбранное",
    ["Full AH scan"] = "Полное сканирование",
    ["Stop scan"] = "Остановить сканирование",
    ["Copy diagnostics"] = "Копировать диагностику",
    ["Settings"] = "Настройки",
    ["Hover a crate"] = "Наведите на ящик",
    ["Hover a crate to choose a bundle"] = "Наведите на ящик, чтобы выбрать комплект",
    ["Search all alternatives"] = "Искать все варианты",
    ["Shop selected option"] = "Купить выбранный комплект",
    ["Scan tracked crates"] = "Сканировать учтённые ящики",
    ["Inventory snapshots"] = "Сохранённые запасы",
    ["Auto refresh scans only missing/stale tracked requirements while this panel is open. Stop pauses it for this auction visit."] = "Автообновление сканирует отсутствующие или устаревшие цены учтённых материалов, пока панель открыта. Остановка приостанавливает его до следующего посещения аукциона.",
    ["Prices: %s (change)"] = "Цены: %s (изменить)",
    ["TSM: Market value (change)"] = "TSM: рыночная цена",
    ["TSM: Min buyout (change)"] = "TSM: мин. выкуп",
    ["Reading the auction-house snapshot..."] = "Чтение данных аукциона...",
    ["Scanning %d/%d: %s\n%d updated, %d failed. Hover again for updated prices."] = "Сканирование %d/%d: %s\nОбновлено: %d, ошибок: %d. Наведите снова, чтобы увидеть цены.",
    ["Auction house open. Ready to scan."] = "Аукцион открыт. Можно сканировать.",
    ["Open an auction house to scan."] = "Откройте аукцион для сканирования.",
    ["\nProfile: %s; Auctionator: %s; TSM: %s"] = "\nПрофиль: %s; Auctionator: %s; TSM: %s",
    ["%s (cycle tracked crates)"] = "%s (переключить учтённый ящик)",
    [" (scan failed)"] = " (ошибка сканирования)",
    [" (stale)"] = " (устарело)",
    ["Option %d/%d: %dx %s%s"] = "Вариант %d/%d: %d шт. %s%s",
    ["Hover an identified crate to choose a bundle."] = "Наведите на опознанный ящик, чтобы выбрать комплект.",
    ["Remembered: %d crates, %d characters, %d visited banks.\nBags update on login; bank contents update when visited."] = "Сохранено: ящиков — %d, персонажей — %d, банков — %d.\nСумки обновляются при входе, банки — при посещении.",
    ["Craftsman's Writs"] = "Задания мастера",
    ["Waylaid Crates"] = "Перехваченные ящики",
    ["Waylaid"] = "Поставки",
    ["Writ prices: %s"] = "Цены заданий: %s",
    ["Crate prices: %s"] = "Цены ящиков: %s",
    ["TSM price: %s"] = "Цена TSM: %s",
    ["Show minimap button"] = "Показывать кнопку у миникарты",
    ["Remember crate and material inventory"] = "Запоминать запасы ящиков и материалов",
    ["Include visited character and shared banks"] = "Учитывать посещённые личные и общие банки",
    ["Include remembered characters on this realm/faction"] = "Учитывать сохранённых персонажей этого мира и фракции",
    ["Auto refresh tracked prices in the Crates list"] = "Автообновлять учтённые цены в списке ящиков",
    ["Auto-scan crate prices on auction open (Auto/Own)"] = "Сканировать цены ящиков при открытии аукциона (Авто/Свои)",
    ["Always show detailed price tooltips"] = "Всегда показывать подробные подсказки цен",
    ["Crate prices"] = "Цены ящиков",
    ["Writ prices"] = "Цены заданий",
    ["TSM price"] = "Цена TSM",
    ["Scan controls"] = "Управление сканированием",
    ["Clear remembered inventory"] = "Очистить сохранённые запасы",
    ["WoW's AddOns settings are unavailable on this client."] = "Настройки модификаций недоступны в этом клиенте.",
    ["Waylaid Ledger - select and copy with Ctrl+C / Cmd+C"] = "Waylaid Ledger — выделите и скопируйте: Ctrl+C / Cmd+C",
    ["No price"] = "Нет цены",
    ["Purchase + delivery"] = "Покупка + доставка",
    ["Purchase (1)"] = "Покупка (1)",
    ["Total"] = "Итого",
    ["Scanning %d/%d"] = "Сканирование %d/%d",
    ["%d priced / %d items"] = "С ценой: %d / предметов: %d",
    ["Refresh"] = "Обновить",
    ["Refresh list"] = "Обновить список",
    ["Refresh saved prices; scan missing or stale prices when providers have no current data."] = "Обновить сохранённые цены; сканировать отсутствующие или устаревшие цены, если у источников нет свежих данных.",
    ["Scan prices"] = "Сканировать цены",
    ["Stop"] = "Стоп",
    ["Item / delivery goods"] = "Предмет / товары",
    ["Purchase"] = "Покупка",
    ["Delivery"] = "Доставка",
    ["Total (lowest first)"] = "Итого (по возрастанию)",
    [" (%d owned)"] = " (в наличии: %d)",
    ["Not scanned"] = "Не сканировано",
    [" (buy %d)"] = " (купить %d)",
    ["None listed"] = "Нет предложений",
    ["Only %d"] = "Только %d",
    [" failed"] = " ошибка",
    ["%dm"] = "%d мин",
    ["%dd"] = "%d дн.",
    [", age unknown"] = ", давность неизвестна",
    [", own scan failed"] = ", своё сканирование не удалось",
    ["Identify this shipment first to compare its filling costs."] = "Сначала опознайте поставку, чтобы сравнить стоимость заполнения.",
    ["Delivery requirements unresolved. Run a full AH scan, then hover this item again."] = "Требования не определены. Выполните полное сканирование аукциона и снова наведите на предмет.",
    ["Waylaid Ledger - delivery estimate"] = "Waylaid Ledger — стоимость доставки",
    ["Incomplete prices"] = "Неполные цены",
    ["Left-click: open | Right-click: settings"] = "ЛКМ: открыть | ПКМ: настройки",
    ["Drag to move around the minimap"] = "Перетащите для перемещения вокруг миникарты",
    ["Open the auction house first."] = "Сначала откройте аукцион.",
    ["Item information is loading. Try again in a moment."] = "Данные предмета загружаются. Повторите чуть позже.",
    ["Auction searches are throttled. Try again shortly."] = "Частота поиска ограничена. Повторите чуть позже.",
    ["Could not open the auction search: %s"] = "Не удалось открыть поиск на аукционе: %s",
    ["The auction house's buying UI is unavailable."] = "Интерфейс покупки на аукционе недоступен.",
    ["Waylaid shopping basket"] = "Корзина поставки",
    ["Compare these alternatives; buy only one bundle."] = "Сравните варианты; купите только один комплект.",
    ["Open each item and buy the quantity shown. Purchases use the auction house's confirmation."] = "Откройте каждый предмет и купите указанное количество. Покупки подтверждаются в окне аукциона.",
    ["Delivery requirements unresolved. Run a full AH scan."] = "Требования не определены. Выполните полное сканирование аукциона.",
    ["Writ prices are disabled in settings."] = "Цены заданий отключены в настройках.",
    ["Scan crate materials or update Auctionator/TSM prices to choose a filling option."] = "Сканируйте материалы или обновите цены Auctionator/TSM, чтобы выбрать комплект.",
    ["Delivery price unavailable"] = "Цена доставки недоступна",
    ["Unknown item."] = "Неизвестный предмет.",
    ["An item name is still loading. Try the search again in a moment."] = "Название предмета ещё загружается. Повторите поиск чуть позже.",
    ["Automatic refresh paused."] = "Автообновление приостановлено.",
    ["Scan stopped for shopping."] = "Сканирование остановлено для покупок.",
    ["Auction house closed; completed prices were kept."] = "Аукцион закрыт; полученные цены сохранены.",
    ["A scan is already running. Stop it before starting another."] = "Уже идёт сканирование. Остановите его перед запуском другого.",
    ["No recognized crates found. Use Scan all or hover a crate first."] = "Известные ящики не найдены. Запустите полное сканирование или наведите на ящик.",
    ["Scanning..."] = "Сканирование...",
    ["Scan stopped; completed prices were kept."] = "Сканирование остановлено; полученные цены сохранены.",
    ["Scan stopped because another auction search started. Scan again when the auction house is idle."] = "Сканирование остановлено из-за другого поиска. Повторите, когда аукцион освободится.",
    ["Full scan did not complete. Retry when the auction house is idle."] = "Полное сканирование не завершено. Повторите, когда аукцион освободится.",
    ["Full scan data could not be read: %s"] = "Не удалось прочитать данные сканирования: %s",
    ["Reading full scan: %d / %d auctions"] = "Чтение сканирования: %d / %d лотов",
    ["Wait for the full scan to finish or stop it first."] = "Дождитесь завершения полного сканирования или остановите его.",
    ["An auction scan is already running."] = "Уже идёт сканирование аукциона.",
    ["Full-scan cooldown: using saved prices. /wll scan deep refreshes known delivery items."] = "Полное сканирование на перезарядке: используются сохранённые цены. /wll scan deep обновляет известные товары.",
    ["Requesting one full auction-house snapshot..."] = "Запрос полных данных аукциона...",
    ["Full scan could not start: %s"] = "Не удалось начать полное сканирование: %s",
    ["Full scan returned an invalid auction count."] = "Полное сканирование вернуло неверное число лотов.",
    ["No matching writs or crates to scan."] = "Нет подходящих заданий или ящиков для сканирования.",
    ["Auction-open scan disabled."] = "Сканирование при открытии аукциона отключено.",
    ["Automatic refresh disabled."] = "Автообновление отключено.",
    ["Automatic scan stopped for the selected price source."] = "Автосканирование остановлено для выбранного источника цен.",
    ["Use /wll source auto, auctionator, tsm, or own."] = "Используйте /wll source auto, auctionator, tsm или own.",
    ["Use /wll writsource auto, auctionator, tsm, own, or off."] = "Используйте /wll writsource auto, auctionator, tsm, own или off.",
    ["Use /wll tsmkey DBMinBuyout or DBMarket."] = "Используйте /wll tsmkey DBMinBuyout или DBMarket.",
    ["Hover an identified Waylaid Crate first."] = "Сначала наведите на опознанный перехваченный ящик.",
    ["Open the auction house to shop."] = "Откройте аукцион для покупок.",
    ["Choose an option between 1 and %d."] = "Выберите вариант от 1 до %d.",
    ["Searching all alternatives in Auctionator. Buy only one bundle to fill the crate."] = "Поиск всех вариантов в Auctionator. Для заполнения ящика купите только один комплект.",
    ["Opened the selected bundle in Auctionator. Review the listings before buying."] = "Выбранный комплект открыт в Auctionator. Проверьте предложения перед покупкой.",
    ["Stop the current scan first."] = "Сначала остановите текущее сканирование.",
    ["Choose Auto or Own scans for this category in Settings."] = "Выберите Авто или Свои сканирования для этой категории в настройках.",
    ["Price source: %s. Options: auto, auctionator, tsm, own."] = "Источник цен: %s. Варианты: auto, auctionator, tsm, own.",
    ["Writ source: %s. Options: auto, auctionator, tsm, own, off."] = "Источник заданий: %s. Варианты: auto, auctionator, tsm, own, off.",
    ["TSM source: %s. Options: DBMinBuyout, DBMarket."] = "Источник TSM: %s. Варианты: DBMinBuyout, DBMarket.",
    ["Use /wll shop [option number]."] = "Используйте /wll shop [номер варианта].",
    ["Use /wll %s on or off, or /wll settings."] = "Используйте /wll %s on или off либо /wll settings.",
    ["Debug logging enabled."] = "Журнал отладки включён.",
    ["Debug logging disabled."] = "Журнал отладки отключён.",
    ["Stopped to clear this market's prices."] = "Сканирование остановлено для очистки цен рынка.",
    ["Cached prices cleared for this market profile."] = "Сохранённые цены этого профиля рынка удалены.",
    ["Current profile: %s. Change with /wll market <name>."] = "Текущий профиль: %s. Изменить: /wll market <имя>.",
    ["Stopped because the market profile changed."] = "Сканирование остановлено из-за смены профиля рынка.",
    ["Market profile: %s. Scan this auction house to populate its prices."] = "Профиль рынка: %s. Просканируйте этот аукцион для получения цен.",
    ["Use a profile name of 1-40 letters, digits, underscores or hyphens."] = "Имя профиля: 1–40 букв, цифр, знаков подчёркивания или дефисов.",
    ["This client has no supported C_AuctionHouse API. Please send its /dump GetBuildInfo() output."] = "В клиенте нет поддерживаемого API C_AuctionHouse. Пришлите результат /dump GetBuildInfo().",
    ["No supported tooltip hook found. Use /wll report to collect diagnostics."] = "Не найден поддерживаемый обработчик подсказок. Соберите диагностику: /wll report.",
    ["Loaded. /wll opens scans, price sources, and shopping."] = "Загружено. /wll открывает сканирование, источники цен и покупки.",
    ["TSM market"] = "Рынок TSM",
    ["TSM min buyout"] = "Мин. выкуп TSM",
    ["Auctionator's shopping API is unavailable. Install/enable a compatible Auctionator release."] = "API покупок Auctionator недоступен. Установите или включите совместимую версию.",
    ["Auctionator could not convert the search: %s"] = "Auctionator не смог преобразовать поиск: %s",
    ["Auctionator could not start the search: %s"] = "Auctionator не смог начать поиск: %s",
    ["AH full scan"] = "Полный скан аукциона",
    ["Own scan"] = "Своё сканирование",
    ["Automatic refresh paused after closing the panel."] = "Автообновление приостановлено.",
    ["Automatic refresh paused after leaving the list."] = "Автообновление приостановлено.",
    ["Automatic refresh paused after leaving the crates list."] = "Автообновление приостановлено.",
    ["Automatic refresh paused after changing category."] = "Автообновление приостановлено.",
    ["Stopped to open a basket item in the auction house."] = "Сканирование остановлено для покупок.",
    ["Stopped to open the built-in shopping basket."] = "Сканирование остановлено для покупок.",
    ["Stopped to hand the search to Auctionator."] = "Сканирование остановлено для покупок.",
    ["Stopped to hand the complete basket to Auctionator."] = "Сканирование остановлено для покупок.",
    ["Refresh: Own + Auctionator"] = "Обновить: своё + Auctionator",
    ["Refresh: Own scan"] = "Обновить: своё сканирование",
    ["Refresh mode"] = "Режим обновления",
    ["TSM group export"] = "Экспорт группы TSM",
    ["Starting a new scoped refresh."] = "Запуск обновления выбранных предметов.",
    ["Refreshing %d unique items for the current %s list."] = "Обновление %d предметов из списка %s.",
    ["Select Auto or Own to display our scan results; the selected provider keeps its own data."] = "Выберите Авто или Свои сканирования для наших результатов; выбранный источник использует свои данные.",
    ["No matching items to scan."] = "Нет подходящих предметов для сканирования.",
    ["Auctionator scans are disabled for custom market profiles."] = "Сканирования Auctionator отключены для пользовательских профилей рынка.",
    ["Auctionator's limited-search API is unavailable."] = "API ограниченного поиска Auctionator недоступен.",
    ["Handing the limited item search to Auctionator."] = "Передача ограниченного поиска предметов в Auctionator.",
    ["Started a limited search in Auctionator Shopping (%d items)."] = "Запущен ограниченный поиск в Auctionator Shopping (предметов: %d).",
    ["No matching items to export."] = "Нет подходящих предметов для экспорта.",
    ["TSM import - copy, import into a group, then run its Shopping scan"] = "Импорт TSM — скопируйте, импортируйте в группу и запустите поиск Shopping",
    ["Exported %d items. Import into TSM and start its group Shopping scan manually."] = "Экспортировано предметов: %d. Импортируйте в TSM и вручную запустите поиск Shopping группы.",
    ["Item names are loading; retry the Auctionator scan shortly."] = "Названия предметов загружаются; повторите сканирование Auctionator чуть позже.",
    ["Refresh prices for this list. Uses a full AH snapshot when supported; otherwise scans its items."] = "Обновить цены списка. При поддержке используются полные данные аукциона, иначе сканируются предметы.",
    ["Full AH scans wait for server readiness; saved prices remain available."] = "Полные сканирования ждут готовности сервера; сохранённые цены остаются доступны.",
    ["Then open a limited Auctionator Shopping search when available."] = "Затем открыть ограниченный поиск Auctionator Shopping, если доступен.",
    ["Own scanner only. Auctionator follow-up is configurable in Settings."] = "Только своё сканирование. Последующий поиск Auctionator настраивается в настройках.",
}

addon.Locales.koKR = {
    ["Auto"] = "자동",
    ["Own scans"] = "자체 검색",
    ["Off"] = "사용 안 함",
    ["ready"] = "준비됨",
    ["unavailable"] = "사용 불가",
    ["Crate prices and shopping. Green: lowest known filling cost. Click an option to choose a different bundle."] = "상자 가격과 구매입니다. 녹색은 확인된 최저 채우기 비용입니다. 다른 묶음을 선택하려면 항목을 누르세요.",
    ["Scan bags"] = "가방 검색",
    ["Scan hovered"] = "가리킨 상자 검색",
    ["Full AH scan"] = "경매장 전체 검색",
    ["Stop scan"] = "검색 중지",
    ["Copy diagnostics"] = "진단 정보 복사",
    ["Settings"] = "설정",
    ["Hover a crate"] = "상자에 커서 올리기",
    ["Hover a crate to choose a bundle"] = "상자에 커서를 올려 묶음을 선택하세요",
    ["Search all alternatives"] = "모든 대안 검색",
    ["Shop selected option"] = "선택한 묶음 구매",
    ["Scan tracked crates"] = "추적 중인 상자 검색",
    ["Inventory snapshots"] = "저장된 소지품",
    ["Auto refresh scans only missing/stale tracked requirements while this panel is open. Stop pauses it for this auction visit."] = "이 창이 열려 있는 동안 추적 중인 재료의 없거나 오래된 가격만 자동으로 검색합니다. 중지하면 이번 경매장 방문 동안 일시 중지됩니다.",
    ["Prices: %s (change)"] = "가격: %s (변경)",
    ["TSM: Market value (change)"] = "TSM: 시장가 (변경)",
    ["TSM: Min buyout (change)"] = "TSM: 최저 즉시 구매가",
    ["Reading the auction-house snapshot..."] = "경매장 데이터를 읽는 중...",
    ["Scanning %d/%d: %s\n%d updated, %d failed. Hover again for updated prices."] = "검색 중 %d/%d: %s\n%d개 갱신, %d개 실패. 커서를 다시 올려 가격을 확인하세요.",
    ["Auction house open. Ready to scan."] = "경매장이 열렸습니다. 검색할 수 있습니다.",
    ["Open an auction house to scan."] = "검색하려면 경매장을 여세요.",
    ["\nProfile: %s; Auctionator: %s; TSM: %s"] = "\n프로필: %s; Auctionator: %s; TSM: %s",
    ["%s (cycle tracked crates)"] = "%s (추적 상자 전환)",
    [" (scan failed)"] = " (검색 실패)",
    [" (stale)"] = " (오래됨)",
    ["Option %d/%d: %dx %s%s"] = "선택 %d/%d: %d개 %s%s",
    ["Hover an identified crate to choose a bundle."] = "확인된 상자에 커서를 올려 묶음을 선택하세요.",
    ["Remembered: %d crates, %d characters, %d visited banks.\nBags update on login; bank contents update when visited."] = "저장됨: 상자 %d개, 캐릭터 %d명, 방문한 은행 %d개.\n가방은 접속 시, 은행은 방문 시 갱신됩니다.",
    ["Craftsman's Writs"] = "장인의 계약서",
    ["Waylaid Crates"] = "잘못 놓인 보급품",
    ["Waylaid"] = "보급품",
    ["Writ prices: %s"] = "계약서 가격: %s",
    ["Crate prices: %s"] = "상자 가격: %s",
    ["TSM price: %s"] = "TSM 가격: %s",
    ["Show minimap button"] = "미니맵 버튼 표시",
    ["Remember crate and material inventory"] = "상자와 재료 소지품 저장",
    ["Include visited character and shared banks"] = "방문한 캐릭터 및 공유 은행 포함",
    ["Include remembered characters on this realm/faction"] = "이 서버와 진영의 저장된 캐릭터 포함",
    ["Auto refresh tracked prices in the Crates list"] = "상자 목록에서 추적 가격 자동 갱신",
    ["Auto-scan crate prices on auction open (Auto/Own)"] = "경매장 열 때 상자 가격 자동 검색 (자동/자체)",
    ["Always show detailed price tooltips"] = "가격 상세 툴팁 항상 표시",
    ["Crate prices"] = "상자 가격",
    ["Writ prices"] = "계약서 가격",
    ["TSM price"] = "TSM 가격",
    ["Scan controls"] = "검색 제어",
    ["Clear remembered inventory"] = "저장된 소지품 지우기",
    ["WoW's AddOns settings are unavailable on this client."] = "이 클라이언트에서는 애드온 설정을 사용할 수 없습니다.",
    ["Waylaid Ledger - select and copy with Ctrl+C / Cmd+C"] = "Waylaid Ledger - 선택 후 Ctrl+C / Cmd+C로 복사",
    ["No price"] = "가격 없음",
    ["Purchase + delivery"] = "구매 + 납품",
    ["Purchase (1)"] = "구매 (1개)",
    ["Total"] = "합계",
    ["Scanning %d/%d"] = "검색 중 %d/%d",
    ["%d priced / %d items"] = "가격 확인 %d개 / 총 %d개",
    ["Refresh"] = "새로고침",
    ["Refresh list"] = "목록 새로고침",
    ["Refresh saved prices; scan missing or stale prices when providers have no current data."] = "저장된 가격을 갱신합니다. 제공자에게 최신 데이터가 없으면 없거나 오래된 가격을 검색합니다.",
    ["Scan prices"] = "가격 검색",
    ["Stop"] = "중지",
    ["Item / delivery goods"] = "아이템 / 납품 물품",
    ["Purchase"] = "구매",
    ["Delivery"] = "납품",
    ["Total (lowest first)"] = "합계 (낮은 순)",
    [" (%d owned)"] = " (보유 %d개)",
    ["Not scanned"] = "검색 안 됨",
    [" (buy %d)"] = " (%d개 구매)",
    ["None listed"] = "등록 물품 없음",
    ["Only %d"] = "%d개만 있음",
    [" failed"] = " 실패",
    ["%dm"] = "%d분",
    ["%dd"] = "%d일",
    [", age unknown"] = ", 갱신 시점 알 수 없음",
    [", own scan failed"] = ", 자체 검색 실패",
    ["Identify this shipment first to compare its filling costs."] = "먼저 보급품을 확인한 뒤 채우기 비용을 비교하세요.",
    ["Delivery requirements unresolved. Run a full AH scan, then hover this item again."] = "납품 요구 사항을 확인하지 못했습니다. 경매장 전체 검색 후 이 아이템에 다시 커서를 올리세요.",
    ["Waylaid Ledger - delivery estimate"] = "Waylaid Ledger - 납품 예상 비용",
    ["Incomplete prices"] = "가격 정보 부족",
    ["Left-click: open | Right-click: settings"] = "왼쪽 클릭: 열기 | 오른쪽 클릭: 설정",
    ["Drag to move around the minimap"] = "드래그하여 미니맵 주위로 이동",
    ["Open the auction house first."] = "먼저 경매장을 여세요.",
    ["Item information is loading. Try again in a moment."] = "아이템 정보를 불러오는 중입니다. 잠시 후 다시 시도하세요.",
    ["Auction searches are throttled. Try again shortly."] = "경매 검색이 제한되었습니다. 잠시 후 다시 시도하세요.",
    ["Could not open the auction search: %s"] = "경매 검색을 열 수 없습니다: %s",
    ["The auction house's buying UI is unavailable."] = "경매장 구매 화면을 사용할 수 없습니다.",
    ["Waylaid shopping basket"] = "보급품 장바구니",
    ["Compare these alternatives; buy only one bundle."] = "대안을 비교하고 묶음 하나만 구매하세요.",
    ["Open each item and buy the quantity shown. Purchases use the auction house's confirmation."] = "각 아이템을 열고 표시된 수량을 구매하세요. 경매장의 구매 확인 절차를 사용합니다.",
    ["Delivery requirements unresolved. Run a full AH scan."] = "납품 요구 사항을 확인하지 못했습니다. 경매장 전체 검색을 실행하세요.",
    ["Writ prices are disabled in settings."] = "설정에서 계약서 가격이 꺼져 있습니다.",
    ["Scan crate materials or update Auctionator/TSM prices to choose a filling option."] = "상자 재료를 검색하거나 Auctionator/TSM 가격을 갱신해 묶음을 선택하세요.",
    ["Delivery price unavailable"] = "납품 가격 없음",
    ["Unknown item."] = "알 수 없는 아이템입니다.",
    ["An item name is still loading. Try the search again in a moment."] = "아이템 이름을 불러오는 중입니다. 잠시 후 다시 검색하세요.",
    ["Automatic refresh paused."] = "자동 갱신이 일시 중지되었습니다.",
    ["Scan stopped for shopping."] = "구매를 위해 검색을 중지했습니다.",
    ["Auction house closed; completed prices were kept."] = "경매장이 닫혔습니다. 확인한 가격은 저장되었습니다.",
    ["A scan is already running. Stop it before starting another."] = "이미 검색 중입니다. 새 검색을 시작하려면 먼저 중지하세요.",
    ["No recognized crates found. Use Scan all or hover a crate first."] = "인식된 상자가 없습니다. 전체 검색을 실행하거나 상자에 커서를 올리세요.",
    ["Scanning..."] = "검색 중...",
    ["Scan stopped; completed prices were kept."] = "검색을 중지했습니다. 확인한 가격은 저장되었습니다.",
    ["Scan stopped because another auction search started. Scan again when the auction house is idle."] = "다른 경매 검색이 시작되어 중지했습니다. 경매장이 사용 중이 아닐 때 다시 검색하세요.",
    ["Full scan did not complete. Retry when the auction house is idle."] = "전체 검색이 완료되지 않았습니다. 경매장이 사용 중이 아닐 때 다시 시도하세요.",
    ["Full scan data could not be read: %s"] = "전체 검색 데이터를 읽을 수 없습니다: %s",
    ["Reading full scan: %d / %d auctions"] = "전체 검색 읽는 중: 경매 %d / %d개",
    ["Wait for the full scan to finish or stop it first."] = "전체 검색이 끝날 때까지 기다리거나 먼저 중지하세요.",
    ["An auction scan is already running."] = "이미 경매 검색 중입니다.",
    ["Full-scan cooldown: using saved prices. /wll scan deep refreshes known delivery items."] = "전체 검색 대기 시간 중: 저장된 가격을 사용합니다. /wll scan deep으로 알려진 납품 물품을 갱신할 수 있습니다.",
    ["Requesting one full auction-house snapshot..."] = "경매장 전체 데이터를 요청하는 중...",
    ["Full scan could not start: %s"] = "전체 검색을 시작할 수 없습니다: %s",
    ["Full scan returned an invalid auction count."] = "전체 검색에서 잘못된 경매 수가 반환되었습니다.",
    ["No matching writs or crates to scan."] = "검색할 계약서나 상자가 없습니다.",
    ["Auction-open scan disabled."] = "경매장 열 때 자동 검색이 꺼졌습니다.",
    ["Automatic refresh disabled."] = "자동 갱신이 꺼졌습니다.",
    ["Automatic scan stopped for the selected price source."] = "선택한 가격 출처의 자동 검색을 중지했습니다.",
    ["Use /wll source auto, auctionator, tsm, or own."] = "/wll source auto, auctionator, tsm 또는 own을 사용하세요.",
    ["Use /wll writsource auto, auctionator, tsm, own, or off."] = "/wll writsource auto, auctionator, tsm, own 또는 off를 사용하세요.",
    ["Use /wll tsmkey DBMinBuyout or DBMarket."] = "/wll tsmkey DBMinBuyout 또는 DBMarket을 사용하세요.",
    ["Hover an identified Waylaid Crate first."] = "먼저 확인된 보급품 상자에 커서를 올리세요.",
    ["Open the auction house to shop."] = "구매하려면 경매장을 여세요.",
    ["Choose an option between 1 and %d."] = "1부터 %d 사이의 항목을 선택하세요.",
    ["Searching all alternatives in Auctionator. Buy only one bundle to fill the crate."] = "Auctionator에서 모든 대안을 검색합니다. 상자를 채울 묶음 하나만 구매하세요.",
    ["Opened the selected bundle in Auctionator. Review the listings before buying."] = "선택한 묶음을 Auctionator에서 열었습니다. 구매 전 목록을 확인하세요.",
    ["Stop the current scan first."] = "먼저 현재 검색을 중지하세요.",
    ["Choose Auto or Own scans for this category in Settings."] = "설정에서 이 분류의 가격 출처를 자동 또는 자체 검색으로 선택하세요.",
    ["Price source: %s. Options: auto, auctionator, tsm, own."] = "가격 출처: %s. 선택: auto, auctionator, tsm, own.",
    ["Writ source: %s. Options: auto, auctionator, tsm, own, off."] = "계약서 가격 출처: %s. 선택: auto, auctionator, tsm, own, off.",
    ["TSM source: %s. Options: DBMinBuyout, DBMarket."] = "TSM 출처: %s. 선택: DBMinBuyout, DBMarket.",
    ["Use /wll shop [option number]."] = "/wll shop [선택 번호]를 사용하세요.",
    ["Use /wll %s on or off, or /wll settings."] = "/wll %s on 또는 off, 혹은 /wll settings를 사용하세요.",
    ["Debug logging enabled."] = "디버그 기록을 켰습니다.",
    ["Debug logging disabled."] = "디버그 기록을 껐습니다.",
    ["Stopped to clear this market's prices."] = "시장 가격을 지우기 위해 검색을 중지했습니다.",
    ["Cached prices cleared for this market profile."] = "이 시장 프로필의 저장된 가격을 지웠습니다.",
    ["Current profile: %s. Change with /wll market <name>."] = "현재 프로필: %s. /wll market <이름>으로 변경하세요.",
    ["Stopped because the market profile changed."] = "시장 프로필이 변경되어 검색을 중지했습니다.",
    ["Market profile: %s. Scan this auction house to populate its prices."] = "시장 프로필: %s. 이 경매장을 검색해 가격을 채우세요.",
    ["Use a profile name of 1-40 letters, digits, underscores or hyphens."] = "프로필 이름은 영문자, 숫자, 밑줄, 하이픈 1~40자로 입력하세요.",
    ["This client has no supported C_AuctionHouse API. Please send its /dump GetBuildInfo() output."] = "지원되는 C_AuctionHouse API가 없습니다. /dump GetBuildInfo() 결과를 보내 주세요.",
    ["No supported tooltip hook found. Use /wll report to collect diagnostics."] = "지원되는 툴팁 연결을 찾지 못했습니다. /wll report로 진단 정보를 수집하세요.",
    ["Loaded. /wll opens scans, price sources, and shopping."] = "불러왔습니다. /wll로 검색, 가격 출처, 구매를 여세요.",
    ["TSM market"] = "TSM 시장가",
    ["TSM min buyout"] = "TSM 최저 즉시 구매가",
    ["Auctionator's shopping API is unavailable. Install/enable a compatible Auctionator release."] = "Auctionator 구매 API를 사용할 수 없습니다. 호환 버전을 설치하거나 켜세요.",
    ["Auctionator could not convert the search: %s"] = "Auctionator가 검색을 변환하지 못했습니다: %s",
    ["Auctionator could not start the search: %s"] = "Auctionator가 검색을 시작하지 못했습니다: %s",
    ["AH full scan"] = "경매장 전체 검색",
    ["Own scan"] = "자체 검색",
    ["Automatic refresh paused after closing the panel."] = "자동 갱신이 일시 중지되었습니다.",
    ["Automatic refresh paused after leaving the list."] = "자동 갱신이 일시 중지되었습니다.",
    ["Automatic refresh paused after leaving the crates list."] = "자동 갱신이 일시 중지되었습니다.",
    ["Automatic refresh paused after changing category."] = "자동 갱신이 일시 중지되었습니다.",
    ["Stopped to open a basket item in the auction house."] = "구매를 위해 검색을 중지했습니다.",
    ["Stopped to open the built-in shopping basket."] = "구매를 위해 검색을 중지했습니다.",
    ["Stopped to hand the search to Auctionator."] = "구매를 위해 검색을 중지했습니다.",
    ["Stopped to hand the complete basket to Auctionator."] = "구매를 위해 검색을 중지했습니다.",
    ["Refresh: Own + Auctionator"] = "갱신: 자체 + Auctionator",
    ["Refresh: Own scan"] = "갱신: 자체 검색",
    ["Refresh mode"] = "갱신 방식",
    ["TSM group export"] = "TSM 그룹 내보내기",
    ["Starting a new scoped refresh."] = "선택 범위의 새 갱신을 시작합니다.",
    ["Refreshing %d unique items for the current %s list."] = "고유 아이템 %d개 갱신 중, 목록: %s.",
    ["Select Auto or Own to display our scan results; the selected provider keeps its own data."] = "자체 검색 결과를 보려면 자동 또는 자체 검색을 선택하세요. 선택한 제공자는 자체 데이터를 유지합니다.",
    ["No matching items to scan."] = "검색할 아이템이 없습니다.",
    ["Auctionator scans are disabled for custom market profiles."] = "사용자 지정 시장 프로필에서는 Auctionator 검색이 꺼져 있습니다.",
    ["Auctionator's limited-search API is unavailable."] = "Auctionator의 범위 검색 API를 사용할 수 없습니다.",
    ["Handing the limited item search to Auctionator."] = "범위 아이템 검색을 Auctionator에 전달합니다.",
    ["Started a limited search in Auctionator Shopping (%d items)."] = "Auctionator Shopping에서 범위 검색을 시작했습니다 (아이템 %d개).",
    ["No matching items to export."] = "내보낼 아이템이 없습니다.",
    ["TSM import - copy, import into a group, then run its Shopping scan"] = "TSM 가져오기 - 복사하여 그룹으로 가져온 후 Shopping 검색 실행",
    ["Exported %d items. Import into TSM and start its group Shopping scan manually."] = "아이템 %d개를 내보냈습니다. TSM으로 가져온 뒤 그룹의 Shopping 검색을 직접 실행하세요.",
    ["Item names are loading; retry the Auctionator scan shortly."] = "아이템 이름을 불러오는 중입니다. 잠시 후 Auctionator 검색을 다시 시도하세요.",
    ["Refresh prices for this list. Uses a full AH snapshot when supported; otherwise scans its items."] = "이 목록의 가격을 갱신합니다. 지원되는 경우 경매장 전체 데이터를 사용하고, 아니면 아이템을 개별 검색합니다.",
    ["Full AH scans wait for server readiness; saved prices remain available."] = "전체 검색은 서버가 준비될 때까지 기다립니다. 저장된 가격은 계속 사용할 수 있습니다.",
    ["Then open a limited Auctionator Shopping search when available."] = "가능하면 이어서 Auctionator Shopping 범위 검색을 엽니다.",
    ["Own scanner only. Auctionator follow-up is configurable in Settings."] = "자체 검색만 사용합니다. 설정에서 후속 Auctionator 검색을 바꿀 수 있습니다.",
}

addon.Locales.zhTW = {
    ["Auto"] = "自動",
    ["Own scans"] = "自行掃描",
    ["Off"] = "停用",
    ["ready"] = "就緒",
    ["unavailable"] = "無法使用",
    ["Crate prices and shopping. Green: lowest known filling cost. Click an option to choose a different bundle."] = "木箱價格與購物。綠色表示已知最低裝填費用。點選選項以選擇其他物品組合。",
    ["Scan bags"] = "掃描背包",
    ["Scan hovered"] = "掃描指向物品",
    ["Full AH scan"] = "完整掃描拍賣場",
    ["Stop scan"] = "停止掃描",
    ["Copy diagnostics"] = "複製診斷資訊",
    ["Settings"] = "設定",
    ["Hover a crate"] = "將游標移至木箱",
    ["Hover a crate to choose a bundle"] = "將游標移至木箱以選擇物品組合",
    ["Search all alternatives"] = "搜尋所有替代選項",
    ["Shop selected option"] = "購買所選組合",
    ["Scan tracked crates"] = "掃描追蹤中的木箱",
    ["Inventory snapshots"] = "已儲存的物品清單",
    ["Auto refresh scans only missing/stale tracked requirements while this panel is open. Stop pauses it for this auction visit."] = "此面板開啟時，自動更新只會掃描追蹤材料中缺少或過期的價格。停止後，本次拍賣場停留期間將暫停更新。",
    ["Prices: %s (change)"] = "價格：%s（變更）",
    ["TSM: Market value (change)"] = "TSM：市價（變更）",
    ["TSM: Min buyout (change)"] = "TSM：最低直購價（變更）",
    ["Reading the auction-house snapshot..."] = "正在讀取拍賣場資料…",
    ["Scanning %d/%d: %s\n%d updated, %d failed. Hover again for updated prices."] = "掃描中 %d/%d：%s\n已更新 %d 項，失敗 %d 項。再次移入游標以查看價格。",
    ["Auction house open. Ready to scan."] = "拍賣場已開啟，可以開始掃描。",
    ["Open an auction house to scan."] = "開啟拍賣場以進行掃描。",
    ["\nProfile: %s; Auctionator: %s; TSM: %s"] = "\n設定檔：%s；Auctionator：%s；TSM：%s",
    ["%s (cycle tracked crates)"] = "%s（切換追蹤木箱）",
    [" (scan failed)"] = "（掃描失敗）",
    [" (stale)"] = "（已過期）",
    ["Option %d/%d: %dx %s%s"] = "選項 %d/%d：%d 個 %s%s",
    ["Hover an identified crate to choose a bundle."] = "將游標移至已辨識的木箱以選擇物品組合。",
    ["Remembered: %d crates, %d characters, %d visited banks.\nBags update on login; bank contents update when visited."] = "已記錄：%d 個木箱、%d 個角色、%d 個已造訪銀行。\n背包於登入時更新，銀行於造訪時更新。",
    ["Craftsman's Writs"] = "工匠令狀",
    ["Waylaid Crates"] = "遭攔截的木箱",
    ["Waylaid"] = "物資",
    ["Writ prices: %s"] = "令狀價格：%s",
    ["Crate prices: %s"] = "木箱價格：%s",
    ["TSM price: %s"] = "TSM 價格：%s",
    ["Show minimap button"] = "顯示小地圖按鈕",
    ["Remember crate and material inventory"] = "記錄木箱與材料數量",
    ["Include visited character and shared banks"] = "包含已造訪的角色與共用銀行",
    ["Include remembered characters on this realm/faction"] = "包含此伺服器與陣營已記錄的角色",
    ["Auto refresh tracked prices in the Crates list"] = "自動更新木箱清單中追蹤的價格",
    ["Auto-scan crate prices on auction open (Auto/Own)"] = "開啟拍賣場時自動掃描木箱價格（自動／自行掃描）",
    ["Always show detailed price tooltips"] = "一律顯示詳細價格提示",
    ["Crate prices"] = "木箱價格",
    ["Writ prices"] = "令狀價格",
    ["TSM price"] = "TSM 價格",
    ["Scan controls"] = "掃描控制",
    ["Clear remembered inventory"] = "清除已記錄的物品清單",
    ["WoW's AddOns settings are unavailable on this client."] = "此用戶端無法使用插件設定。",
    ["Waylaid Ledger - select and copy with Ctrl+C / Cmd+C"] = "Waylaid Ledger－選取後按 Ctrl+C / Cmd+C 複製",
    ["No price"] = "無價格",
    ["Purchase + delivery"] = "購買＋交付",
    ["Purchase (1)"] = "購買（1 個）",
    ["Total"] = "總計",
    ["Scanning %d/%d"] = "掃描中 %d/%d",
    ["%d priced / %d items"] = "%d 項有價格／共 %d 項物品",
    ["Refresh"] = "更新",
    ["Refresh list"] = "更新清單",
    ["Refresh saved prices; scan missing or stale prices when providers have no current data."] = "更新已儲存的價格。來源沒有最新資料時，掃描缺少或過期的價格。",
    ["Scan prices"] = "掃描價格",
    ["Stop"] = "停止",
    ["Item / delivery goods"] = "物品／交付材料",
    ["Purchase"] = "購買",
    ["Delivery"] = "交付",
    ["Total (lowest first)"] = "總計（由低至高）",
    [" (%d owned)"] = "（持有 %d 個）",
    ["Not scanned"] = "尚未掃描",
    [" (buy %d)"] = "（購買 %d 個）",
    ["None listed"] = "無拍賣物品",
    ["Only %d"] = "僅有 %d 個",
    [" failed"] = " 失敗",
    ["%dm"] = "%d 分鐘",
    ["%dd"] = "%d 天",
    [", age unknown"] = "，資料時間不明",
    [", own scan failed"] = "，自行掃描失敗",
    ["Identify this shipment first to compare its filling costs."] = "請先辨識此批物資，再比較裝填費用。",
    ["Delivery requirements unresolved. Run a full AH scan, then hover this item again."] = "尚未確認交付需求。請完整掃描拍賣場後，再將游標移至此物品。",
    ["Waylaid Ledger - delivery estimate"] = "Waylaid Ledger－交付費用估算",
    ["Incomplete prices"] = "價格資料不完整",
    ["Left-click: open | Right-click: settings"] = "左鍵：開啟 | 右鍵：設定",
    ["Drag to move around the minimap"] = "拖曳以沿小地圖移動",
    ["Open the auction house first."] = "請先開啟拍賣場。",
    ["Item information is loading. Try again in a moment."] = "正在載入物品資訊，請稍後再試。",
    ["Auction searches are throttled. Try again shortly."] = "拍賣搜尋受到頻率限制，請稍後再試。",
    ["Could not open the auction search: %s"] = "無法開啟拍賣搜尋：%s",
    ["The auction house's buying UI is unavailable."] = "無法使用拍賣場購買介面。",
    ["Waylaid shopping basket"] = "物資購物清單",
    ["Compare these alternatives; buy only one bundle."] = "比較各替代選項，只需購買一組。",
    ["Open each item and buy the quantity shown. Purchases use the auction house's confirmation."] = "開啟各物品並購買顯示的數量。購買時須經過拍賣場確認。",
    ["Delivery requirements unresolved. Run a full AH scan."] = "尚未確認交付需求，請完整掃描拍賣場。",
    ["Writ prices are disabled in settings."] = "設定中已停用令狀價格。",
    ["Scan crate materials or update Auctionator/TSM prices to choose a filling option."] = "掃描木箱材料或更新 Auctionator／TSM 價格，以選擇裝填組合。",
    ["Delivery price unavailable"] = "無交付價格",
    ["Unknown item."] = "未知物品。",
    ["An item name is still loading. Try the search again in a moment."] = "仍在載入物品名稱，請稍後再次搜尋。",
    ["Automatic refresh paused."] = "自動更新已暫停。",
    ["Scan stopped for shopping."] = "已停止掃描以進行購物。",
    ["Auction house closed; completed prices were kept."] = "拍賣場已關閉，已完成的價格資料已保留。",
    ["A scan is already running. Stop it before starting another."] = "已有掃描正在進行，請先停止再開始另一項掃描。",
    ["No recognized crates found. Use Scan all or hover a crate first."] = "找不到已辨識的木箱。請完整掃描或先將游標移至木箱。",
    ["Scanning..."] = "掃描中…",
    ["Scan stopped; completed prices were kept."] = "掃描已停止，已完成的價格資料已保留。",
    ["Scan stopped because another auction search started. Scan again when the auction house is idle."] = "已因另一項拍賣搜尋而停止掃描。請在拍賣場閒置時重試。",
    ["Full scan did not complete. Retry when the auction house is idle."] = "完整掃描未完成，請在拍賣場閒置時重試。",
    ["Full scan data could not be read: %s"] = "無法讀取完整掃描資料：%s",
    ["Reading full scan: %d / %d auctions"] = "讀取完整掃描：%d／%d 筆拍賣",
    ["Wait for the full scan to finish or stop it first."] = "請等待完整掃描結束，或先將其停止。",
    ["An auction scan is already running."] = "拍賣掃描已在進行中。",
    ["Full-scan cooldown: using saved prices. /wll scan deep refreshes known delivery items."] = "完整掃描冷卻中，使用已儲存的價格。/wll scan deep 可更新已知交付物品。",
    ["Requesting one full auction-house snapshot..."] = "正在要求完整拍賣場資料…",
    ["Full scan could not start: %s"] = "無法開始完整掃描：%s",
    ["Full scan returned an invalid auction count."] = "完整掃描傳回的拍賣數量無效。",
    ["No matching writs or crates to scan."] = "沒有可掃描的相符令狀或木箱。",
    ["Auction-open scan disabled."] = "已停用開啟拍賣場時的掃描。",
    ["Automatic refresh disabled."] = "已停用自動更新。",
    ["Automatic scan stopped for the selected price source."] = "已停止所選價格來源的自動掃描。",
    ["Use /wll source auto, auctionator, tsm, or own."] = "請使用 /wll source auto、auctionator、tsm 或 own。",
    ["Use /wll writsource auto, auctionator, tsm, own, or off."] = "請使用 /wll writsource auto、auctionator、tsm、own 或 off。",
    ["Use /wll tsmkey DBMinBuyout or DBMarket."] = "請使用 /wll tsmkey DBMinBuyout 或 DBMarket。",
    ["Hover an identified Waylaid Crate first."] = "請先將游標移至已辨識的遭攔截木箱。",
    ["Open the auction house to shop."] = "請開啟拍賣場以購物。",
    ["Choose an option between 1 and %d."] = "請選擇 1 至 %d 之間的選項。",
    ["Searching all alternatives in Auctionator. Buy only one bundle to fill the crate."] = "正在 Auctionator 搜尋所有替代選項。只需購買一組以裝滿木箱。",
    ["Opened the selected bundle in Auctionator. Review the listings before buying."] = "已在 Auctionator 開啟所選組合。購買前請確認拍賣清單。",
    ["Stop the current scan first."] = "請先停止目前的掃描。",
    ["Choose Auto or Own scans for this category in Settings."] = "請在設定中將此分類設為自動或自行掃描。",
    ["Price source: %s. Options: auto, auctionator, tsm, own."] = "價格來源：%s。選項：auto、auctionator、tsm、own。",
    ["Writ source: %s. Options: auto, auctionator, tsm, own, off."] = "令狀價格來源：%s。選項：auto、auctionator、tsm、own、off。",
    ["TSM source: %s. Options: DBMinBuyout, DBMarket."] = "TSM 來源：%s。選項：DBMinBuyout、DBMarket。",
    ["Use /wll shop [option number]."] = "請使用 /wll shop [選項編號]。",
    ["Use /wll %s on or off, or /wll settings."] = "請使用 /wll %s on 或 off，或 /wll settings。",
    ["Debug logging enabled."] = "已啟用偵錯記錄。",
    ["Debug logging disabled."] = "已停用偵錯記錄。",
    ["Stopped to clear this market's prices."] = "已停止掃描以清除此市場價格。",
    ["Cached prices cleared for this market profile."] = "已清除此市場設定檔的快取價格。",
    ["Current profile: %s. Change with /wll market <name>."] = "目前設定檔：%s。使用 /wll market <名稱> 變更。",
    ["Stopped because the market profile changed."] = "市場設定檔已變更，因此停止掃描。",
    ["Market profile: %s. Scan this auction house to populate its prices."] = "市場設定檔：%s。請掃描此拍賣場以取得價格。",
    ["Use a profile name of 1-40 letters, digits, underscores or hyphens."] = "設定檔名稱須為 1 至 40 個英文字母、數字、底線或連字號。",
    ["This client has no supported C_AuctionHouse API. Please send its /dump GetBuildInfo() output."] = "此用戶端沒有支援的 C_AuctionHouse API。請提供 /dump GetBuildInfo() 的輸出。",
    ["No supported tooltip hook found. Use /wll report to collect diagnostics."] = "找不到支援的提示處理方式。請使用 /wll report 收集診斷資訊。",
    ["Loaded. /wll opens scans, price sources, and shopping."] = "已載入。/wll 可開啟掃描、價格來源與購物。",
    ["TSM market"] = "TSM 市價",
    ["TSM min buyout"] = "TSM 最低直購價",
    ["Auctionator's shopping API is unavailable. Install/enable a compatible Auctionator release."] = "無法使用 Auctionator 購物 API。請安裝或啟用相容版本。",
    ["Auctionator could not convert the search: %s"] = "Auctionator 無法轉換搜尋：%s",
    ["Auctionator could not start the search: %s"] = "Auctionator 無法開始搜尋：%s",
    ["AH full scan"] = "拍賣場完整掃描",
    ["Own scan"] = "自行掃描",
    ["Automatic refresh paused after closing the panel."] = "自動更新已暫停。",
    ["Automatic refresh paused after leaving the list."] = "自動更新已暫停。",
    ["Automatic refresh paused after leaving the crates list."] = "自動更新已暫停。",
    ["Automatic refresh paused after changing category."] = "自動更新已暫停。",
    ["Stopped to open a basket item in the auction house."] = "已停止掃描以進行購物。",
    ["Stopped to open the built-in shopping basket."] = "已停止掃描以進行購物。",
    ["Stopped to hand the search to Auctionator."] = "已停止掃描以進行購物。",
    ["Stopped to hand the complete basket to Auctionator."] = "已停止掃描以進行購物。",
    ["Refresh: Own + Auctionator"] = "更新：自行＋Auctionator",
    ["Refresh: Own scan"] = "更新：自行掃描",
    ["Refresh mode"] = "更新模式",
    ["TSM group export"] = "匯出 TSM 群組",
    ["Starting a new scoped refresh."] = "正在開始更新所選範圍。",
    ["Refreshing %d unique items for the current %s list."] = "正在更新 %d 項不同物品，清單：%s。",
    ["Select Auto or Own to display our scan results; the selected provider keeps its own data."] = "選擇自動或自行掃描以顯示掃描結果；所選來源會保留自己的資料。",
    ["No matching items to scan."] = "沒有可掃描的相符物品。",
    ["Auctionator scans are disabled for custom market profiles."] = "自訂市場設定檔無法使用 Auctionator 掃描。",
    ["Auctionator's limited-search API is unavailable."] = "無法使用 Auctionator 範圍搜尋 API。",
    ["Handing the limited item search to Auctionator."] = "正在將所選物品的搜尋交給 Auctionator。",
    ["Started a limited search in Auctionator Shopping (%d items)."] = "已在 Auctionator Shopping 開始範圍搜尋（%d 項物品）。",
    ["No matching items to export."] = "沒有可匯出的相符物品。",
    ["TSM import - copy, import into a group, then run its Shopping scan"] = "TSM 匯入－複製並匯入群組，再執行該群組的 Shopping 掃描",
    ["Exported %d items. Import into TSM and start its group Shopping scan manually."] = "已匯出 %d 項物品。請匯入 TSM 並手動執行群組 Shopping 掃描。",
    ["Item names are loading; retry the Auctionator scan shortly."] = "正在載入物品名稱，請稍後重試 Auctionator 掃描。",
    ["Refresh prices for this list. Uses a full AH snapshot when supported; otherwise scans its items."] = "更新此清單的價格。支援時使用完整拍賣場資料，否則逐項掃描物品。",
    ["Full AH scans wait for server readiness; saved prices remain available."] = "完整掃描會等待伺服器就緒；已儲存的價格仍可使用。",
    ["Then open a limited Auctionator Shopping search when available."] = "可用時接著開啟 Auctionator Shopping 範圍搜尋。",
    ["Own scanner only. Auctionator follow-up is configurable in Settings."] = "僅自行掃描。可在設定中調整後續 Auctionator 搜尋。",
}

-- Both Spanish client variants share control wording, with their own crate name.
addon.Locales.esMX = setmetatable({ ["Waylaid Crates"] = "Cajones arrebatados" }, { __index = addon.Locales.esES })

-- Simplified settings and snapshot status (0.7.2).

addon.Locales.deDE["Prices"] = "Preise"
addon.Locales.deDE["Display"] = "Anzeige"
addon.Locales.deDE["Automatic scans"] = "Automatische Scans"
addon.Locales.deDE["Inventory"] = "Inventar"
addon.Locales.deDE["Tools"] = "Werkzeuge"
addon.Locales.deDE["Minimum buyout"] = "Minimaler Sofortkauf"
addon.Locales.deDE["Market value"] = "Marktwert"
addon.Locales.deDE["Auto uses own scans and optional providers. Forced sources use only that provider."] =
    "Auto nutzt eigene Scans und optionale Preisanbieter. Eine feste Quelle nutzt nur diesen Anbieter."
addon.Locales.deDE["Choose a price source for writ purchases and deliveries."] =
    "Preisquelle für den Kauf und die Lieferung von Aufträgen wählen."
addon.Locales.deDE["Applies to both lists when TSM supplies prices."] =
    "Gilt für beide Listen, wenn TSM Preise liefert."
addon.Locales.deDE["Left-click opens the auction list at the AH, or settings elsewhere."] =
    "Linksklick öffnet im Auktionshaus die Liste, andernorts die Einstellungen."
addon.Locales.deDE["Hold Shift for details when disabled."] = "Wenn deaktiviert, Shift für Details halten."
addon.Locales.deDE["Scan on auction-house open"] = "Beim Öffnen des Auktionshauses scannen"
addon.Locales.deDE["Auto and Own scan missing prices in the open list."] =
    "Auto und Eigene Scans suchen fehlende Preise in der geöffneten Liste."
addon.Locales.deDE["Remember inventory"] = "Inventar speichern"
addon.Locales.deDE["Include visited banks"] = "Besuchte Banken einbeziehen"
addon.Locales.deDE["Include remembered characters"] = "Gespeicherte Charaktere einbeziehen"
addon.Locales.deDE["Auctions %d/%d"] = "Auktionen %d/%d"
addon.Locales.deDE["Items %d/%d"] = "Artikel %d/%d"
addon.Locales.deDE["Finishing full scan"] = "Vollscan wird abgeschlossen"
addon.Locales.deDE["Full scan: waiting"] = "Vollscan: Warten"
addon.Locales.deDE["Shared scan: waiting"] = "Geteilter Scan: Warten"
addon.Locales.deDE["Left-click: auction list"] = "Linksklick: Auktionsliste"
addon.Locales.deDE["Right-click: settings"] = "Rechtsklick: Einstellungen"
addon.Locales.deDE["Refresh prices"] = "Preise aktualisieren"
addon.Locales.deDE["Stop Waylaid's scan or snapshot processing; keep saved prices. Other addons' scans continue."] =
    "Waylaid-Scan oder Datenverarbeitung stoppen; gespeicherte Preise behalten. Scans anderer Addons laufen weiter."
addon.Locales.deDE["Request one full auction-house snapshot to update both lists. The search filter only changes the displayed rows."] =
    "Einen vollständigen Auktionshaus-Datensatz für beide Listen anfordern. Der Suchfilter ändert nur die angezeigten Zeilen."
addon.Locales.deDE["Scan purchases and delivery goods for the filtered list."] =
    "Kauf- und Lieferwaren der gefilterten Liste scannen."

addon.Locales.frFR["Prices"] = "Prix"
addon.Locales.frFR["Display"] = "Affichage"
addon.Locales.frFR["Automatic scans"] = "Analyses automatiques"
addon.Locales.frFR["Inventory"] = "Inventaire"
addon.Locales.frFR["Tools"] = "Outils"
addon.Locales.frFR["Minimum buyout"] = "Achat immédiat minimal"
addon.Locales.frFR["Market value"] = "Valeur du marché"
addon.Locales.frFR["Auto uses own scans and optional providers. Forced sources use only that provider."] =
    "Auto utilise vos analyses et les sources facultatives. Une source imposée utilise uniquement ce fournisseur."
addon.Locales.frFR["Choose a price source for writ purchases and deliveries."] =
    "Choisissez une source de prix pour les achats et livraisons de commandes."
addon.Locales.frFR["Applies to both lists when TSM supplies prices."] =
    "S’applique aux deux listes lorsque TSM fournit les prix."
addon.Locales.frFR["Left-click opens the auction list at the AH, or settings elsewhere."] =
    "Un clic gauche ouvre la liste à l’hôtel des ventes, ou les options ailleurs."
addon.Locales.frFR["Hold Shift for details when disabled."] = "Si désactivé, maintenez Maj pour les détails."
addon.Locales.frFR["Scan on auction-house open"] = "Analyser à l’ouverture des enchères"
addon.Locales.frFR["Auto and Own scan missing prices in the open list."] =
    "Auto et Mes analyses recherchent les prix manquants dans la liste ouverte."
addon.Locales.frFR["Remember inventory"] = "Mémoriser l’inventaire"
addon.Locales.frFR["Include visited banks"] = "Inclure les banques visitées"
addon.Locales.frFR["Include remembered characters"] = "Inclure les personnages mémorisés"
addon.Locales.frFR["Auctions %d/%d"] = "Enchères %d/%d"
addon.Locales.frFR["Items %d/%d"] = "Objets %d/%d"
addon.Locales.frFR["Finishing full scan"] = "Fin de l’analyse complète"
addon.Locales.frFR["Full scan: waiting"] = "Analyse complète : attente"
addon.Locales.frFR["Shared scan: waiting"] = "Analyse partagée : attente"
addon.Locales.frFR["Left-click: auction list"] = "Clic gauche : liste des enchères"
addon.Locales.frFR["Right-click: settings"] = "Clic droit : options"
addon.Locales.frFR["Refresh prices"] = "Actualiser les prix"
addon.Locales.frFR["Stop Waylaid's scan or snapshot processing; keep saved prices. Other addons' scans continue."] =
    "Arrête l’analyse ou le traitement de Waylaid et conserve les prix enregistrés. Les autres addons continuent leurs analyses."
addon.Locales.frFR["Request one full auction-house snapshot to update both lists. The search filter only changes the displayed rows."] =
    "Demande un instantané complet des enchères pour les deux listes. Le filtre ne change que les lignes affichées."
addon.Locales.frFR["Scan purchases and delivery goods for the filtered list."] =
    "Analyse les achats et livraisons de la liste filtrée."

addon.Locales.esES["Prices"] = "Precios"
addon.Locales.esES["Display"] = "Aspecto"
addon.Locales.esES["Automatic scans"] = "Análisis automáticos"
addon.Locales.esES["Inventory"] = "Inventario"
addon.Locales.esES["Tools"] = "Herramientas"
addon.Locales.esES["Minimum buyout"] = "Compra mínima"
addon.Locales.esES["Market value"] = "Valor de mercado"
addon.Locales.esES["Auto uses own scans and optional providers. Forced sources use only that provider."] =
    "Auto usa análisis propios y proveedores opcionales. Una fuente fija usa solo ese proveedor."
addon.Locales.esES["Choose a price source for writ purchases and deliveries."] =
    "Elige la fuente de precios para comprar y completar encargos."
addon.Locales.esES["Applies to both lists when TSM supplies prices."] =
    "Se aplica a ambas listas cuando TSM proporciona los precios."
addon.Locales.esES["Left-click opens the auction list at the AH, or settings elsewhere."] =
    "Clic izquierdo abre la lista en la subasta, o las opciones fuera de ella."
addon.Locales.esES["Hold Shift for details when disabled."] =
    "Si está desactivado, mantén Mayús para ver los detalles."
addon.Locales.esES["Scan on auction-house open"] = "Analizar al abrir la subasta"
addon.Locales.esES["Auto and Own scan missing prices in the open list."] =
    "Auto y Análisis propios buscan precios ausentes en la lista abierta."
addon.Locales.esES["Remember inventory"] = "Recordar inventario"
addon.Locales.esES["Include visited banks"] = "Incluir bancos visitados"
addon.Locales.esES["Include remembered characters"] = "Incluir personajes registrados"
addon.Locales.esES["Auctions %d/%d"] = "Subastas %d/%d"
addon.Locales.esES["Items %d/%d"] = "Objetos %d/%d"
addon.Locales.esES["Finishing full scan"] = "Finalizando análisis completo"
addon.Locales.esES["Full scan: waiting"] = "Análisis completo: esperando"
addon.Locales.esES["Shared scan: waiting"] = "Análisis compartido: esperando"
addon.Locales.esES["Left-click: auction list"] = "Clic izquierdo: lista de subastas"
addon.Locales.esES["Right-click: settings"] = "Clic derecho: opciones"
addon.Locales.esES["Refresh prices"] = "Actualizar precios"
addon.Locales.esES["Stop Waylaid's scan or snapshot processing; keep saved prices. Other addons' scans continue."] =
    "Detiene el análisis o procesamiento de Waylaid y conserva precios guardados. Los demás addons siguen analizando."
addon.Locales.esES["Request one full auction-house snapshot to update both lists. The search filter only changes the displayed rows."] =
    "Solicita una instantánea completa de la subasta para ambas listas. El filtro solo cambia las filas mostradas."
addon.Locales.esES["Scan purchases and delivery goods for the filtered list."] =
    "Analiza compras y entregas de la lista filtrada."

addon.Locales.ptBR["Prices"] = "Preços"
addon.Locales.ptBR["Display"] = "Exibição"
addon.Locales.ptBR["Automatic scans"] = "Buscas automáticas"
addon.Locales.ptBR["Inventory"] = "Inventário"
addon.Locales.ptBR["Tools"] = "Ferramentas"
addon.Locales.ptBR["Minimum buyout"] = "Compra imediata mínima"
addon.Locales.ptBR["Market value"] = "Valor de mercado"
addon.Locales.ptBR["Auto uses own scans and optional providers. Forced sources use only that provider."] =
    "Auto usa buscas próprias e provedores opcionais. Uma fonte fixa usa apenas esse provedor."
addon.Locales.ptBR["Choose a price source for writ purchases and deliveries."] =
    "Escolha a fonte de preços para compras e entregas de encomendas."
addon.Locales.ptBR["Applies to both lists when TSM supplies prices."] =
    "Aplica-se às duas listas quando o TSM fornece os preços."
addon.Locales.ptBR["Left-click opens the auction list at the AH, or settings elsewhere."] =
    "Clique esquerdo abre a lista na casa de leilões, ou as configurações fora dela."
addon.Locales.ptBR["Hold Shift for details when disabled."] = "Quando desativado, segure Shift para ver detalhes."
addon.Locales.ptBR["Scan on auction-house open"] = "Buscar ao abrir a casa de leilões"
addon.Locales.ptBR["Auto and Own scan missing prices in the open list."] =
    "Auto e Buscas próprias buscam preços ausentes na lista aberta."
addon.Locales.ptBR["Remember inventory"] = "Lembrar inventário"
addon.Locales.ptBR["Include visited banks"] = "Incluir bancos visitados"
addon.Locales.ptBR["Include remembered characters"] = "Incluir personagens registrados"
addon.Locales.ptBR["Auctions %d/%d"] = "Leilões %d/%d"
addon.Locales.ptBR["Items %d/%d"] = "Itens %d/%d"
addon.Locales.ptBR["Finishing full scan"] = "Concluindo busca completa"
addon.Locales.ptBR["Full scan: waiting"] = "Busca completa: aguardando"
addon.Locales.ptBR["Shared scan: waiting"] = "Busca compartilhada: aguardando"
addon.Locales.ptBR["Left-click: auction list"] = "Clique esquerdo: lista de leilões"
addon.Locales.ptBR["Right-click: settings"] = "Clique direito: configurações"
addon.Locales.ptBR["Refresh prices"] = "Atualizar preços"
addon.Locales.ptBR["Stop Waylaid's scan or snapshot processing; keep saved prices. Other addons' scans continue."] =
    "Para a busca ou o processamento do Waylaid e mantém os preços salvos. As buscas de outros addons continuam."
addon.Locales.ptBR["Request one full auction-house snapshot to update both lists. The search filter only changes the displayed rows."] =
    "Solicita uma captura completa da casa de leilões para as duas listas. O filtro altera apenas as linhas exibidas."
addon.Locales.ptBR["Scan purchases and delivery goods for the filtered list."] =
    "Busca compras e itens de entrega da lista filtrada."

addon.Locales.ruRU["Prices"] = "Цены"
addon.Locales.ruRU["Display"] = "Отображение"
addon.Locales.ruRU["Automatic scans"] = "Автосканирование"
addon.Locales.ruRU["Inventory"] = "Инвентарь"
addon.Locales.ruRU["Tools"] = "Инструменты"
addon.Locales.ruRU["Minimum buyout"] = "Минимальный выкуп"
addon.Locales.ruRU["Market value"] = "Рыночная стоимость"
addon.Locales.ruRU["Auto uses own scans and optional providers. Forced sources use only that provider."] =
    "Авто использует свои сканирования и дополнительные источники. Выбранный источник используется без подмены."
addon.Locales.ruRU["Choose a price source for writ purchases and deliveries."] =
    "Выберите источник цен для покупки и выполнения заказов."
addon.Locales.ruRU["Applies to both lists when TSM supplies prices."] =
    "Применяется к обоим спискам, когда цены предоставляет TSM."
addon.Locales.ruRU["Left-click opens the auction list at the AH, or settings elsewhere."] =
    "Левая кнопка открывает список на аукционе или настройки вне аукциона."
addon.Locales.ruRU["Hold Shift for details when disabled."] =
    "Если отключено, удерживайте Shift для подробностей."
addon.Locales.ruRU["Scan on auction-house open"] = "Сканировать при открытии аукциона"
addon.Locales.ruRU["Auto and Own scan missing prices in the open list."] =
    "Авто и Свои сканирования ищут отсутствующие цены в открытом списке."
addon.Locales.ruRU["Remember inventory"] = "Запоминать инвентарь"
addon.Locales.ruRU["Include visited banks"] = "Учитывать посещённые банки"
addon.Locales.ruRU["Include remembered characters"] = "Учитывать сохранённых персонажей"
addon.Locales.ruRU["Auctions %d/%d"] = "Лоты %d/%d"
addon.Locales.ruRU["Items %d/%d"] = "Предметы %d/%d"
addon.Locales.ruRU["Finishing full scan"] = "Завершение полного сканирования"
addon.Locales.ruRU["Full scan: waiting"] = "Полное сканирование: ожидание"
addon.Locales.ruRU["Shared scan: waiting"] = "Общее сканирование: ожидание"
addon.Locales.ruRU["Left-click: auction list"] = "Левая кнопка: список аукциона"
addon.Locales.ruRU["Right-click: settings"] = "Правая кнопка: настройки"
addon.Locales.ruRU["Refresh prices"] = "Обновить цены"
addon.Locales.ruRU["Stop Waylaid's scan or snapshot processing; keep saved prices. Other addons' scans continue."] =
    "Останавливает сканирование или обработку Waylaid, сохраняя цены. Сканирования других аддонов продолжаются."
addon.Locales.ruRU["Request one full auction-house snapshot to update both lists. The search filter only changes the displayed rows."] =
    "Запрашивает полный снимок аукциона для обоих списков. Фильтр меняет только отображаемые строки."
addon.Locales.ruRU["Scan purchases and delivery goods for the filtered list."] =
    "Сканирует покупки и товары для доставки из отфильтрованного списка."

addon.Locales.koKR["Prices"] = "가격"
addon.Locales.koKR["Display"] = "표시"
addon.Locales.koKR["Automatic scans"] = "자동 검색"
addon.Locales.koKR["Inventory"] = "소지품"
addon.Locales.koKR["Tools"] = "도구"
addon.Locales.koKR["Minimum buyout"] = "최저 즉시 구매가"
addon.Locales.koKR["Market value"] = "시장 가치"
addon.Locales.koKR["Auto uses own scans and optional providers. Forced sources use only that provider."] =
    "자동은 자체 검색과 선택적 가격 제공자를 사용합니다. 지정한 출처는 해당 제공자만 사용합니다."
addon.Locales.koKR["Choose a price source for writ purchases and deliveries."] =
    "주문서 구매 및 납품 가격의 출처를 선택합니다."
addon.Locales.koKR["Applies to both lists when TSM supplies prices."] =
    "TSM이 가격을 제공할 때 두 목록 모두에 적용됩니다."
addon.Locales.koKR["Left-click opens the auction list at the AH, or settings elsewhere."] =
    "경매장에서는 왼쪽 클릭으로 목록을, 그 외에는 설정을 엽니다."
addon.Locales.koKR["Hold Shift for details when disabled."] =
    "비활성화 시 Shift를 누르면 자세한 정보를 표시합니다."
addon.Locales.koKR["Scan on auction-house open"] = "경매장을 열 때 검색"
addon.Locales.koKR["Auto and Own scan missing prices in the open list."] =
    "자동과 자체 검색은 열린 목록에서 없는 가격을 검색합니다."
addon.Locales.koKR["Remember inventory"] = "소지품 기록"
addon.Locales.koKR["Include visited banks"] = "방문한 은행 포함"
addon.Locales.koKR["Include remembered characters"] = "기록된 캐릭터 포함"
addon.Locales.koKR["Auctions %d/%d"] = "경매 %d/%d"
addon.Locales.koKR["Items %d/%d"] = "물품 %d/%d"
addon.Locales.koKR["Finishing full scan"] = "전체 검색 마무리 중"
addon.Locales.koKR["Full scan: waiting"] = "전체 검색: 대기 중"
addon.Locales.koKR["Shared scan: waiting"] = "공유 검색: 대기 중"
addon.Locales.koKR["Left-click: auction list"] = "왼쪽 클릭: 경매 목록"
addon.Locales.koKR["Right-click: settings"] = "오른쪽 클릭: 설정"
addon.Locales.koKR["Refresh prices"] = "가격 새로고침"
addon.Locales.koKR["Stop Waylaid's scan or snapshot processing; keep saved prices. Other addons' scans continue."] =
    "Waylaid의 검색 또는 스냅샷 처리를 중지하고 저장된 가격을 유지합니다. 다른 애드온의 검색은 계속됩니다."
addon.Locales.koKR["Request one full auction-house snapshot to update both lists. The search filter only changes the displayed rows."] =
    "두 목록을 갱신할 전체 경매장 스냅샷을 요청합니다. 검색 필터는 표시되는 행만 변경합니다."
addon.Locales.koKR["Scan purchases and delivery goods for the filtered list."] =
    "필터링한 목록의 구매 및 납품 물품을 검색합니다."

addon.Locales.zhTW["Prices"] = "價格"
addon.Locales.zhTW["Display"] = "顯示"
addon.Locales.zhTW["Automatic scans"] = "自動掃描"
addon.Locales.zhTW["Inventory"] = "物品欄"
addon.Locales.zhTW["Tools"] = "工具"
addon.Locales.zhTW["Minimum buyout"] = "最低直購價"
addon.Locales.zhTW["Market value"] = "市場價值"
addon.Locales.zhTW["Auto uses own scans and optional providers. Forced sources use only that provider."] =
    "自動會使用自行掃描與可選的價格來源。指定來源時只使用該來源。"
addon.Locales.zhTW["Choose a price source for writ purchases and deliveries."] =
    "選擇委託書購買與交付物品的價格來源。"
addon.Locales.zhTW["Applies to both lists when TSM supplies prices."] = "TSM 提供價格時會套用至兩個清單。"
addon.Locales.zhTW["Left-click opens the auction list at the AH, or settings elsewhere."] =
    "左鍵在拍賣場開啟清單，在其他地方開啟設定。"
addon.Locales.zhTW["Hold Shift for details when disabled."] = "停用時按住 Shift 查看詳細資訊。"
addon.Locales.zhTW["Scan on auction-house open"] = "開啟拍賣場時掃描"
addon.Locales.zhTW["Auto and Own scan missing prices in the open list."] =
    "自動與自行掃描會搜尋目前清單中缺少的價格。"
addon.Locales.zhTW["Remember inventory"] = "記錄物品欄"
addon.Locales.zhTW["Include visited banks"] = "包含已造訪的銀行"
addon.Locales.zhTW["Include remembered characters"] = "包含已記錄的角色"
addon.Locales.zhTW["Auctions %d/%d"] = "拍賣 %d/%d"
addon.Locales.zhTW["Items %d/%d"] = "物品 %d/%d"
addon.Locales.zhTW["Finishing full scan"] = "正在完成完整掃描"
addon.Locales.zhTW["Full scan: waiting"] = "完整掃描：等待中"
addon.Locales.zhTW["Shared scan: waiting"] = "共用掃描：等待中"
addon.Locales.zhTW["Left-click: auction list"] = "左鍵：拍賣清單"
addon.Locales.zhTW["Right-click: settings"] = "右鍵：設定"
addon.Locales.zhTW["Refresh prices"] = "重新整理價格"
addon.Locales.zhTW["Stop Waylaid's scan or snapshot processing; keep saved prices. Other addons' scans continue."] =
    "停止 Waylaid 掃描或快照處理並保留已儲存的價格。其他插件的掃描會繼續。"
addon.Locales.zhTW["Request one full auction-house snapshot to update both lists. The search filter only changes the displayed rows."] =
    "要求完整拍賣場快照以更新兩個清單。搜尋篩選只會改變顯示的列。"
addon.Locales.zhTW["Scan purchases and delivery goods for the filtered list."] =
    "掃描篩選清單中的購買與交付物品。"
addon.Locales.esMX["Prices"] = addon.Locales.esES["Prices"]
addon.Locales.esMX["Display"] = addon.Locales.esES["Display"]
addon.Locales.esMX["Automatic scans"] = addon.Locales.esES["Automatic scans"]
addon.Locales.esMX["Inventory"] = addon.Locales.esES["Inventory"]
addon.Locales.esMX["Tools"] = addon.Locales.esES["Tools"]
addon.Locales.esMX["Minimum buyout"] = addon.Locales.esES["Minimum buyout"]
addon.Locales.esMX["Market value"] = addon.Locales.esES["Market value"]
addon.Locales.esMX["Auto uses own scans and optional providers. Forced sources use only that provider."] =
    addon.Locales.esES["Auto uses own scans and optional providers. Forced sources use only that provider."]
addon.Locales.esMX["Choose a price source for writ purchases and deliveries."] =
    addon.Locales.esES["Choose a price source for writ purchases and deliveries."]
addon.Locales.esMX["Applies to both lists when TSM supplies prices."] =
    addon.Locales.esES["Applies to both lists when TSM supplies prices."]
addon.Locales.esMX["Left-click opens the auction list at the AH, or settings elsewhere."] =
    addon.Locales.esES["Left-click opens the auction list at the AH, or settings elsewhere."]
addon.Locales.esMX["Hold Shift for details when disabled."] =
    addon.Locales.esES["Hold Shift for details when disabled."]
addon.Locales.esMX["Scan on auction-house open"] = addon.Locales.esES["Scan on auction-house open"]
addon.Locales.esMX["Auto and Own scan missing prices in the open list."] =
    addon.Locales.esES["Auto and Own scan missing prices in the open list."]
addon.Locales.esMX["Remember inventory"] = addon.Locales.esES["Remember inventory"]
addon.Locales.esMX["Include visited banks"] = addon.Locales.esES["Include visited banks"]
addon.Locales.esMX["Include remembered characters"] = addon.Locales.esES["Include remembered characters"]
addon.Locales.esMX["Auctions %d/%d"] = addon.Locales.esES["Auctions %d/%d"]
addon.Locales.esMX["Items %d/%d"] = addon.Locales.esES["Items %d/%d"]
addon.Locales.esMX["Finishing full scan"] = addon.Locales.esES["Finishing full scan"]
addon.Locales.esMX["Full scan: waiting"] = addon.Locales.esES["Full scan: waiting"]
addon.Locales.esMX["Shared scan: waiting"] = addon.Locales.esES["Shared scan: waiting"]
addon.Locales.esMX["Left-click: auction list"] = addon.Locales.esES["Left-click: auction list"]
addon.Locales.esMX["Right-click: settings"] = addon.Locales.esES["Right-click: settings"]
addon.Locales.esMX["Refresh prices"] = addon.Locales.esES["Refresh prices"]
addon.Locales.esMX["Stop Waylaid's scan or snapshot processing; keep saved prices. Other addons' scans continue."] =
    addon.Locales.esES["Stop Waylaid's scan or snapshot processing; keep saved prices. Other addons' scans continue."]
addon.Locales.esMX["Request one full auction-house snapshot to update both lists. The search filter only changes the displayed rows."] =
    addon.Locales.esES["Request one full auction-house snapshot to update both lists. The search filter only changes the displayed rows."]
addon.Locales.esMX["Scan purchases and delivery goods for the filtered list."] =
    addon.Locales.esES["Scan purchases and delivery goods for the filtered list."]

-- External scans are observed only for status; tab switches never query the AH.
addon.Locales.deDE["Another addon is scanning."] = "Ein anderes Addon scannt."
addon.Locales.deDE["Descriptions %d/%d"] = "Beschreibungen %d/%d"
addon.Locales.deDE["Auctionator: %d%%"] = "Auctionator: %d%%"
addon.Locales.frFR["Another addon is scanning."] = "Un autre addon analyse les enchères."
addon.Locales.frFR["Descriptions %d/%d"] = "Descriptions %d/%d"
addon.Locales.frFR["Auctionator: %d%%"] = "Auctionator: %d%%"
addon.Locales.esES["Another addon is scanning."] = "Otro addon está escaneando."
addon.Locales.esES["Descriptions %d/%d"] = "Descripciones %d/%d"
addon.Locales.esES["Auctionator: %d%%"] = "Auctionator: %d%%"
addon.Locales.esMX["Another addon is scanning."] = "Otro addon está escaneando."
addon.Locales.esMX["Descriptions %d/%d"] = "Descripciones %d/%d"
addon.Locales.esMX["Auctionator: %d%%"] = "Auctionator: %d%%"
addon.Locales.ptBR["Another addon is scanning."] = "Outro addon está escaneando."
addon.Locales.ptBR["Descriptions %d/%d"] = "Descrições %d/%d"
addon.Locales.ptBR["Auctionator: %d%%"] = "Auctionator: %d%%"
addon.Locales.ruRU["Another addon is scanning."] = "Другой аддон сканирует аукцион."
addon.Locales.ruRU["Descriptions %d/%d"] = "Описания %d/%d"
addon.Locales.ruRU["Auctionator: %d%%"] = "Auctionator: %d%%"
addon.Locales.koKR["Another addon is scanning."] = "다른 애드온이 검색 중입니다."
addon.Locales.koKR["Descriptions %d/%d"] = "설명 %d/%d"
addon.Locales.koKR["Auctionator: %d%%"] = "Auctionator: %d%%"
addon.Locales.zhTW["Another addon is scanning."] = "其他插件正在掃描。"
addon.Locales.zhTW["Descriptions %d/%d"] = "說明 %d/%d"
addon.Locales.zhTW["Auctionator: %d%%"] = "Auctionator: %d%%"

-- Provider refresh and the shared full-scan limit.
addon.Locales.deDE["Reloaded %s cached prices. Run a scan in that addon for newer data."] =
    "Gespeicherte Preise von %s neu geladen. Scanne in diesem Addon für neuere Daten."
addon.Locales.deDE["Reload cached provider prices. Scan in that addon for newer data."] =
    "Gespeicherte Anbieterpreise neu laden. Scanne in diesem Addon für neuere Daten."
addon.Locales.deDE["Full scans share a cooldown. Try again in %d seconds, or use /wll scan deep."] =
    "Vollständige Scans teilen sich eine Abklingzeit. Versuche es in %d Sekunden erneut oder nutze /wll scan deep."
addon.Locales.deDE["No auction snapshot response. A recent full scan may be throttled; use provider prices or /wll scan deep."] =
    "Keine Antwort auf die Auktionsabfrage. Ein kürzlicher vollständiger Scan kann weitere Anfragen begrenzen; nutze Anbieterpreise oder /wll scan deep."
addon.Locales.frFR["Reloaded %s cached prices. Run a scan in that addon for newer data."] =
    "Prix en cache de %s rechargés. Lancez une analyse dans cet addon pour des données plus récentes."
addon.Locales.frFR["Reload cached provider prices. Scan in that addon for newer data."] =
    "Recharger les prix en cache du fournisseur. Analysez dans cet addon pour des données plus récentes."
addon.Locales.frFR["Full scans share a cooldown. Try again in %d seconds, or use /wll scan deep."] =
    "Les analyses complètes partagent un délai. Réessayez dans %d secondes ou utilisez /wll scan deep."
addon.Locales.frFR["No auction snapshot response. A recent full scan may be throttled; use provider prices or /wll scan deep."] =
    "Aucune réponse pour les données des enchères. Une analyse complète récente peut limiter les requêtes ; utilisez les prix du fournisseur ou /wll scan deep."
addon.Locales.esES["Reloaded %s cached prices. Run a scan in that addon for newer data."] =
    "Precios guardados de %s recargados. Ejecuta un análisis en ese addon para obtener datos más recientes."
addon.Locales.esES["Reload cached provider prices. Scan in that addon for newer data."] =
    "Recargar precios guardados del proveedor. Analiza en ese addon para obtener datos más recientes."
addon.Locales.esES["Full scans share a cooldown. Try again in %d seconds, or use /wll scan deep."] =
    "Los análisis completos comparten un tiempo de espera. Reintenta en %d segundos o usa /wll scan deep."
addon.Locales.esES["No auction snapshot response. A recent full scan may be throttled; use provider prices or /wll scan deep."] =
    "No se recibió respuesta con los datos de la subasta. Un análisis completo reciente puede limitar las peticiones; usa precios del proveedor o /wll scan deep."
addon.Locales.ptBR["Reloaded %s cached prices. Run a scan in that addon for newer data."] =
    "Preços armazenados de %s recarregados. Faça uma busca nesse addon para obter dados mais recentes."
addon.Locales.ptBR["Reload cached provider prices. Scan in that addon for newer data."] =
    "Recarregar preços armazenados do provedor. Faça uma busca nesse addon para obter dados mais recentes."
addon.Locales.ptBR["Full scans share a cooldown. Try again in %d seconds, or use /wll scan deep."] =
    "Buscas completas compartilham um intervalo. Tente em %d segundos ou use /wll scan deep."
addon.Locales.ptBR["No auction snapshot response. A recent full scan may be throttled; use provider prices or /wll scan deep."] =
    "Nenhuma resposta com os dados do leilão. Uma busca completa recente pode limitar as solicitações; use preços do provedor ou /wll scan deep."
addon.Locales.ruRU["Reloaded %s cached prices. Run a scan in that addon for newer data."] =
    "Сохранённые цены %s обновлены. Для новых данных запустите сканирование в этом аддоне."
addon.Locales.ruRU["Reload cached provider prices. Scan in that addon for newer data."] =
    "Перечитать сохранённые цены поставщика. Для новых данных запустите сканирование в этом аддоне."
addon.Locales.ruRU["Full scans share a cooldown. Try again in %d seconds, or use /wll scan deep."] =
    "У полных сканирований общий интервал ожидания. Повторите через %d сек. или используйте /wll scan deep."
addon.Locales.ruRU["No auction snapshot response. A recent full scan may be throttled; use provider prices or /wll scan deep."] =
    "Ответ с данными аукциона не получен. Недавнее полное сканирование может ограничивать запросы; используйте цены поставщика или /wll scan deep."
addon.Locales.koKR["Reloaded %s cached prices. Run a scan in that addon for newer data."] =
    "%s의 저장된 가격을 다시 불러왔습니다. 최신 데이터는 해당 애드온에서 검색하세요."
addon.Locales.koKR["Reload cached provider prices. Scan in that addon for newer data."] =
    "제공자의 저장된 가격을 다시 불러옵니다. 최신 데이터는 해당 애드온에서 검색하세요."
addon.Locales.koKR["Full scans share a cooldown. Try again in %d seconds, or use /wll scan deep."] =
    "전체 검색은 대기 시간을 공유합니다. %d초 후 다시 시도하거나 /wll scan deep을 사용하세요."
addon.Locales.koKR["No auction snapshot response. A recent full scan may be throttled; use provider prices or /wll scan deep."] =
    "경매장 데이터 응답이 없습니다. 최근 전체 검색으로 요청이 제한될 수 있습니다. 제공자 가격 또는 /wll scan deep을 사용하세요."
addon.Locales.zhTW["Reloaded %s cached prices. Run a scan in that addon for newer data."] =
    "已重新載入 %s 的快取價格。請在該插件中掃描以取得較新資料。"
addon.Locales.zhTW["Reload cached provider prices. Scan in that addon for newer data."] =
    "重新載入提供者的快取價格。請在該插件中掃描以取得較新資料。"
addon.Locales.zhTW["Full scans share a cooldown. Try again in %d seconds, or use /wll scan deep."] =
    "完整掃描共用冷卻時間。請於 %d 秒後重試，或使用 /wll scan deep。"
addon.Locales.zhTW["No auction snapshot response. A recent full scan may be throttled; use provider prices or /wll scan deep."] =
    "未收到拍賣場資料回應。近期的完整掃描可能限制請求；請使用提供者價格或 /wll scan deep。"
addon.Locales.esMX["Reloaded %s cached prices. Run a scan in that addon for newer data."] =
    addon.Locales.esES["Reloaded %s cached prices. Run a scan in that addon for newer data."]
addon.Locales.esMX["Reload cached provider prices. Scan in that addon for newer data."] =
    addon.Locales.esES["Reload cached provider prices. Scan in that addon for newer data."]
addon.Locales.esMX["Full scans share a cooldown. Try again in %d seconds, or use /wll scan deep."] =
    addon.Locales.esES["Full scans share a cooldown. Try again in %d seconds, or use /wll scan deep."]
addon.Locales.esMX["No auction snapshot response. A recent full scan may be throttled; use provider prices or /wll scan deep."] =
    addon.Locales.esES["No auction snapshot response. A recent full scan may be throttled; use provider prices or /wll scan deep."]

-- Reward efficiency columns use the same client-selected locale as prices.
local rewardKeys = {
    "Cost / Favor",
    "Cost / reputation",
    "Reward unknown",
    "%d rep",
    "%d Favor",
    "Base rewards; bonuses and gold rewards are excluded.",
    "Reward unverified; excluded from cost-per-reward ranking.",
}
local rewardLabels = {
    deDE = {
        "Kosten / Gunst",
        "Kosten / Ruf",
        "Belohnung unbekannt",
        "%d Ruf",
        "%d Gunst",
        "Grundbelohnungen; Boni und Goldbelohnungen sind ausgeschlossen.",
        "Belohnung unbestätigt; nicht nach Kosten pro Belohnung eingestuft.",
    },
    frFR = {
        "Coût / faveur",
        "Coût / réputation",
        "Récompense inconnue",
        "%d réput.",
        "%d faveur",
        "Récompenses de base ; bonus et récompenses en or exclus.",
        "Récompense non vérifiée ; exclue du classement par coût unitaire.",
    },
    esES = {
        "Coste / favor",
        "Coste / reputación",
        "Recompensa desconocida",
        "%d rep.",
        "%d favor",
        "Recompensas base; se excluyen las bonificaciones y el oro recibido.",
        "Recompensa sin verificar; excluida de la clasificación por coste unitario.",
    },
    ptBR = {
        "Custo / favor",
        "Custo / reputação",
        "Recompensa desconhecida",
        "%d rep.",
        "%d favor",
        "Recompensas básicas; bônus e recompensas em ouro não estão incluídos.",
        "Recompensa não verificada; excluída da classificação por custo unitário.",
    },
    ruRU = {
        "Цена / благосклонность",
        "Цена / репутация",
        "Награда неизвестна",
        "%d реп.",
        "%d благоскл.",
        "Базовые награды; бонусы и денежные награды не учитываются.",
        "Награда не подтверждена; не участвует в сортировке по цене за единицу.",
    },
    koKR = {
        "호의당 비용",
        "평판당 비용",
        "보상 알 수 없음",
        "평판 %d",
        "호의 %d",
        "기본 보상 기준이며 보너스와 골드 보상은 제외됩니다.",
        "보상이 확인되지 않아 보상당 비용 순위에서 제외됩니다.",
    },
    zhTW = {
        "每點青睞成本",
        "每點聲望成本",
        "獎勵未知",
        "%d 聲望",
        "%d 青睞",
        "以基本獎勵計算；不計額外加成和金錢獎勵。",
        "獎勵尚未確認；不列入每單位獎勵成本排名。",
    },
}
for locale, labels in pairs(rewardLabels) do
    for index, key in ipairs(rewardKeys) do
        addon.Locales[locale][key] = labels[index]
    end
end

local sortHelp = {
    deDE = "Zum Sortieren klicken; erneut klicken, um die Reihenfolge umzukehren.",
    frFR = "Cliquez pour trier ; cliquez à nouveau pour inverser l’ordre.",
    esES = "Haz clic para ordenar; vuelve a hacer clic para invertir el orden.",
    ptBR = "Clique para ordenar; clique novamente para inverter a ordem.",
    ruRU = "Нажмите для сортировки; нажмите ещё раз, чтобы изменить порядок.",
    koKR = "클릭하여 정렬하고 다시 클릭하여 순서를 반대로 바꿉니다.",
    zhTW = "點擊以排序；再次點擊可反轉順序。",
}
for locale, label in pairs(sortHelp) do
    addon.Locales[locale]["Click to sort; click again to reverse."] = label
end

-- Cached browser
addon.Locales.deDE["Waylaid Ledger - saved prices"] = "Waylaid Ledger - gespeicherte Preise"
addon.Locales.deDE["Left-click opens the lists anywhere. Right-click opens settings."] =
    "Linksklick öffnet die Listen überall. Rechtsklick öffnet die Einstellungen."
addon.Locales.deDE["Saved prices. Visit the auction house for current prices and purchases."] =
    "Gespeicherte Preise. Besuche das Auktionshaus für aktuelle Preise und Einkäufe."
addon.Locales.frFR["Waylaid Ledger - saved prices"] = "Waylaid Ledger - prix enregistrés"
addon.Locales.frFR["Left-click opens the lists anywhere. Right-click opens settings."] =
    "Clic gauche : listes partout. Clic droit : options."
addon.Locales.frFR["Saved prices. Visit the auction house for current prices and purchases."] =
    "Prix enregistrés. Rendez-vous à l’hôtel des ventes pour les prix actuels et les achats."
addon.Locales.esES["Waylaid Ledger - saved prices"] = "Waylaid Ledger - precios guardados"
addon.Locales.esES["Left-click opens the lists anywhere. Right-click opens settings."] =
    "Clic izquierdo: listas en cualquier lugar. Clic derecho: opciones."
addon.Locales.esES["Saved prices. Visit the auction house for current prices and purchases."] =
    "Precios guardados. Visita la casa de subastas para ver precios actuales y comprar."
addon.Locales.ptBR["Waylaid Ledger - saved prices"] = "Waylaid Ledger - preços salvos"
addon.Locales.ptBR["Left-click opens the lists anywhere. Right-click opens settings."] =
    "Clique esquerdo abre as listas em qualquer lugar. Clique direito abre as configurações."
addon.Locales.ptBR["Saved prices. Visit the auction house for current prices and purchases."] =
    "Preços salvos. Visite a casa de leilões para preços atuais e compras."
addon.Locales.ruRU["Waylaid Ledger - saved prices"] = "Waylaid Ledger - сохранённые цены"
addon.Locales.ruRU["Left-click opens the lists anywhere. Right-click opens settings."] =
    "Левая кнопка открывает списки в любом месте. Правая — настройки."
addon.Locales.ruRU["Saved prices. Visit the auction house for current prices and purchases."] =
    "Сохранённые цены. Посетите аукцион, чтобы увидеть актуальные цены и сделать покупки."
addon.Locales.koKR["Waylaid Ledger - saved prices"] = "Waylaid Ledger - 저장된 가격"
addon.Locales.koKR["Left-click opens the lists anywhere. Right-click opens settings."] =
    "왼쪽 클릭: 어디서나 목록 열기. 오른쪽 클릭: 설정 열기."
addon.Locales.koKR["Saved prices. Visit the auction house for current prices and purchases."] =
    "저장된 가격입니다. 최신 가격 확인 및 구매는 경매장을 방문하세요."
addon.Locales.zhTW["Waylaid Ledger - saved prices"] = "Waylaid Ledger - 已儲存價格"
addon.Locales.zhTW["Left-click opens the lists anywhere. Right-click opens settings."] =
    "左鍵：隨時開啟清單。右鍵：開啟設定。"
addon.Locales.zhTW["Saved prices. Visit the auction house for current prices and purchases."] =
    "已儲存的價格。請前往拍賣場查看最新價格及購買。"
addon.Locales.esMX["Waylaid Ledger - saved prices"] = addon.Locales.esES["Waylaid Ledger - saved prices"]
addon.Locales.esMX["Left-click opens the lists anywhere. Right-click opens settings."] =
    addon.Locales.esES["Left-click opens the lists anywhere. Right-click opens settings."]
addon.Locales.esMX["Saved prices. Visit the auction house for current prices and purchases."] =
    addon.Locales.esES["Saved prices. Visit the auction house for current prices and purchases."]

-- Current browsing, settings and scan guidance (1.0.1).
addon.Locales.deDE["Left-click: saved crate and writ lists"] = "Linksklick: gespeicherte Kisten- und Auftragslisten"
addon.Locales.deDE["Loaded. /wll opens crate and writ lists. /wll settings opens settings."] =
    "Geladen. /wll öffnet Kisten- und Auftragslisten. /wll settings öffnet die Einstellungen."
addon.Locales.deDE["No matching items. Clear or change the search."] =
    "Keine passenden Artikel. Suche löschen oder ändern."
addon.Locales.deDE["Scan finished: %d items updated, %d failed."] =
    "Scan beendet: %d Artikel aktualisiert, %d fehlgeschlagen."
addon.Locales.deDE["Use /wll scan bags, hovered, tracked, all, crates, writs, or deep."] =
    "Verwende /wll scan bags, hovered, tracked, all, crates, writs oder deep."
addon.Locales.deDE["Full scan finished: %d item prices."] = "Vollständiger Scan beendet: %d Artikelpreise."
addon.Locales.deDE["Scan on AH open with Own scans, or Auto without an available price provider. May start a full scan."] =
    "Beim Öffnen mit Eigenen Scans scannen, oder mit Auto ohne verfügbaren Preisanbieter. Kann einen vollständigen Scan starten."
addon.Locales.deDE["Lists use saved prices. Refresh reloads prices; scanning requires the AH."] =
    "Listen nutzen gespeicherte Preise. Aktualisieren lädt Preise neu; Scans benötigen das Auktionshaus."
addon.Locales.deDE["Refresh is in each list; Stop appears during Waylaid scans. Advanced tools: /wll help"] =
    "Aktualisieren ist in jeder Liste; Stopp erscheint bei Waylaid-Scans. Weitere Werkzeuge: /wll help"
addon.Locales.deDE["Remember bags and visited banks across characters. Prices do not subtract owned items."] =
    "Taschen und besuchte Banken mehrerer Charaktere speichern. Eigene Gegenstände werden nicht vom Preis abgezogen."
addon.Locales.deDE["Offline inventory is last seen. Log into characters and revisit banks to refresh it."] =
    "Offline-Inventar ist der zuletzt erfasste Stand. Zum Aktualisieren einloggen und Banken erneut besuchen."
addon.Locales.frFR["Left-click: saved crate and writ lists"] =
    "Clic gauche : listes de caisses et commandes enregistrées"
addon.Locales.frFR["Loaded. /wll opens crate and writ lists. /wll settings opens settings."] =
    "Chargé. /wll ouvre les listes de caisses et commandes. /wll settings ouvre les options."
addon.Locales.frFR["No matching items. Clear or change the search."] =
    "Aucun objet correspondant. Effacez ou modifiez la recherche."
addon.Locales.frFR["Scan finished: %d items updated, %d failed."] =
    "Analyse terminée : %d objets mis à jour, %d échecs."
addon.Locales.frFR["Use /wll scan bags, hovered, tracked, all, crates, writs, or deep."] =
    "Utilisez /wll scan bags, hovered, tracked, all, crates, writs ou deep."
addon.Locales.frFR["Full scan finished: %d item prices."] = "Analyse complète terminée : %d prix d’objets."
addon.Locales.frFR["Scan on AH open with Own scans, or Auto without an available price provider. May start a full scan."] =
    "Analyse à l’ouverture avec Mes analyses, ou Auto sans source de prix disponible. Peut lancer une analyse complète."
addon.Locales.frFR["Lists use saved prices. Refresh reloads prices; scanning requires the AH."] =
    "Les listes utilisent les prix enregistrés. Actualiser recharge les prix ; les analyses nécessitent l’hôtel des ventes."
addon.Locales.frFR["Refresh is in each list; Stop appears during Waylaid scans. Advanced tools: /wll help"] =
    "Actualiser est dans chaque liste ; Arrêter apparaît pendant les analyses Waylaid. Outils avancés : /wll help"
addon.Locales.frFR["Remember bags and visited banks across characters. Prices do not subtract owned items."] =
    "Mémorise les sacs et banques visitées des personnages. Les objets possédés ne sont pas déduits des prix."
addon.Locales.frFR["Offline inventory is last seen. Log into characters and revisit banks to refresh it."] =
    "L’inventaire hors ligne est le dernier observé. Connectez les personnages et revisitez les banques pour l’actualiser."
addon.Locales.esES["Left-click: saved crate and writ lists"] = "Clic izquierdo: listas guardadas de cajones y encargos"
addon.Locales.esES["Loaded. /wll opens crate and writ lists. /wll settings opens settings."] =
    "Cargado. /wll abre las listas de cajones y encargos. /wll settings abre las opciones."
addon.Locales.esES["No matching items. Clear or change the search."] =
    "No hay objetos coincidentes. Borra o cambia la búsqueda."
addon.Locales.esES["Scan finished: %d items updated, %d failed."] =
    "Análisis terminado: %d objetos actualizados, %d fallidos."
addon.Locales.esES["Use /wll scan bags, hovered, tracked, all, crates, writs, or deep."] =
    "Usa /wll scan bags, hovered, tracked, all, crates, writs o deep."
addon.Locales.esES["Full scan finished: %d item prices."] = "Análisis completo terminado: %d precios de objetos."
addon.Locales.esES["Scan on AH open with Own scans, or Auto without an available price provider. May start a full scan."] =
    "Analiza al abrir la casa de subastas con Análisis propios, o Auto sin una fuente de precios disponible. Puede iniciar un análisis completo."
addon.Locales.esES["Lists use saved prices. Refresh reloads prices; scanning requires the AH."] =
    "Las listas usan precios guardados. Actualizar recarga los precios; analizar requiere la casa de subastas."
addon.Locales.esES["Refresh is in each list; Stop appears during Waylaid scans. Advanced tools: /wll help"] =
    "Actualizar está en cada lista; Detener aparece durante los análisis de Waylaid. Herramientas avanzadas: /wll help"
addon.Locales.esES["Remember bags and visited banks across characters. Prices do not subtract owned items."] =
    "Recuerda las bolsas y los bancos visitados de tus personajes. Los precios no descuentan los objetos que ya tienes."
addon.Locales.esES["Offline inventory is last seen. Log into characters and revisit banks to refresh it."] =
    "El inventario sin conexión es el último registrado. Entra con tus personajes y vuelve a visitar los bancos para actualizarlo."
addon.Locales.ptBR["Left-click: saved crate and writ lists"] = "Clique esquerdo: listas salvas de caixotes e ordens"
addon.Locales.ptBR["Loaded. /wll opens crate and writ lists. /wll settings opens settings."] =
    "Carregado. /wll abre listas de caixotes e ordens. /wll settings abre as configurações."
addon.Locales.ptBR["No matching items. Clear or change the search."] =
    "Nenhum item correspondente. Limpe ou altere a busca."
addon.Locales.ptBR["Scan finished: %d items updated, %d failed."] = "Busca concluída: %d itens atualizados, %d falhas."
addon.Locales.ptBR["Use /wll scan bags, hovered, tracked, all, crates, writs, or deep."] =
    "Use /wll scan bags, hovered, tracked, all, crates, writs ou deep."
addon.Locales.ptBR["Full scan finished: %d item prices."] = "Busca completa concluída: %d preços de itens."
addon.Locales.ptBR["Scan on AH open with Own scans, or Auto without an available price provider. May start a full scan."] =
    "Busca ao abrir a casa de leilões com Buscas próprias, ou Auto sem fonte de preços disponível. Pode iniciar uma busca completa."
addon.Locales.ptBR["Lists use saved prices. Refresh reloads prices; scanning requires the AH."] =
    "As listas usam preços salvos. Atualizar recarrega os preços; buscas exigem a casa de leilões."
addon.Locales.ptBR["Refresh is in each list; Stop appears during Waylaid scans. Advanced tools: /wll help"] =
    "Atualizar fica em cada lista; Parar aparece durante buscas do Waylaid. Ferramentas avançadas: /wll help"
addon.Locales.ptBR["Remember bags and visited banks across characters. Prices do not subtract owned items."] =
    "Memoriza bolsas e bancos visitados dos personagens. Os preços não descontam itens possuídos."
addon.Locales.ptBR["Offline inventory is last seen. Log into characters and revisit banks to refresh it."] =
    "O inventário offline é o último registrado. Entre nos personagens e visite os bancos novamente para atualizá-lo."
addon.Locales.ruRU["Left-click: saved crate and writ lists"] =
    "Левая кнопка: сохранённые списки ящиков и заказов"
addon.Locales.ruRU["Loaded. /wll opens crate and writ lists. /wll settings opens settings."] =
    "Загружено. /wll открывает списки ящиков и заказов. /wll settings открывает настройки."
addon.Locales.ruRU["No matching items. Clear or change the search."] =
    "Совпадений нет. Очистите или измените поиск."
addon.Locales.ruRU["Scan finished: %d items updated, %d failed."] =
    "Сканирование завершено: обновлено предметов — %d, ошибок — %d."
addon.Locales.ruRU["Use /wll scan bags, hovered, tracked, all, crates, writs, or deep."] =
    "Используйте /wll scan bags, hovered, tracked, all, crates, writs или deep."
addon.Locales.ruRU["Full scan finished: %d item prices."] =
    "Полное сканирование завершено: %d цен предметов."
addon.Locales.ruRU["Scan on AH open with Own scans, or Auto without an available price provider. May start a full scan."] =
    "Сканировать при открытии аукциона с источником «Свои сканирования» или «Авто» без доступного поставщика цен. Возможно полное сканирование."
addon.Locales.ruRU["Lists use saved prices. Refresh reloads prices; scanning requires the AH."] =
    "Списки используют сохранённые цены. «Обновить» загружает цены заново; для сканирования нужен аукцион."
addon.Locales.ruRU["Refresh is in each list; Stop appears during Waylaid scans. Advanced tools: /wll help"] =
    "«Обновить» есть в каждом списке; «Стоп» появляется при сканировании Waylaid. Дополнительные команды: /wll help"
addon.Locales.ruRU["Remember bags and visited banks across characters. Prices do not subtract owned items."] =
    "Запоминать сумки и посещённые банки персонажей. Имеющиеся предметы не вычитаются из стоимости."
addon.Locales.ruRU["Offline inventory is last seen. Log into characters and revisit banks to refresh it."] =
    "Офлайн-инвентарь показывает последние данные. Зайдите за персонажей и снова посетите банки для обновления."
addon.Locales.koKR["Left-click: saved crate and writ lists"] = "왼쪽 클릭: 저장된 상자 및 의뢰 목록"
addon.Locales.koKR["Loaded. /wll opens crate and writ lists. /wll settings opens settings."] =
    "로드되었습니다. /wll: 상자 및 의뢰 목록. /wll settings: 설정."
addon.Locales.koKR["No matching items. Clear or change the search."] =
    "일치하는 아이템이 없습니다. 검색어를 지우거나 변경하세요."
addon.Locales.koKR["Scan finished: %d items updated, %d failed."] =
    "검색 완료: 아이템 %d개 갱신, %d개 실패."
addon.Locales.koKR["Use /wll scan bags, hovered, tracked, all, crates, writs, or deep."] =
    "/wll scan bags, hovered, tracked, all, crates, writs 또는 deep을 사용하세요."
addon.Locales.koKR["Full scan finished: %d item prices."] = "전체 검색 완료: 아이템 가격 %d개."
addon.Locales.koKR["Scan on AH open with Own scans, or Auto without an available price provider. May start a full scan."] =
    "자체 검색 또는 가격 제공 애드온이 없는 자동 모드에서 경매장을 열 때 검색합니다. 전체 검색을 시작할 수 있습니다."
addon.Locales.koKR["Lists use saved prices. Refresh reloads prices; scanning requires the AH."] =
    "목록은 저장된 가격을 사용합니다. 새로고침으로 가격을 다시 불러오며, 검색은 경매장에서만 가능합니다."
addon.Locales.koKR["Refresh is in each list; Stop appears during Waylaid scans. Advanced tools: /wll help"] =
    "각 목록에 새로고침이 있으며 Waylaid 검색 중에는 중지가 표시됩니다. 고급 도구: /wll help"
addon.Locales.koKR["Remember bags and visited banks across characters. Prices do not subtract owned items."] =
    "캐릭터의 가방과 방문한 은행을 기억합니다. 가격에서 보유 아이템은 차감하지 않습니다."
addon.Locales.koKR["Offline inventory is last seen. Log into characters and revisit banks to refresh it."] =
    "오프라인 소지품은 마지막 기록입니다. 캐릭터에 접속하고 은행을 다시 방문하여 갱신하세요."
addon.Locales.zhTW["Left-click: saved crate and writ lists"] = "左鍵：已儲存的箱子與委託清單"
addon.Locales.zhTW["Loaded. /wll opens crate and writ lists. /wll settings opens settings."] =
    "已載入。/wll 開啟箱子與委託清單，/wll settings 開啟設定。"
addon.Locales.zhTW["No matching items. Clear or change the search."] =
    "沒有相符物品。請清除或變更搜尋條件。"
addon.Locales.zhTW["Scan finished: %d items updated, %d failed."] =
    "掃描完成：已更新 %d 項物品，%d 項失敗。"
addon.Locales.zhTW["Use /wll scan bags, hovered, tracked, all, crates, writs, or deep."] =
    "請使用 /wll scan bags、hovered、tracked、all、crates、writs 或 deep。"
addon.Locales.zhTW["Full scan finished: %d item prices."] = "完整掃描完成：%d 項物品價格。"
addon.Locales.zhTW["Scan on AH open with Own scans, or Auto without an available price provider. May start a full scan."] =
    "使用自行掃描，或自動模式且無可用價格來源時，在開啟拍賣場時掃描。可能啟動完整掃描。"
addon.Locales.zhTW["Lists use saved prices. Refresh reloads prices; scanning requires the AH."] =
    "清單使用已儲存價格。重新整理會重新載入價格；掃描需要在拍賣場進行。"
addon.Locales.zhTW["Refresh is in each list; Stop appears during Waylaid scans. Advanced tools: /wll help"] =
    "每個清單都有重新整理，Waylaid 掃描時顯示停止。進階工具：/wll help"
addon.Locales.zhTW["Remember bags and visited banks across characters. Prices do not subtract owned items."] =
    "記住各角色的背包與已造訪銀行。價格不會扣除已擁有物品。"
addon.Locales.zhTW["Offline inventory is last seen. Log into characters and revisit banks to refresh it."] =
    "離線物品為上次記錄。請登入角色並再次造訪銀行以更新。"
addon.Locales.deDE["Wait for the other addon's scan to finish before refreshing prices."] =
    "Warte, bis der Scan des anderen Addons beendet ist, bevor du Preise aktualisierst."
addon.Locales.frFR["Wait for the other addon's scan to finish before refreshing prices."] =
    "Attendez la fin de l’analyse de l’autre addon avant d’actualiser les prix."
addon.Locales.esES["Wait for the other addon's scan to finish before refreshing prices."] =
    "Espera a que termine el análisis del otro addon antes de actualizar los precios."
addon.Locales.ptBR["Wait for the other addon's scan to finish before refreshing prices."] =
    "Aguarde a busca do outro addon terminar antes de atualizar os preços."
addon.Locales.ruRU["Wait for the other addon's scan to finish before refreshing prices."] =
    "Дождитесь завершения сканирования другого аддона, прежде чем обновлять цены."
addon.Locales.koKR["Wait for the other addon's scan to finish before refreshing prices."] =
    "가격을 새로고침하기 전에 다른 애드온의 검색이 끝날 때까지 기다리세요."
addon.Locales.zhTW["Wait for the other addon's scan to finish before refreshing prices."] =
    "請等待其他插件掃描完成後再重新整理價格。"
