-- Let's inspect the first 50 rows of the database.

SELECT * 
FROM schools 
LIMIT 50;

-- Count the number of schools not reporting the percentage of students tested and the total number of schools in the database.

SELECT 
	COUNT(DISTINCT school_name) - COUNT(percent_tested) AS num_tested_missing, 
	COUNT(DISTINCT school_name) AS num_schools
FROM schools;


-- Find how many unique schools there are based on building code.

SELECT 
	COUNT(DISTINCT building_code) AS num_school_buildings
FROM schools;

-- Filter the database for all schools with math scores of at least 640.

SELECT school_name, 
	   average_math
FROM schools
WHERE average_math >= 640
ORDER BY average_math DESC;

-- Find the lowest average reading score.

SELECT MIN(average_reading) AS lowest_reading
FROM schools;

-- Filter the database for the top-performing school, as measured by average writing scores.

SELECT school_name, 
	   average_writing AS max_writing
FROM schools
ORDER BY average_writing DESC
LIMIT 1;

-- Create total score scores and find the top 10 best schools.

SELECT school_name, SUM(average_math + average_reading + average_writing) AS average_sat
FROM schools
GROUP BY school_name
ORDER BY average_sat DESC
LIMIT 10;

-- Find out how NYC SAT performance varies by borough.

SELECT borough, COUNT(school_name) AS num_schools, SUM(average_math + average_reading + average_writing)/COUNT(school_name) AS average_borough_sat
FROM schools 
GROUP BY  borough
ORDER BY average_borough_sat DESC;

-- Find the top five best schools in Brooklyn by math score.

SELECT school_name, average_math
FROM schools 
WHERE borough == 'Brooklyn' 
ORDER BY average_math DESC
LIMIT 5;

