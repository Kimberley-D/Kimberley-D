-- Create a new database called 'PortfolioProject' in which to load the restructured Excel data files
-- Connect to the 'master' database to run this snippet
USE master
GO
-- Create the new database if it does not exist already
IF NOT EXISTS (
    SELECT [name]
        FROM sys.databases
        WHERE [name] = N'PortfolioProject'
)
CREATE DATABASE PortfolioProject
GO 

-- Received the following error when importing data file into Azure;
--- "Failed to convert parameter value from a String to a DateTime" where the Date column was not recognised as a DateTime format. To resolve this I changed the date format in column D of the Excel file from dd/mm/yyyy to yyyy-mm-dd. Other errors occured where the INT values were not recognised and needed to be converted to decimals manually when importing the data file

-- Ensuring the data was loaded correctly by running a test query on both imported tables;
SELECT *
FROM CovidDeaths

SELECT *
FROM CovidVaccinations

