-- #1

CREATE SCHEMA IF NOT EXISTS pandemic;

USE pandemic;

-- #2

DROP TABLE IF EXISTS infectious_cases_normalized;
DROP TABLE IF EXISTS regions;
DROP TABLE IF EXISTS diseases;

CREATE TABLE regions (
 id INT PRIMARY KEY AUTO_INCREMENT,
 name VARCHAR(255) NOT NULL UNIQUE,
 code VARCHAR(255) UNIQUE
);

CREATE TABLE diseases (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255)
);

CREATE TABLE infectious_cases_normalized (
    id INT AUTO_INCREMENT PRIMARY KEY,
    region_id INT,
    year INT,
    disease_id INT,
    cases_number DOUBLE,
    FOREIGN KEY (region_id) REFERENCES regions(id),
    FOREIGN KEY (disease_id) REFERENCES diseases(id)
);

INSERT INTO regions (name, code)
SELECT entity, NULLIF(code, '') FROM infectious_cases GROUP BY entity, code;

INSERT INTO diseases (name)
VALUES
	('yaws'),
	('polio'),
	('guinea_worm'),
	('rabies'),
	('malaria'),
	('hiv'),
	('tuberculosis'),
	('smallpox'),
	('cholera');

DROP PROCEDURE IF EXISTS UpdateColumnValue;

DELIMITER //

CREATE PROCEDURE UpdateColumnValue (
    diseaseName VARCHAR(64),
    diseaseColumnName VARCHAR(64)
)
BEGIN
    -- Змінна для зберігання динамічного SQL-запиту
    SET @sql = CONCAT(
            'INSERT INTO infectious_cases_normalized (region_id, year, disease_id, cases_number) ',
            'SELECT r.id region_id, ic.year, d.id disease_id, ic.' , diseaseColumnName, ' ',
            'FROM infectious_cases ic ',
            'JOIN diseases d ON d.name = \'', diseaseName , '\' ',
            'JOIN regions r ON ic.Entity = r.name ',
            'WHERE ic.' , diseaseColumnName ,' != \'\''
               );

    -- Підготовка запиту
    PREPARE stmt FROM @sql;

    -- Виконання запиту з переданими аргументами
    EXECUTE stmt;

    -- Завершення підготовленого запиту
    DEALLOCATE PREPARE stmt;
END //

DELIMITER ;

CALL UpdateColumnValue('yaws', 'Number_yaws');
CALL UpdateColumnValue('polio', 'polio_cases');
CALL UpdateColumnValue('guinea_worm', 'cases_guinea_worm');
CALL UpdateColumnValue('rabies', 'Number_rabies');
CALL UpdateColumnValue('malaria', 'Number_malaria');
CALL UpdateColumnValue('hiv', 'Number_hiv');
CALL UpdateColumnValue('tuberculosis', 'Number_tuberculosis');
CALL UpdateColumnValue('smallpox', 'Number_smallpox');
CALL UpdateColumnValue('cholera', 'Number_cholera_cases');

-- #3
SELECT
    r.name,
    r.code,
    AVG(icn.cases_number) AS avg_rabies,
    MIN(icn.cases_number) AS min_rabies,
    MAX(icn.cases_number) AS max_rabies,
    SUM(icn.cases_number) AS sum_rabies
FROM
    infectious_cases_normalized icn
        JOIN
    regions r ON icn.region_id = r.id
        JOIN
    diseases d ON icn.disease_id = d.id
WHERE
    d.name = 'rabies'
GROUP BY
    icn.region_id
ORDER BY
    avg_rabies DESC
LIMIT
    10;

-- #4
SELECT
    year,
    MAKEDATE(year, 1) AS start_date,
    CURDATE() AS curr_date,
    TIMESTAMPDIFF(YEAR, MAKEDATE(year, 1), CURDATE()) AS diff_in_years
FROM
    infectious_cases_normalized;


-- #5
DROP FUNCTION IF EXISTS DIFF_IN_YEAR;

DELIMITER //
CREATE FUNCTION DIFF_IN_YEAR(input_year INT)
    RETURNS INT
    DETERMINISTIC
    NO SQL
BEGIN
    RETURN TIMESTAMPDIFF(YEAR, MAKEDATE(input_year, 1), CURDATE());
END//

DELIMITER ;

SELECT
    year,
    MAKEDATE(year, 1) AS start_date,
    CURDATE() AS curr_date,
    DIFF_IN_YEAR(year) AS diff_in_years
FROM
    infectious_cases_normalized;