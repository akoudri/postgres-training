INSERT INTO author (first_name, last_name, birthdate) VALUES ('George', 'Orwell', '1903-06-25');
INSERT INTO author (first_name, last_name, birthdate) VALUES ('J.K.', 'Rowling', '1965-07-31');
INSERT INTO author (first_name, last_name, birthdate) VALUES ('F. Scott', 'Fitzgerald', '1896-09-24');
INSERT INTO author (first_name, last_name, birthdate) VALUES ('Victor', 'Hugo', '1802-02-26');
INSERT INTO author (first_name, last_name, birthdate) VALUES ('Charles', 'Dickens', '1812-02-07');
INSERT INTO author (first_name, last_name, birthdate) VALUES ('Jane', 'Austen', '1775-12-16');
INSERT INTO author (first_name, last_name, birthdate) VALUES ('Marcel', 'Proust', '1871-07-10');
INSERT INTO author (first_name, last_name, birthdate) VALUES ('Emily', 'Bronte', '1818-07-30');
INSERT INTO author (first_name, last_name, birthdate) VALUES ('Jules', 'Verne', '1828-02-08');
INSERT INTO Author (first_name, last_name, birthdate) VALUES ('Agatha', 'Christie', '1890-09-15');
INSERT INTO Author (first_name, last_name, birthdate) VALUES ('Ernest', 'Hemingway', '1899-07-21');
-- INSERT INTO author (first_name, last_name, birthdate) VALUES ('Mark', 'Twain', '1835-11-30');

-- Livres de George Orwell
INSERT INTO book (title, published_date, genre) VALUES ('1984', '1949-06-08', 'Science-fiction');
INSERT INTO book (title, published_date, genre) VALUES ('La Ferme des animaux', '1945-08-17', 'Satire');

-- Livres de J.K. Rowling
INSERT INTO book (title, published_date, genre) VALUES ('Harry Potter à l''école des sorciers', '1997-06-26', 'Fantasy');
INSERT INTO book (title, published_date, genre) VALUES ('Harry Potter et la Chambre des secrets', '1998-07-02', 'Fantasy');
INSERT INTO book (title, published_date, genre) VALUES ('Harry Potter et le Prisonnier d''Azkaban', '1999-07-08', 'Fantasy');
INSERT INTO book (title, published_date, genre) VALUES ('Harry Potter et la Coupe de feu', '2000-07-08', 'Fantasy');
INSERT INTO book (title, published_date, genre) VALUES ('Harry Potter et l''Ordre du Phénix', '2003-06-21', 'Fantasy');
INSERT INTO book (title, published_date, genre) VALUES ('Harry Potter et le Prince de sang-mêlé', '2005-07-16', 'Fantasy');
INSERT INTO book (title, published_date, genre) VALUES ('Harry Potter et les Reliques de la Mort', '2007-07-21', 'Fantasy');

-- Livres de F. Scott Fitzgerald
INSERT INTO book (title, published_date, genre) VALUES ('Gatsby le Magnifique', '1925-04-10', 'Roman');
INSERT INTO book (title, published_date, genre) VALUES ('Tendre est la nuit', '1934-04-12', 'Roman');

-- Livres de Victor Hugo
INSERT INTO book (title, published_date, genre) VALUES ('Les Misérables', '1862-01-01', 'Roman');
INSERT INTO book (title, published_date, genre) VALUES ('Notre-Dame de Paris', '1831-03-16', 'Roman');

-- Livres de Charles Dickens
INSERT INTO book (title, published_date, genre) VALUES ('Un conte de deux villes', '1859-04-30', 'Roman historique');
INSERT INTO book (title, published_date, genre) VALUES ('Oliver Twist', '1838-02-01', 'Roman');

-- Livres de Jane Austen
INSERT INTO book (title, published_date, genre) VALUES ('Orgueil et Préjugés', '1813-01-28', 'Roman');
INSERT INTO book (title, published_date, genre) VALUES ('Raison et Sentiments', '1811-10-30', 'Roman');

-- Livres de Marcel Proust
INSERT INTO book (title, published_date, genre) VALUES ('Du côté de chez Swann', '1913-11-14', 'Roman');
INSERT INTO book (title, published_date, genre) VALUES ('À l''ombre des jeunes filles en fleurs', '1919-06-01', 'Roman');

