-- defi 01 
SELECT
  adresse.pays,
  AVG(commande.montant) AS montant_moyen,
  COUNT(commande.id) AS nombre_commandes,
  SUM(commande.montant) AS chiffre_affaires
FROM commande
JOIN adresse ON commande.adresse_id = adresse.id
WHERE commande.statut = 'validee'
GROUP BY adresse.pays
ORDER BY chiffre_affaires DESC;

-- defi 2
SELECT
  adresse.ville,
  AVG(commande.montant) AS montant_moyen,
  COUNT(commande.id) AS nombre_commandes
FROM commande
JOIN adresse ON commande.adresse_id = adresse.id
GROUP BY adresse.ville
HAVING COUNT(commande.id) >= 30
ORDER BY montant_moyen DESC
LIMIT 20

--defi 3 
SELECT
  user_id,
  SUM(commande.montant) AS depense_total,
  COUNT(commande.id) AS nombre_commandes
FROM commande
WHERE commande.statut = 'payee' 
--   AND commande.date_commande >= CURRENT_DATE - '12 months'
GROUP BY commande.user_id
ORDER BY nombre_commandes DESC
LIMIT 50

-- defi 4
SELECT
  variant.id
FROM variant
LEFT JOIN panier_ligne ON panier_ligne.produit_id = variant.produit_id
LEFT JOIN panier ON panier.id = panier_ligne.panier_id
LEFT JOIN commande ON commande.panier_id = panier.id
WHERE commande.id IS NULL;

-- defi 5
-- SELECT
--   marque.nom AS marque,
--   SUM(prix.valeur * panier_ligne.nb_produit) AS chiffre_affaires
-- FROM marque
-- JOIN produit ON produit.marque_id = marque.id
-- JOIN prix ON prix.id = produit.prix_id
-- WHERE commande.statut = 'payee'
-- GROUP BY marque.id, marque.nom
-- ORDER BY chiffre_affaires DESC;

-- deif 7 
SELECT
  commande.user_id,
  MAX(commande.date_commande) AS derniere_commande
FROM commande
GROUP BY commande.user_id
HAVING MAX(commande.date_commande) < CURRENT_DATE - INTERVAL '180 days'
ORDER BY derniere_commande;

-- defi 8
SELECT DISTINCT ON (adresse.pays)
  adresse.pays,
  categorie.nom AS categorie
FROM commande
JOIN adresse ON adresse.id = commande.adresse_id
JOIN panier ON panier.id = commande.panier_id
JOIN panier_ligne ON panier_ligne.panier_id = panier.id
JOIN produit ON produit.id = panier_ligne.produit_id
JOIN prix ON prix.id = produit.prix_id
JOIN categorie ON categorie.produit_id = produit.id
WHERE commande.statut IN ('payee', 'validee')
GROUP BY adresse.pays, categorie.nom
ORDER BY adresse.pays, SUM(prix.valeur * panier_ligne.nb_produit) DESC;


-- defi 18 
-- pas fait


-- defi 19 
-- quelle proportion des clients repasse commande dans les 30, 60 et 90 jours apres leur premier achat ? 
WITH premier_achat AS (
  SELECT
    user_id,
    MIN(date_commande) AS date_premier
  FROM commande
  WHERE statut IN ('payee', 'validee')
  GROUP BY user_id
),
clients AS (
  SELECT
    p.user_id,
    EXISTS (
      SELECT 1
      FROM commande c
      WHERE c.user_id = p.user_id
        AND c.statut IN ('payee', 'validee')
        AND c.date_commande > p.date_premier
        AND c.date_commande <= p.date_premier + INTERVAL '30 days'
    ) AS rachat_30,
    EXISTS (
      SELECT 1
      FROM commande c
      WHERE c.user_id = p.user_id
        AND c.statut IN ('payee', 'validee')
        AND c.date_commande > p.date_premier
        AND c.date_commande <= p.date_premier + INTERVAL '60 days'
    ) AS rachat_60,
    EXISTS (
      SELECT 1
      FROM commande c
      WHERE c.user_id = p.user_id
        AND c.statut IN ('payee', 'validee')
        AND c.date_commande > p.date_premier
        AND c.date_commande <= p.date_premier + INTERVAL '90 days'
    ) AS rachat_90
  FROM premier_achat p
)
SELECT
  ROUND(100.0 * COUNT(*) FILTER (WHERE rachat_30) / COUNT(*), 2) AS pct_30_jours,
  ROUND(100.0 * COUNT(*) FILTER (WHERE rachat_60) / COUNT(*), 2) AS pct_60_jours,
  ROUND(100.0 * COUNT(*) FILTER (WHERE rachat_90) / COUNT(*), 2) AS pct_90_jours
FROM clients;

-- defi 20 
--quelles paires de variantes sont les plus frequentes dans une meme commande ? comptez chaque paire une fois par commande 
-- pas fait 