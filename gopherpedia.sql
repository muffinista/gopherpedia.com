gopherpedia
g0ferp3dlia
cat shorter-titles | sed "s/'/''/g" | sed "s/.*/'&'/" > titles-load

DROP TABLE IF EXISTS pages;
CREATE TABLE pages (
  id int NOT NULL AUTO_INCREMENT,
  title varchar(250),
  viewed_at timestamp,
  primary key(id)
);

CREATE INDEX viewed_at ON pages(viewed_at);

DROP TABLE IF EXISTS titles;
CREATE TABLE titles (
  id int NOT NULL AUTO_INCREMENT,
  title varchar(300),
  primary key(id)
) ENGINE = MyISAM;

LOAD DATA INFILE '/tmp/titles-load' INTO TABLE titles FIELDS ENCLOSED BY "'" (title);

CREATE FULLTEXT INDEX title ON titles(title);

LOAD DATA LOCAL INFILE '/home/mitchc2/gopherpedia-data/titles-load' INTO TABLE titles FIELDS ENCLOSED BY "'" (title);

CREATE FULLTEXT INDEX title ON titles(title);
