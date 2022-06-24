-- phpMyAdmin SQL Dump
-- version 5.1.3
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Jun 18, 2022 at 05:31 AM
-- Server version: 10.4.24-MariaDB
-- PHP Version: 7.4.28

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `test_bairways`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `add_airport` (`code` CHAR(3), `name` VARCHAR(50), `locations` VARCHAR(1000), `num` INT)   begin
	declare loc varchar(100);
    declare loc_id int;
	call add_port_location(locations, num);
    
    select SPLIT_STR(locations, ',', 1) into loc;
    -- select loc;
    select id into loc_id from port_location where location = loc;
    insert into airport(code, name, location) values (code, name, loc_id);
end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `add_port_location` (`location_str` VARCHAR(1000), `num` INT)   begin
	declare i int;
    declare parent int;
    declare current_id int;
    declare iter_count int;
    declare temp_loc varchar(100);
  
	drop temporary table if exists temp_data;
    create temporary table temp_data (id int auto_increment primary key, loc varchar(100), loc_parent int);
    
    set i = num;
    while ( i > 0) do
		select SPLIT_STR(location_str, ',', i) into temp_loc;
        select count(id) into parent from port_location where location = temp_loc;
        if parent = 0 then	
			start transaction; 
				insert into port_location (location) values (temp_loc);
				select last_insert_id() into parent;  
			commit;
		else
			select id into parent from port_location where location = temp_loc;
        end if;        
        insert into temp_data(loc, loc_parent) values (temp_loc, parent);
        set i = i-1;
    end while;
    
    select count(*) into iter_count from temp_data; 
    
    set i = 1;
    while iter_count > i do
		select loc_parent into current_id from temp_data where id = i+1;
		select loc_parent into parent from temp_data where id = i;
		insert ignore into parent_location ( id, parent_id) values ( current_id, parent);
        set i = i + 1;
    end while;
    
    drop temporary table temp_data;    

end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `book_ticket` (IN `user_id` INT, IN `passenger_id` VARCHAR(25), IN `flight_id` INT, IN `seat_number` INT, IN `date` DATETIME, IN `class` VARCHAR(10), IN `paid` DECIMAL(10,2), IN `is_boarded` TINYINT)   begin
	declare ticket_id int;
	start transaction;
		insert into ticket( `user_id`, `date`, `class`, `paid`, `is_boarded`) 
		values (user_id, date, class, paid, is_boarded);
        
		select last_insert_id() into ticket_id;
        
        insert into booking
		values ( passenger_id, flight_id, ticket_id);
        
        insert into seat_reservation
        values (flight_id, seat_number, ticket_id);
	commit;
end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `book_ticket_proc` (IN `in_f_id` INT(11), IN `in_user_id` INT(11), IN `in_passenger_id` VARCHAR(25), IN `in_passenger_name` VARCHAR(150), IN `in_passenger_add` VARCHAR(255), IN `in_dob` DATE, IN `in_class` VARCHAR(10), IN `in_seat_no` VARCHAR(5))   BEGIN  
    declare payment  dec(10,2);
    declare disc_type varchar(20);
    declare var_discount dec(4,2);

	select cost into payment from flight_cost where flight_id =in_f_id and class=in_class limit 1;
    
	if in_user_id !=0 then
        
    		select discount_type into disc_type from user where user_id=in_user_id limit 1;
        	select discount into var_discount from discount where type =disc_type limit 1;
        	
            set payment= payment *( 100-var_discount)/100;
    end if;  
    start TRANSACTION;
    	insert IGNORE into passenger values(in_passenger_id,in_passenger_name,in_dob,in_passenger_add);
    	insert into ticket(user_id,passenger_id,flight_id,seat_number,date,class,paid,status,is_boarded) values (in_user_id,in_passenger_id,in_f_id,in_seat_no,NOW(),in_class,payment,0,0);
    commit;
END$$

