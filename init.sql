
CREATE TABLE `User` (
  `id` int(32) NOT NULL AUTO_INCREMENT,
  `username` varchar(128) NOT NULL,
  `realname` varchar(128) NOT NULL,
  `email` varchar(128) NOT NULL,
  `reg_date` DATE NOT NULL,
  `avatar` varchar(32) DEFAULT NULL,

  PRIMARY KEY (id)
);

CREATE TABLE `Chat` (
  `id` int(32) NOT NULL AUTO_INCREMENT,
  `from` int(32) NOT NULL,
  `to` int(32) NOT NULL,
  `pending` bit NOT NULL,

  PRIMARY KEY (`id`, `from`, `to`),
  FOREIGN KEY (`from`) REFERENCES User(id) ON DELETE CASCADE,
  FOREIGN KEY (`to`) REFERENCES User(id) ON DELETE CASCADE
);

CREATE TABLE `Message` (
  `chat` int(32) NOT NULL,
  `time` Date NOT NULL,
  `text` varchar(512) NOT NULL,

  PRIMARY KEY (`chat`, `time`),
  FOREIGN KEY (chat) REFERENCES Chat(id) ON DELETE CASCADE
);

-- static data
CREATE TABLE `City` (
  `id` int(32) NOT NULL AUTO_INCREMENT,
  `name` varchar(32) NOT NULL,

  PRIMARY KEY (`id`)
);


-- cucc ami szerint matchelunk
-- ennek kell jobb nev
CREATE TABLE `Cucc` ( 
  `id` int(32) NOT NULL AUTO_INCREMENT,
  `user` int(32) NOT NULL,
  `city` int(32) NOT NULL,
  `begin` Date NOT NULL,
  `end` Date NOT NULL,

  PRIMARY KEY (`id`),
  FOREIGN KEY (user) REFERENCES User(id) ON DELETE CASCADE,
  FOREIGN KEY (city) REFERENCES City(id) ON DELETE CASCADE
);

-- static data
CREATE TABLE `Activity` ( 
  `id` int(32) NOT NULL,
  `name` varchar(32) NOT NULL,

  PRIMARY KEY (`id`)
);

-- n:n connection
CREATE TABLE `CuccActivities` ( 
  `cucc` int(32) NOT NULL,
  `activity` int(32) NOT NULL,

  FOREIGN KEY (cucc) REFERENCES Cucc(id) ON DELETE CASCADE,
  FOREIGN KEY (activity) REFERENCES Activity(id) ON DELETE CASCADE
);