-- Livres d'Emily Bronte
INSERT INTO book (title, published_date, genre) VALUES ('Les Hauts de Hurlevent', '1847-12-01', 'Roman');

-- Livres de Jules Verne
INSERT INTO book (title, published_date, genre) VALUES ('Vingt mille lieues sous les mers', '1870-06-20', 'Science-fiction');
INSERT INTO book (title, published_date, genre) VALUES ('Le Tour du monde en quatre-vingts jours', '1873-01-30', 'Aventure');
INSERT INTO book (title, published_date, genre) VALUES ('Voyage au centre de la Terre', '1864-11-25', 'Science-fiction');
INSERT INTO book (title, published_date, genre) VALUES ('De la Terre à la Lune', '1865-09-01', 'Science-fiction');
INSERT INTO book (title, published_date, genre) VALUES ('Les Enfants du capitaine Grant', '1867-06-20', 'Aventure');
INSERT INTO book (title, published_date, genre) VALUES ('L''Île mystérieuse', '1874-01-01', 'Aventure');
INSERT INTO book (title, published_date, genre) VALUES ('Les Cinq Cents Millions de la Bégum', '1879-01-01', 'Science-fiction');

-- Relations

-- Relations pour George Orwell
INSERT INTO book_author (book_id, author_id, role) VALUES (3, 1, 'Premier auteur');
INSERT INTO book_author (book_id, author_id, role) VALUES (4, 1, 'Premier auteur');

-- Relations pour J.K. Rowling
INSERT INTO book_author (book_id, author_id, role) VALUES (1, 2, 'Premier auteur');
INSERT INTO book_author (book_id, author_id, role) VALUES (2, 2, 'Premier auteur');
INSERT INTO book_author (book_id, author_id, role) VALUES (3, 2, 'Premier auteur');
INSERT INTO book_author (book_id, author_id, role) VALUES (4, 2, 'Premier auteur');
INSERT INTO book_author (book_id, author_id, role) VALUES (5, 2, 'Premier auteur');
INSERT INTO book_author (book_id, author_id, role) VALUES (6, 2, 'Premier auteur');
INSERT INTO book_author (book_id, author_id, role) VALUES (7, 2, 'Premier auteur');

-- Relations pour F. Scott Fitzgerald
INSERT INTO book_author (book_id, author_id, role) VALUES (7, 3, 'Premier auteur');
INSERT INTO book_author (book_id, author_id, role) VALUES (8, 3, 'Premier auteur');

-- Relations pour Victor Hugo
INSERT INTO book_author (book_id, author_id, role) VALUES (9, 4, 'Premier auteur');
INSERT INTO book_author (book_id, author_id, role) VALUES (10, 4, 'Premier auteur');

-- Relations pour Charles Dickens
INSERT INTO book_author (book_id, author_id, role) VALUES (11, 5, 'Premier auteur');
INSERT INTO book_author (book_id, author_id, role) VALUES (12, 5, 'Premier auteur');

-- Relations pour Jane Austen
INSERT INTO book_author (book_id, author_id, role) VALUES (13, 6, 'Premier auteur');
INSERT INTO book_author (book_id, author_id, role) VALUES (14, 6, 'Premier auteur');

-- Relations pour Marcel Proust
INSERT INTO book_author (book_id, author_id, role) VALUES (15, 7, 'Premier auteur');
INSERT INTO book_author (book_id, author_id, role) VALUES (16, 7, 'Premier auteur');

-- Relation pour Emily Bronte
INSERT INTO book_author (book_id, author_id, role) VALUES (17, 8, 'Premier auteur');

-- Relations pour Jules Verne
INSERT INTO book_author (book_id, author_id, role) VALUES (1, 9, 'Premier auteur');
INSERT INTO book_author (book_id, author_id, role) VALUES (2, 9, 'Premier auteur');
INSERT INTO book_author (book_id, author_id, role) VALUES (3, 9, 'Premier auteur');
INSERT INTO book_author (book_id, author_id, role) VALUES (4, 9, 'Premier auteur');
INSERT INTO book_author (book_id, author_id, role) VALUES (5, 9, 'Premier auteur');
INSERT INTO book_author (book_id, author_id, role) VALUES (6, 9, 'Premier auteur');
INSERT INTO book_author (book_id, author_id, role) VALUES (7, 9, 'Premier auteur');
