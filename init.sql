
CREATE TABLE `User` (
  `id` int(32) NOT NULL AUTO_INCREMENT,
  `username` varchar(128) NOT NULL,
  `password` char(128) DEFAULT NULL, -- must be matched with PasswordManager.HASH_BYTES (base64)
  `salt` char(128) DEFAULT NULL, -- must be matched with PasswordManager.SALT_BYTES (base64)
  `realname` varchar(128) DEFAULT NULL,
  `email` varchar(128) NOT NULL,
  `reg_date` varchar(128) NOT NULL,
  `avatar` varchar(128) DEFAULT NULL,
  `balance` int(32) NOT NULL DEFAULT 0,

  PRIMARY KEY (id),
  UNIQUE KEY `username_UNIQUE` (`username`),
  UNIQUE KEY `email_UNIQUE` (`email`)
);


CREATE TABLE Category (
  `id` int(32) NOT NULL AUTO_INCREMENT,
  `name` varchar(128) NOT NULL,
  `parent` int(32) DEFAULT NULL,

  PRIMARY KEY (id),
  FOREIGN KEY (parent) REFERENCES Category(id) ON DELETE CASCADE
);

CREATE TABLE `Project` (
  `id` int(32) NOT NULL AUTO_INCREMENT,
  `name` varchar(128) NOT NULL,
  `category` int(32) NOT NULL,
  `goal` int(32) NOT NULL,
  `description` varchar(128) NOT NULL,
  `description_long` varchar(128) NOT NULL,
  `deadline` varchar(128) NOT NULL,
  `user` int(32) NOT NULL,
  `deleted` tinyint(1) NOT NULL DEFAULT 0,
  `completed` tinyint(1) NOT NULL DEFAULT 0,

  PRIMARY KEY (id),
  FOREIGN KEY (user) REFERENCES User(id) ON DELETE CASCADE,
  FOREIGN KEY (category) REFERENCES Category(id) ON DELETE CASCADE
);

CREATE TABLE `Donation` (
  `id` int(32) NOT NULL AUTO_INCREMENT,
  `project` int(32) NOT NULL,
  `user` int(32) NOT NULL,
  `amount` int(32) NOT NULL,

  PRIMARY KEY (id, project, user),
  FOREIGN KEY (user) REFERENCES User(id) ON DELETE CASCADE,
  FOREIGN KEY (project) REFERENCES Project(id) ON DELETE CASCADE
);

CREATE TABLE `Reward` (
  `id` int(32) NOT NULL AUTO_INCREMENT,
  `name` varchar(128) NOT NULL,
  `description` varchar(128) NOT NULL,
  `category` int(32) NOT NULL,
  `goal` int(32) NOT NULL,
  `small_avatar` varchar(128) DEFAULT NULL,
  `big_avatar` varchar(128) DEFAULT NULL,

  PRIMARY KEY (id),
  FOREIGN KEY (category) REFERENCES Category(id) ON DELETE CASCADE
);

CREATE TABLE `Message` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `sender_id` INT NOT NULL,
  `receiver_id` INT NOT NULL,
  `subject` VARCHAR(128) NULL,
  `message_body` TEXT NULL,
  `send_date` VARCHAR(128) NULL,
  `parent_id` INT NULL,
  `receiver_read` TINYINT(1) NOT NULL DEFAULT 0,
  
  PRIMARY KEY (id),
  FOREIGN KEY (receiver_id) REFERENCES User(id) ON DELETE CASCADE
);

CREATE TABLE `Progress` (
  `id` int(32) NOT NULL AUTO_INCREMENT,
  `reward` int(32) NOT NULL,
  `user` int(32) NOT NULL,
  `count` int(32) NOT NULL DEFAULT 0,
  `done` int(1) NOT NULL DEFAULT 0,

  PRIMARY KEY (id),
  FOREIGN KEY (reward) REFERENCES Reward(id) ON DELETE CASCADE,
  FOREIGN KEY (user) REFERENCES User(id) ON DELETE CASCADE,
  UNIQUE KEY `reward_user` (`reward`,`user`)
);