--
-- Functions
--
CREATE DEFINER=`root`@`localhost` FUNCTION `get_location` (`location_id` INT) RETURNS VARCHAR(1000) CHARSET utf8mb4 DETERMINISTIC begin
	declare loc varchar(1000);
    declare temp_s varchar(100);
    declare temp_id1 int;
    declare temp_id2 int;
    
    set temp_id1 = location_id;
    
    repeat
		select location, parent_id into temp_s, temp_id2 
			from port_location_with_parent
			where id = temp_id1;
		set temp_id1 = temp_id2;
        if isnull(loc) then
			set loc = temp_s;
		else
			set loc = concat(loc,', ',temp_s);
		end if;
	until isnull(temp_id1)
    end repeat;
	return loc;
	
end$$

CREATE DEFINER=`root`@`localhost` FUNCTION `SPLIT_STR` (`x` VARCHAR(255), `delim` VARCHAR(12), `pos` INT) RETURNS VARCHAR(255) CHARSET utf8mb4 DETERMINISTIC RETURN REPLACE(SUBSTRING(SUBSTRING_INDEX(x, delim, pos),
       LENGTH(SUBSTRING_INDEX(x, delim, pos -1)) + 1),
       delim, '')$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `aircraft`
--

CREATE TABLE `aircraft` (
  `aircraft_id` int(11) NOT NULL,
  `tail_number` varchar(10) NOT NULL,
  `model` varchar(50) NOT NULL,
  `Economy_seats` int(11) DEFAULT NULL CHECK (`Economy_seats` > 0),
  `Business_seats` int(11) DEFAULT NULL CHECK (`Business_seats` > 0),
  `Platinum_seats` int(11) DEFAULT NULL CHECK (`Platinum_seats` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `aircraft`
--

INSERT INTO `aircraft` (`aircraft_id`, `tail_number`, `model`, `Economy_seats`, `Business_seats`, `Platinum_seats`) VALUES
(1, 'PK-MGI', 'Boeing 737', 50, 50, 26),
(2, 'PK-MGZ', 'Boeing 737', 50, 50, 26),
(3, 'PK-YGH', 'Boeing 737', 50, 50, 26),
(4, 'PK-YGV', 'Boeing 757', 70, 60, 32),
(5, 'PK-YGW', 'Boeing 757', 70, 60, 32),
(6, 'PK-LBW', 'Boeing 757', 70, 60, 32),
(7, 'PK-LBZ', 'Boeing 757', 70, 60, 32),
(8, 'PK-LUV', 'Airbus A380', 200, 200, 125);

-- --------------------------------------------------------

--
-- Table structure for table `airport`
--

CREATE TABLE `airport` (
  `airport_id` int(11) NOT NULL,
  `code` char(3) NOT NULL,
  `name` varchar(50) NOT NULL,
  `location` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `airport`
--

INSERT INTO `airport` (`airport_id`, `code`, `name`, `location`) VALUES
(1, 'CGK', 'Soekarno-Hatta International Airport', 1),
(2, 'DPS', 'Ngurah Rai International Airport', 4),
(3, 'BIA', 'Bandaranaike International Airport', 6),
(4, 'HRI', 'Mattala international airport', 8),
(5, 'DEL', 'Indira Gandhi International Airport', 9),
(6, 'BOM', 'Chhatrapati Shivaji Maharaj International Airport', 11),
(7, 'MAA', 'Chennai International Airport', 13),
(8, 'BKK', 'Suvarnabhumi Airport', 15),
(9, 'DMK', 'Don Mueang International Airport', 18),
(10, 'SIN', 'Singapore Changi Airport', 20);

-- --------------------------------------------------------

--
-- Stand-in structure for view `airport_locations`
-- (See below for the actual view)
--
CREATE TABLE `airport_locations` (
`id` int(11)
,`code` char(3)
,`name` varchar(50)
,`location` varchar(1000)
);

-- --------------------------------------------------------

--
-- Table structure for table `discount`
--

CREATE TABLE `discount` (
  `type` varchar(20) NOT NULL,
  `discount` decimal(4,2) DEFAULT NULL CHECK (`discount` >= 0 and `discount` <= 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `discount`
--

INSERT INTO `discount` (`type`, `discount`) VALUES
('Frequent', '5.00'),
('Gold', '9.00');

-- --------------------------------------------------------

--
-- Table structure for table `flight`
--

CREATE TABLE `flight` (
  `flight_id` int(11) NOT NULL,
  `aircraft_id` int(11) NOT NULL,
  `route_id` int(11) NOT NULL,
  `takeoff_time` datetime NOT NULL,
  `departure_time` datetime NOT NULL,
  `is_active` tinyint(4) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `flight`
--

INSERT INTO `flight` (`flight_id`, `aircraft_id`, `route_id`, `takeoff_time`, `departure_time`, `is_active`) VALUES
(15, 8, 1, '2022-07-09 10:00:00', '2022-07-09 14:00:00', 1),
(16, 1, 1, '2022-07-09 11:00:00', '2022-07-09 15:00:00', 1),
(17, 2, 1, '2022-07-09 09:00:00', '2022-07-09 11:00:00', 1),
(18, 3, 2, '2022-07-09 09:00:00', '2022-07-09 11:00:00', 1),
(19, 4, 2, '2022-07-09 10:00:00', '2022-07-09 12:00:00', 1),
(20, 5, 3, '2022-07-09 10:00:00', '2022-07-09 12:00:00', 1),
(21, 6, 3, '2022-07-09 12:00:00', '2022-07-09 15:00:00', 1),
(22, 7, 4, '2022-07-09 12:00:00', '2022-07-09 15:00:00', 1),
(23, 8, 4, '2022-07-09 10:00:00', '2022-07-09 14:00:00', 1),
(24, 1, 5, '2022-07-09 16:00:00', '2022-07-09 20:00:00', 1),
(25, 2, 5, '2022-07-09 13:00:00', '2022-07-09 23:00:00', 1),
(26, 3, 10, '2022-07-09 13:00:00', '2022-07-09 23:00:00', 1),
(27, 4, 10, '2022-07-09 11:00:00', '2022-07-09 01:00:00', 1),
(28, 5, 11, '2022-07-09 16:00:00', '2022-07-09 20:00:00', 1),
(29, 6, 11, '2022-07-09 20:00:00', '2022-07-09 22:00:00', 1),
(30, 7, 12, '2022-07-09 20:00:00', '2022-07-09 22:00:00', 1),
(31, 8, 12, '2022-07-09 21:00:00', '2022-07-09 23:00:00', 1),
(32, 1, 13, '2022-07-09 21:00:00', '2022-07-09 23:00:00', 1),
(33, 2, 13, '2022-07-09 22:00:00', '2022-07-09 23:00:00', 1),
(34, 3, 19, '2022-07-09 22:00:00', '2022-07-09 23:00:00', 1),
(35, 4, 19, '2022-07-09 03:00:00', '2022-07-09 05:00:00', 1),
(36, 5, 20, '2022-07-09 03:00:00', '2022-07-09 05:00:00', 1),
(37, 6, 21, '2022-07-09 10:00:00', '2022-07-09 12:00:00', 1);

-- --------------------------------------------------------

--
-- Table structure for table `flight_cost`
--

CREATE TABLE `flight_cost` (
  `flight_id` int(11) NOT NULL,
  `class` varchar(10) NOT NULL CHECK (`class` in ('platinum','business','economy')),
  `cost` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `flight_cost`
--

INSERT INTO `flight_cost` (`flight_id`, `class`, `cost`) VALUES
(15, 'Business', '800.00'),
(15, 'Economy', '400.00'),
(15, 'Platinum', '1000.00'),
(16, 'Business', '800.00'),
(16, 'Economy', '400.00'),
(16, 'Platinum', '1000.00'),
(17, 'Business', '800.00'),
(17, 'Economy', '400.00'),
(17, 'Platinum', '1000.00'),
(18, 'Business', '800.00'),
(18, 'Economy', '400.00'),
(18, 'Platinum', '1000.00'),
(19, 'Business', '800.00'),
(19, 'Economy', '400.00'),
(19, 'Platinum', '1000.00'),
(20, 'Business', '800.00'),
(20, 'Economy', '400.00'),
(20, 'Platinum', '1000.00'),
(21, 'Business', '800.00'),
(21, 'Economy', '400.00'),
(21, 'Platinum', '1000.00'),
(22, 'Business', '800.00'),
(22, 'Economy', '400.00'),
(22, 'Platinum', '1000.00'),
(23, 'Business', '800.00'),
(23, 'Economy', '400.00'),
(23, 'Platinum', '1000.00'),
(24, 'Business', '800.00'),
(24, 'Economy', '400.00'),
(24, 'Platinum', '1000.00'),
(25, 'Business', '800.00'),
(25, 'Economy', '400.00'),
(25, 'Platinum', '1000.00'),
(26, 'Business', '800.00'),
(26, 'Economy', '400.00'),
(26, 'Platinum', '1000.00'),
(27, 'Business', '800.00'),
(27, 'Economy', '400.00'),
(27, 'Platinum', '1000.00'),
(28, 'Business', '800.00'),
(28, 'Economy', '400.00'),
(28, 'Platinum', '1000.00'),
(29, 'Business', '800.00'),
(29, 'Economy', '400.00'),
(29, 'Platinum', '1000.00'),
(30, 'Business', '800.00'),
(30, 'Economy', '400.00'),
(30, 'Platinum', '1000.00'),
(31, 'Business', '800.00'),
(31, 'Economy', '400.00'),
(31, 'Platinum', '1000.00'),
(32, 'Business', '800.00'),
(32, 'Economy', '400.00'),
(32, 'Platinum', '1000.00'),
(33, 'Business', '800.00'),
(33, 'Economy', '400.00'),
(33, 'Platinum', '1000.00'),
(34, 'Business', '800.00'),
(34, 'Economy', '400.00'),
(34, 'Platinum', '1000.00'),
(35, 'Business', '800.00'),
(35, 'Economy', '400.00'),
(35, 'Platinum', '1000.00'),
(36, 'Business', '800.00'),
(36, 'Economy', '400.00'),
(36, 'Platinum', '1000.00'),
(37, 'Business', '800.00'),
(37, 'Economy', '400.00'),
(37, 'Platinum', '1000.00');

-- --------------------------------------------------------

--
-- Table structure for table `parent_location`
--

CREATE TABLE `parent_location` (
  `id` int(11) NOT NULL,
  `parent_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `parent_location`
--

INSERT INTO `parent_location` (`id`, `parent_id`) VALUES
(1, 2),
(2, 3),
(4, 5),
(5, 3),
(6, 7),
(8, 7),
(9, 10),
(11, 12),
(12, 10),
(13, 14),
(14, 10),
(15, 16),
(16, 17),
(18, 19),
(19, 17),
(20, 21);

-- --------------------------------------------------------

--
-- Table structure for table `passenger`
--

CREATE TABLE `passenger` (
  `passenger_id` varchar(25) NOT NULL,
  `name` varchar(150) NOT NULL,
  `dob` date NOT NULL,
  `address` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `passenger`
--

INSERT INTO `passenger` (`passenger_id`, `name`, `dob`, `address`) VALUES
('A0000001', 'Kabilan Mahathevan', '1999-03-25', 'No. 45/60, Thirunavatkulam, Vavuniya, Sri Lanka'),
('A0000002', 'Jathavan Mahendrarajah', '2000-01-05', 'No. 36/1, 3rd lane, Pandarikulam, Vavuniya, Srilanka'),
('A0000003', 'John Wick', '1987-03-07', '112 Lower Horseshoe, Mill Neck, New York City, New York, USA.'),
('A0000004', 'Leonardo DiCaprio', '1974-11-11', 'Suite 615, West Hollywood, CA 90069 USA'),
('A0000005', 'Kate Winslet', '1975-10-05', 'Drury House, 34-43 Russell Street London, WC2B5HA, United Kingdom'),
('A0000006', 'Quentin Tarantino', '1963-03-27', '601 Wilshire Blvd. 3rd Floor Beverly Hills, CA 90210-5213. USA'),
('A0000007', 'Mahinda Rajapaksa', '1945-11-18', 'No. 117, Wijerama Mawatha, Colombo 07, Sri Lanka'),
('A0000008', 'Gotabaya Rajapaksa', '1948-06-20', 'No. 26/A, Pangiriwatta Mawatha, Mirihana, Nugegoda, Sri Lanka'),
('A0000009', 'Basil Rajapaksa', '1951-04-27', 'No. 1316, Jayanthipura, Nelum Mawatha, Battaramulla, Sri Lanka'),
('A0000010', 'Goran Peterson', '2010-04-10', 'No. 15, Lotus Avenue, Helineski, Finland'),
('A0000011', 'Arifullah Khan', '2015-04-10', 'No. 1516, Havelok street, Stockholm, Sweden'),
('q', 'q', '2022-06-11', 'q'),
('test1', 'test1', '2022-06-03', 'test1');

-- --------------------------------------------------------

--
-- Table structure for table `port_location`
--

CREATE TABLE `port_location` (
  `id` int(11) NOT NULL,
  `location` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `port_location`
--

INSERT INTO `port_location` (`id`, `location`) VALUES
(20, 'Airport Blvd.'),
(5, 'Bali'),
(15, 'Bang Phli District'),
(19, 'Bangkok'),
(2, 'Banten'),
(13, 'Chennai'),
(9, 'Delhi'),
(18, 'Don Mueang'),
(8, 'Hambantota'),
(10, 'India'),
(3, 'Indonesia'),
(4, 'Kabupaten Badung'),
(6, 'Katunayake'),
(12, 'Maharashtra'),
(11, 'Mumbai'),
(16, 'Samut Prakan'),
(21, 'Singapore'),
(7, 'Sri Lanka'),
(14, 'Tamil Nadu'),
(1, 'Tangerang City'),
(17, 'Thailand');

-- --------------------------------------------------------

--
-- Stand-in structure for view `port_location_with_parent`
-- (See below for the actual view)
--
CREATE TABLE `port_location_with_parent` (
`id` int(11)
,`location` varchar(50)
,`parent_id` int(11)
);

-- --------------------------------------------------------

--
-- Table structure for table `route`
--

CREATE TABLE `route` (
  `route_id` int(11) NOT NULL,
  `origin` int(11) NOT NULL,
  `destination` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `route`
--

INSERT INTO `route` (`route_id`, `origin`, `destination`) VALUES
(1, 1, 2),
(2, 1, 3),
(3, 1, 4),
(4, 1, 5),
(5, 1, 6),
(6, 1, 7),
(7, 1, 8),
(8, 1, 9),
(9, 1, 10),
(10, 2, 1),
(11, 2, 3),
(12, 2, 4),
(13, 2, 5),
(14, 2, 6),
(15, 2, 7),
(16, 2, 8),
(17, 2, 9),
(18, 2, 10),
(19, 3, 1),
(20, 3, 2),
(21, 3, 4),
(22, 3, 5),
(23, 3, 6),
(24, 3, 7),
(25, 3, 8),
(26, 3, 9),
(27, 3, 10),
(28, 4, 1),
(29, 4, 2),
(30, 4, 3),
(31, 4, 5),
(32, 4, 6),
(33, 4, 7),
(34, 4, 8),
(35, 4, 9),
(36, 4, 10),
(37, 5, 1),
(38, 5, 2),
(39, 5, 3),
(40, 5, 4),
(41, 5, 6),
(42, 5, 7),
(43, 5, 8),
(44, 5, 9),
(45, 5, 10),
(46, 6, 1),
(47, 6, 2),
(48, 6, 3),
(49, 6, 4),
(50, 6, 5),
(51, 6, 7),
(52, 6, 8),
(53, 6, 9),
(54, 6, 10),
(55, 7, 1),
(56, 7, 2),
(57, 7, 3),
(58, 7, 4),
(59, 7, 5),
(60, 7, 6),
(61, 7, 8),
(62, 7, 9),
(63, 7, 10),
(64, 8, 1),
(65, 8, 2),
(66, 8, 3),
(67, 8, 4),
(68, 8, 5),
(69, 8, 6),
(70, 8, 7),
(71, 8, 9),
(72, 8, 10),
(73, 9, 1),
(74, 9, 2),
(75, 9, 3),
(76, 9, 4),
(77, 9, 5),
(78, 9, 6),
(79, 9, 7),
(80, 9, 8),
(81, 9, 10),
(82, 10, 1),
(83, 10, 2),
(84, 10, 3),
(85, 10, 4),
(86, 10, 5),
(87, 10, 6),
(88, 10, 7),
(89, 10, 8),
(90, 10, 9);

-- --------------------------------------------------------

--
-- Table structure for table `sessions`
--

CREATE TABLE `sessions` (
  `session_id` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `expires` int(10) UNSIGNED NOT NULL,
  `data` mediumtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `sessions`
--

INSERT INTO `sessions` (`session_id`, `expires`, `data`) VALUES
('Cb3bBef18c8HLJ0YSjwmkuGtwRzxf75w', 1687059088, '{\"cookie\":{\"originalMaxAge\":31536000000,\"expires\":\"2023-06-18T03:31:28.070Z\",\"httpOnly\":false,\"path\":\"/\"},\"userID\":3}'),
('kfScdvB6JFCcfw-8a_k05nsBC05QJU2D', 1687057417, '{\"cookie\":{\"originalMaxAge\":31536000000,\"expires\":\"2023-06-18T03:02:22.930Z\",\"httpOnly\":false,\"path\":\"/\"},\"userID\":1}'),
('m1_pYtOWab2H2y1IGBi20VJOFq51wbS3', 1686916490, '{\"cookie\":{\"originalMaxAge\":31536000000,\"expires\":\"2023-06-16T11:40:25.519Z\",\"httpOnly\":false,\"path\":\"/\"},\"userID\":2}');

-- --------------------------------------------------------

--
-- Table structure for table `ticket`
--

CREATE TABLE `ticket` (
  `ticket_id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `passenger_id` varchar(25) NOT NULL,
  `flight_id` int(11) NOT NULL,
  `seat_number` varchar(5) NOT NULL,
  `date` datetime NOT NULL,
  `class` varchar(10) NOT NULL,
  `paid` decimal(10,2) NOT NULL,
  `status` tinyint(4) NOT NULL DEFAULT 1,
  `is_boarded` tinyint(1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `ticket`
--

INSERT INTO `ticket` (`ticket_id`, `user_id`, `passenger_id`, `flight_id`, `seat_number`, `date`, `class`, `paid`, `status`, `is_boarded`) VALUES
(80, 3, 'q', 2, '1', '2022-06-18 08:22:50', 'Economy', '364.00', -1, 0),
(82, NULL, 'test1', 15, '1', '2022-06-18 08:53:50', 'Economy', '400.00', 1, 0);

-- --------------------------------------------------------

--
-- Table structure for table `user`
--

CREATE TABLE `user` (
  `user_id` int(11) NOT NULL,
  `email` varchar(255) NOT NULL,
  `password` varchar(100) NOT NULL,
  `first_name` varchar(100) NOT NULL,
  `last_name` varchar(100) DEFAULT NULL,
  `role` varchar(30) NOT NULL CHECK (`role` in ('moderator','clerk','user','guest')),
  `discount_type` varchar(20) DEFAULT NULL,
  `is_active` tinyint(4) DEFAULT NULL,
  `dob` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `user`
--

INSERT INTO `user` (`user_id`, `email`, `password`, `first_name`, `last_name`, `role`, `discount_type`, `is_active`, `dob`) VALUES
(1, 'test1_mod@gmail.com', '$2b$09$tkU0Te8xv98Ivor4Nxv7gOqoHc6GVCxn3gXz/iJKox8y.TjZRxBXy', 'mod1', 'mod1', 'moderator', NULL, 1, '1987-03-07'),
(2, 'test1_clr@gmail.com', '$2b$09$.nb0aGqTmcW6XoMH.u6JZeZ63GEJpvtaNx7XepSWqoMOwb2i1rrPe', 'clr_1', 'clr_1', 'clerk', NULL, 1, '1963-03-27'),
(3, 'test1_usr@gmail.com', '$2b$09$/G0kHfffgFWyjrgBu8keYuMS2KSAoMu62NxunfCCyfcJHlmrUq.pK', 'usr_1', 'usr_1', 'user', 'gold', NULL, '2000-01-05');

-- --------------------------------------------------------

--
-- Structure for view `airport_locations`
--
DROP TABLE IF EXISTS `airport_locations`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `airport_locations`  AS SELECT `airport`.`airport_id` AS `id`, `airport`.`code` AS `code`, `airport`.`name` AS `name`, `get_location`(`airport`.`location`) AS `location` FROM `airport``airport`  ;

-- --------------------------------------------------------

--
-- Structure for view `port_location_with_parent`
--
DROP TABLE IF EXISTS `port_location_with_parent`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `port_location_with_parent`  AS SELECT `port_location`.`id` AS `id`, `port_location`.`location` AS `location`, `parent_location`.`parent_id` AS `parent_id` FROM (`port_location` left join `parent_location` on(`port_location`.`id` = `parent_location`.`id`))  ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `aircraft`
--
ALTER TABLE `aircraft`
  ADD PRIMARY KEY (`aircraft_id`),
  ADD UNIQUE KEY `tail_number` (`tail_number`);

--
-- Indexes for table `airport`
--
ALTER TABLE `airport`
  ADD PRIMARY KEY (`airport_id`),
  ADD UNIQUE KEY `code` (`code`);

--
-- Indexes for table `discount`
--
ALTER TABLE `discount`
  ADD PRIMARY KEY (`type`);

--
-- Indexes for table `flight`
--
ALTER TABLE `flight`
  ADD PRIMARY KEY (`flight_id`);

--
-- Indexes for table `flight_cost`
--
ALTER TABLE `flight_cost`
  ADD PRIMARY KEY (`flight_id`,`class`);

--
-- Indexes for table `parent_location`
--
ALTER TABLE `parent_location`
  ADD PRIMARY KEY (`id`,`parent_id`),
  ADD UNIQUE KEY `id` (`id`);

--
-- Indexes for table `passenger`
--
ALTER TABLE `passenger`
  ADD PRIMARY KEY (`passenger_id`);

--
-- Indexes for table `port_location`
--
ALTER TABLE `port_location`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `location` (`location`);

--
-- Indexes for table `route`
--
ALTER TABLE `route`
  ADD PRIMARY KEY (`route_id`),
  ADD UNIQUE KEY `origin` (`origin`,`destination`);

--
-- Indexes for table `sessions`
--
ALTER TABLE `sessions`
  ADD PRIMARY KEY (`session_id`);

--
-- Indexes for table `ticket`
--
ALTER TABLE `ticket`
  ADD PRIMARY KEY (`ticket_id`),
  ADD UNIQUE KEY `flight_id` (`flight_id`,`seat_number`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `passenger_id` (`passenger_id`);

--
-- Indexes for table `user`
--
ALTER TABLE `user`
  ADD PRIMARY KEY (`user_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `aircraft`
--
ALTER TABLE `aircraft`
  MODIFY `aircraft_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `airport`
--
ALTER TABLE `airport`
  MODIFY `airport_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `flight`
--
ALTER TABLE `flight`
  MODIFY `flight_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=38;

--
-- AUTO_INCREMENT for table `port_location`
--
ALTER TABLE `port_location`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=22;

--
-- AUTO_INCREMENT for table `route`
--
ALTER TABLE `route`
  MODIFY `route_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=91;

--
-- AUTO_INCREMENT for table `ticket`
--
ALTER TABLE `ticket`
  MODIFY `ticket_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=83;

--
-- AUTO_INCREMENT for table `user`
--
ALTER TABLE `user`
  MODIFY `user_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
