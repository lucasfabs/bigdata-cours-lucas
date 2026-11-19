-- Donnees analytiques :
-- - villes avec >= 30 commandes (et quelques villes en dessous)
-- - statuts varies (payee, validee, en_cours, annulee)
-- - dates sur ~18 mois (filtre "12 mois")
-- - 60 clients avec des volumes de commandes payees differents

TRUNCATE TABLE
  commande,
  panier_ligne,
  panier,
  categorie,
  variant,
  produit,
  prix,
  promotion,
  devise,
  marque,
  adresse,
  users
RESTART IDENTITY CASCADE;

INSERT INTO marque (nom, nom_commercial) VALUES
  ('Nike', 'Nike Inc.'),
  ('Adidas', 'Adidas AG'),
  ('Puma', 'Puma SE');

INSERT INTO devise (valeur) VALUES
  ('EUR'),
  ('USD'),
  ('GBP');

INSERT INTO promotion (valeur, date, nb_utilisation) VALUES
  ('10%', '2026-01-01', 100),
  ('20%', '2026-06-01', 50),
  ('5EUR', '2026-03-15', 200);

INSERT INTO prix (valeur, date, devise_id) VALUES
  (79.99, '2026-01-10', 1),
  (59.99, '2026-01-10', 1),
  (119.99, '2026-02-01', 1),
  (49.99, '2026-02-15', 1);

INSERT INTO produit (nom, description, reference, marque_id, prix_id) VALUES
  ('Basket Runner', 'Chaussure de course', 'NK-001', 1, 1),
  ('T-shirt Classic', 'T-shirt coton', 'AD-010', 2, 2),
  ('Veste Sport', 'Veste legere', 'PM-020', 3, 3),
  ('Short Training', 'Short respirant', 'NK-002', 1, 4);

INSERT INTO variant (produit_id, nom, taille, couleur, reference) VALUES
  (1, 'Runner S', '42', 'noir', 'NK-001-42-N'),
  (1, 'Runner M', '43', 'blanc', 'NK-001-43-B'),
  (2, 'Classic M', 'M', 'bleu', 'AD-010-M-BL'),
  (3, 'Veste L', 'L', 'gris', 'PM-020-L-G'),
  (4, 'Short S', 'S', 'noir', 'NK-002-S-N');

INSERT INTO categorie (nom, produit_id, promotion_id) VALUES
  ('Chaussures', 1, 1),
  ('Vetements', 2, 2),
  ('Sport', 3, 1),
  ('Sport', 4, 3);

CREATE TEMP TABLE villes_seed (
  id INTEGER PRIMARY KEY,
  ville VARCHAR(100),
  pays VARCHAR(100),
  code_postal VARCHAR(20),
  montant_base DECIMAL(10, 2),
  nb_commandes INTEGER
);

INSERT INTO villes_seed (id, ville, pays, code_postal, montant_base, nb_commandes) VALUES
  (1,  'Monaco',      'Monaco',       '98000', 320.00, 35),
  (2,  'Geneve',      'Suisse',       '1200',  300.00, 40),
  (3,  'Zurich',      'Suisse',       '8000',  290.00, 38),
  (4,  'Luxembourg',  'Luxembourg',   '1000',  280.00, 32),
  (5,  'Paris',       'France',       '75001', 260.00, 45),
  (6,  'Londres',     'Royaume-Uni',  'EC1A',  250.00, 42),
  (7,  'Amsterdam',   'Pays-Bas',     '1011',  240.00, 36),
  (8,  'Bruxelles',   'Belgique',     '1000',  230.00, 34),
  (9,  'Munich',      'Allemagne',    '80331', 220.00, 33),
  (10, 'Milan',       'Italie',       '20121', 210.00, 37),
  (11, 'Barcelone',   'Espagne',      '08001', 200.00, 31),
  (12, 'Vienne',      'Autriche',     '1010',  190.00, 30),
  (13, 'Lisbonne',    'Portugal',     '1100',  180.00, 35),
  (14, 'Lyon',        'France',       '69001', 170.00, 40),
  (15, 'Berlin',      'Allemagne',    '10115', 160.00, 38),
  (16, 'Madrid',      'Espagne',      '28013', 150.00, 36),
  (17, 'Rome',        'Italie',       '00118', 140.00, 32),
  (18, 'Porto',       'Portugal',     '4000',  130.00, 30),
  (19, 'Lille',       'France',       '59000', 120.00, 34),
  (20, 'Marseille',   'France',       '13001', 110.00, 41),
  (21, 'Nantes',      'France',       '44000', 350.00, 12),
  (22, 'Toulouse',    'France',       '31000', 340.00, 18),
  (23, 'Bordeaux',    'France',       '33000', 330.00, 8),
  (24, 'Nice',        'France',       '06000', 310.00, 20),
  (25, 'Strasbourg',  'France',       '67000', 305.00, 15);