delimiter $$
CREATE TRIGGER balanceCheck BEFORE UPDATE ON `User` FOR EACH ROW 
  BEGIN
    DECLARE dummy INT;
    IF NEW.balance < 0 THEN
      SIGNAL SQLSTATE '45000' set message_text = 'Tried to spend too much';
    END IF;
END$$
delimiter ;

delimiter $$
CREATE TRIGGER maintainProgress
BEFORE UPDATE ON Progress
FOR EACH ROW
BEGIN
	DECLARE goal INT;
    SET @goal = (SELECT Reward.goal FROM Reward WHERE Reward.id = NEW.reward GROUP BY Reward.goal);
	if NEW.count > @goal then
		set NEW.count = @goal;
	END IF;
END$$
delimiter ;

delimiter $$
CREATE TRIGGER projectCompletedInsert
AFTER INSERT ON Donation
FOR EACH ROW
BEGIN
	DECLARE goal INT;
    SET @goal = (SELECT Project.goal FROM Project WHERE Project.id = NEW.project GROUP BY Project.goal);
    SET @progress = (SELECT CAST(sum(amount) AS SIGNED) as amount From Donation WHERE Donation.project = NEW.project GROUP BY Donation.project);
	if @progress >= @goal then
		update Project set completed = 1 where id = NEW.project;
	END IF;
END$$
delimiter ;

delimiter $$
CREATE TRIGGER sendCompletedMessage
AFTER UPDATE ON Project
FOR EACH ROW
BEGIN
	IF OLD.completed = 0 AND NEW.completed = 1 THEN
		BEGIN
			DECLARE curuser INT;
			DECLARE done INT DEFAULT FALSE;
			DECLARE cur CURSOR FOR SELECT Donation.user FROM Donation WHERE project = NEW.id GROUP BY Donation.user;
			DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
			OPEN cur;
			send_message: LOOP
				FETCH cur INTO curuser;
				IF done THEN
					LEAVE send_message;
				END IF;
				INSERT INTO Message(sender_id, receiver_id, subject, message_body, send_date, parent_id) VALUE (-10000, curuser, 'Project Completed', 'Egy project elerte a celt.', 'Most', null);
			END LOOP;
			CLOSE cur;
        END;
    END IF;
END$$
delimiter ;

delimiter $$
CREATE TRIGGER sendDeletedMessage
AFTER UPDATE ON Project
FOR EACH ROW
BEGIN
	IF OLD.deleted = 0 AND NEW.deleted = 1 THEN
		BEGIN
			DECLARE curuser INT;
			DECLARE done INT DEFAULT FALSE;
			DECLARE cur CURSOR FOR SELECT Donation.user FROM Donation WHERE project = NEW.id GROUP BY Donation.user;
			DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
			OPEN cur;
			send_message: LOOP
				FETCH cur INTO curuser;
				IF done THEN
					LEAVE send_message;
				END IF;
				INSERT INTO Message(sender_id, receiver_id, subject, message_body, send_date, parent_id) VALUE (-10000, curuser, 'Project Deleted', concat(NEW.name, ' nevu project torolve lett.'), NOW(), null);
			END LOOP;
			CLOSE cur;
        END;
    END IF;
END$$
delimiter ;

delimiter $$
CREATE TRIGGER projectCompletedDelete
AFTER DELETE ON Donation
FOR EACH ROW
BEGIN
	DECLARE goal INT;
    SET @goal = (SELECT Project.goal FROM Project WHERE Project.id = OLD.project GROUP BY Project.goal);
    SET @progress = (SELECT CAST(sum(amount) AS SIGNED) as amount From Donation WHERE Donation.project = OLD.project GROUP BY Donation.project);
	if @progress < @goal then
		update Project set completed = 0 where id = OLD.project;
	END IF;
END$$
delimiter ;

delimiter $$
CREATE TRIGGER messageDelete
AFTER DELETE ON Message
FOR EACH ROW
BEGIN
    DECLARE parentRecord INT;
    SET @parentRecord = OLD.parent_id;
    IF @parentRecord IS NOT NULL THEN
		DELETE FROM Message WHERE id = @parentRecord;
    END IF;
END$$
delimiter ;

-- Computer Game, Design, Fashion, Film, Music, Startup, Technology