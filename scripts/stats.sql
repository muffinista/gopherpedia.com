CREATE DATABASE gopherpedia;
USE gopherpedia;


DROP TABLE IF EXISTS `pages`;
CREATE TABLE `pages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(250) DEFAULT NULL,
  `viewed_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `viewed_at` (`viewed_at`)
) DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS traffic;
CREATE TABLE traffic (
	   hostname varchar(100) NOT NULL,
	   selector varchar(100) NOT NULL,
	   remote_ip INT UNSIGNED NOT NULL,
	   filesize INT UNSIGNED NOT NULL DEFAULT 0,
	   request_at datetime NOT NULL
);

CREATE INDEX host_traffic_idx ON traffic(hostname, request_at);
CREATE INDEX host_selector_traffic_idx ON traffic(hostname, selector, request_at);