-- 60 clients (assez pour un top 50)
INSERT INTO users (email, nom, prenom, tel, password, role)
SELECT
  'user' || i || '@exemple.com',
  'Client' || i,
  'Prenom' || i,
  '06000000' || lpad(i::text, 2, '0'),
  'pass123',
  'client'
FROM generate_series(1, 60) AS i;

-- 1 adresse / user, ville en cycle sur les 25 villes
INSERT INTO adresse (user_id, type, ligne, ville, code_postal, pays)
SELECT
  i,
  'domicile',
  '1 rue Principale',
  v.ville,
  v.code_postal,
  v.pays
FROM generate_series(1, 60) AS i
JOIN villes_seed v ON v.id = ((i - 1) % 25) + 1;

-- Commandes "villes" (defis 1 et 2) + statuts / dates varies
CREATE TEMP TABLE ordre_seed AS
SELECT
  row_number() OVER (ORDER BY v.id, g.n) AS rn,
  v.id AS city_id,
  v.ville,
  v.montant_base,
  g.n AS num_cmd,
  -- user reparti (1..60)
  1 + ((v.id * 3 + g.n * 7) % 60) AS user_id,
  CASE (g.n % 5)
    WHEN 0 THEN 'en_cours'
    WHEN 1 THEN 'annulee'
    WHEN 2 THEN 'validee'
    ELSE 'payee'
  END AS statut,
  -- 0 a 450 jours : une partie hors des 12 derniers mois
  CURRENT_DATE - ((g.n * 11 + v.id * 3) % 450) AS date_commande
FROM villes_seed v
CROSS JOIN LATERAL generate_series(1, v.nb_commandes) AS g(n);

INSERT INTO panier (user_id, promotion_id)
SELECT user_id, NULL
FROM ordre_seed
ORDER BY rn;

INSERT INTO panier_ligne (panier_id, produit_id, nb_produit)
SELECT
  rn,
  1 + ((rn - 1) % 4),
  1 + ((num_cmd - 1) % 3)
FROM ordre_seed
ORDER BY rn;

INSERT INTO commande (
  nom, adresse_id, user_id, panier_id, mail, montant, statut, date_commande
)
SELECT
  'Commande ' || ville || ' #' || num_cmd,
  user_id,
  user_id,
  rn,
  'user' || user_id || '@exemple.com',
  montant_base + ((num_cmd % 5) * 5),
  statut,
  date_commande
FROM ordre_seed
ORDER BY rn;

-- Extra commandes payees recentes pour classer clairement les clients
-- client 1 => 50 payees, client 2 => 49, ... client 50 => 1
CREATE TEMP TABLE extra_payee AS
SELECT
  row_number() OVER (ORDER BY c.user_id, g.n) AS rn,
  c.user_id,
  g.n AS num_cmd,
  (200 + c.user_id * 3 + g.n)::DECIMAL(10, 2) AS montant,
  CURRENT_DATE - (g.n % 60) AS date_commande
FROM generate_series(1, 50) AS c(user_id)
CROSS JOIN LATERAL generate_series(1, 51 - c.user_id) AS g(n);

INSERT INTO panier (user_id, promotion_id)
SELECT user_id, NULL
FROM extra_payee
ORDER BY rn;

INSERT INTO panier_ligne (panier_id, produit_id, nb_produit)
SELECT
  (SELECT COUNT(*) FROM ordre_seed) + rn,
  1 + ((rn - 1) % 4),
  1 + ((num_cmd - 1) % 2)
FROM extra_payee
ORDER BY rn;

INSERT INTO commande (
  nom, adresse_id, user_id, panier_id, mail, montant, statut, date_commande
)
SELECT
  'Commande payee client ' || user_id || ' #' || num_cmd,
  user_id,
  user_id,
  (SELECT COUNT(*) FROM ordre_seed) + rn,
  'user' || user_id || '@exemple.com',
  montant,
  'payee',
  date_commande
FROM extra_payee
ORDER BY rn;
