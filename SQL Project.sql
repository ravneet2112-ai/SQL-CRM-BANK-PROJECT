
CREATE DATABASE CRM_PROJECT;

USE CRM_PROJECT;
-- Updated the 'bankDOJ' column to proper DATE format
SET SQL_SAFE_UPDATES = 0;
UPDATE customerinfo
SET BankDOJ = STR_TO_DATE(bankDOJ, '%Y-%m-%d');

-- Changed the column type from VARCHAR to DATE
ALTER TABLE customerinfo
MODIFY COLUMN bankDOJ DATE;

-- Special characters in the surname column have been replaced with blanks during the data cleaning process.
UPDATE customerinfo
SET surname = replace(surname,'?','');

select surname, locate('?',surname) from customerinfo
WHERE surname REGEXP '[^a-zA-Z ]' and locate('?',surname)<>0;

-- In reference to question 26, there were data discrepancies in the IsActiveMember and Exited columns.
-- Customers marked as exited were incorrectly labeled as active, which is not possible.
-- This issue affected 735 rows.
-- The discrepancies have now been corrected.
UPDATE bankchurn
SET IsActiveMember = 0
WHERE Exited = 1 AND IsActiveMember = 1;

select * from bankchurn where Exited=1 and IsActiveMember=1;


SELECT * FROM customerinfo;
SELECT * FROM bankchurn;

-- Objective Questions

-- 1 What is the distribution of account balances across different regions?
-- Solution 
select c.Geography,
count(c.CustomerId) as number_of_customers,
round(avg(b.balance),2) as average_balance,
round(sum(b.Balance),2)as total_account_balance
from customerinfo c
inner join bankchurn b
on c.CustomerId=b.CustomerId
group by 1;

-- 2 Identify the top 5 customers with the highest Estimated Salary in the last quarter of the year. (SQL)
-- Solution
select 
CustomerId,Surname,
bankdoj,EstimatedSalary
from customerinfo
where extract(month from bankdoj) in (10,11,12)
order by EstimatedSalary desc
limit 5;

-- 3 Calculate the average number of products used by customers who have a credit card. (SQL)
-- Solution
select avg(numofproducts) as avg_of_products
from bankchurn
where HasCrCard = 1;

-- 4 Determine the churn rate by gender for the most recent year in the dataset.
-- Solution
select c.Gender,
count(b.customerid) as churncustomers
from bankchurn b
inner join customerinfo c
on c.CustomerId=b.CustomerId
where year(c.BankDOJ) = 2019 and b.ExitCustomer = 'Exit'
group by 1;

-- 5 Compare the average credit score of customers who have exited and those who remain. (SQL)
-- Solution
SELECT Exited,
       AVG(CreditScore) AS avg_credit_score
FROM bankchurn
GROUP BY Exited;
-- or we can also solve the same using CTE (Comman table expression)
WITH cte1 AS 
(SELECT 'Exit' AS status,
AVG(CreditScore) AS avg_credit_score
FROM bankchurn
WHERE  ExitCustomer = 'Exit'),
cte2 AS 
(SELECT 'Retain' AS status,
AVG(CreditScore) AS avg_credit_score
FROM bankchurn
WHERE ExitCustomer = 'Retain')
SELECT
cte1.avg_credit_score AS avg_credit_score_of_exit_customers,
cte2.avg_credit_score AS avg_credit_score_of_retain_customers,
(cte2.avg_credit_score-cte1.avg_credit_score) AS compared_avg
FROM cte1 inner JOIN cte2 on 1=1;


-- 6 Which gender has a higher average estimated salary, and how does it relate to the number of active accounts? (SQL)
-- Solution
WITH CTE1 AS 
(SELECT c.Gender,AVG(c.EstimatedSalary) AS AvgSalary,
SUM(CASE WHEN b.ActiveCustomer = 'Active Member' THEN 1 ELSE 0 END) AS ActiveAccounts
FROM customerinfo c
inner join bankchurn b ON c.CustomerId = b.CustomerId
GROUP BY c.Gender)
SELECT Gender,ROUND(AvgSalary, 2) AS AvgSalary,ActiveAccounts
FROM CTE1 order by AvgSalary desc limit 1;


-- 7 Segment the customers based on their credit score and identify the segment with the highest exit rate. (SQL)
-- Solution
WITH CreditScoreSegments AS (SELECT
CASE WHEN CreditScore BETWEEN 800 AND 850 THEN 'Excellent'
WHEN CreditScore BETWEEN 740 AND 799 THEN 'Very Good'
WHEN CreditScore BETWEEN 670 AND 739 THEN 'Good'
WHEN CreditScore BETWEEN 580 AND 669 THEN 'Fair'
WHEN CreditScore BETWEEN 300 AND 579 THEN 'Poor'
ELSE 'Unknown'END AS CreditScoreSegment, 
COUNT(*) AS TotalCustomers,
SUM(Exited) AS ChurnedCustomers,
100 * SUM(Exited) / COUNT(*) AS ExitRate FROM Bankchurn
GROUP BY CreditScoreSegment)
SELECT CreditScoreSegment,TotalCustomers,ChurnedCustomers,ExitRate
FROM CreditScoreSegments
ORDER BY ExitRate DESC
LIMIT 1;


-- 8 Find out which geographic region has the highest number of active customers with a tenure greater than 5 years. (SQL)
-- Solution
select c.Geography,
count(b.customerid) as number_of_customers
from customerinfo c
inner join bankchurn b
on c.CustomerId=b.CustomerId
where b.IsActiveMember =1 and Tenure > 5
group by 1
order by 2 desc
limit 1;


-- 9 What is the impact of having a credit card on customer churn, based on the available data?
-- Solution
Select 
    CreditCard,
    SUM(Case When ActiveCustomer = 'Active Member' Then 1 Else 0 END) AS ActiveCustomers,
    SUM(Case When ActiveCustomer = 'Inactive Member' Then 1 Else 0 END) AS InactiveCustomers,
    SUM(Case When ExitCustomer = 'Exit' Then 1 ELSE 0 END) AS ExitCustomers,
    SUM(Case WHen ExitCustomer = 'Retain' Then 1 Else 0 END) AS RetainedCustomers,
    COUNT(customerID) AS OverallTotalCustomers
From bankchurn
Group by CreditCard;


-- 10 What is the impact of having a credit card on customer churn, based on the available data?
-- Solution
Select
    NumofProducts,
    COUNT(CustomerID) AS NumOfCustomers
From Bankchurn
Where ExitCustomer = 'Exit'
Group by NumofProducts
Order by NumofCustomers DESC
LIMIT 1;

-- 11 Examine the trend of customers joining over time and identify any seasonal patterns (yearly or monthly). Prepare the data through SQL and then visualize it.
-- Solution
--      Prepare the data through SQL and then visualize it.
-- Yearly Trend
Select 
    YEAR(BankDOJ) AS JoiningYear,
    COUNT(CustomerID) AS NumofCustomers
From customerINFO
Group by JoiningYear
Order by joiningyear;

-- Monthly Trend
Select 
    YEAR(BankDOJ) AS JoiningYear,
    Month(BankDOJ) AS JoiningMonth,
    COUNT(customerID) AS NumOfCustomers
From customerInfo
Group by JoiningYear, JoiningMonth
Order by JoiningYear, JoiningMonth;

-- 12 Analyze the relationship between the number of products and the account balance for customers who have exited.
-- Solution
Select
    NumofProducts,
    round(AVG(Balance),2) AS AvgBalance,
    MIN(Balance) AS MinBalance,
    MAX(Balance) AS MaxBalance,
    round(SUM(Balance),2) AS TotalBalance
From BankChurn
WHere ExitCustomer = 'Exit'
Group by NumofProducts;

-- 13 Identify any potential outliers in terms of balance among customers who have remained with the bank.
-- Solution
Select
   customerID,
   Exitcustomer,
   Balance
From Bankchurn
Where ExitCustomer LIKE 'Retain'
Order by Balance DESC;

-- 14 How many different tables are given in the dataset, out of these tables which table only consists of categorical variables?
-- Solution
-- I have provided the answer of the given question in word file.


-- 15 Using SQL, write a query to find out the gender-wise average income of males and females in each geography id. Also, rank the gender according to the average value. (SQL)
-- Solution
WITH GenderAvgIncome AS 
(SELECT Geography,Gender,
AVG(EstimatedSalary) AS AvgIncome
FROM customerinfo GROUP BY 1,2),
RankedGenderAvgIncome AS 
(SELECT Geography, Gender,AvgIncome,
        RANK() OVER (PARTITION BY Geography ORDER BY AvgIncome DESC) AS Ranked
FROM GenderAvgIncome)
SELECT Geography,Gender,round(AvgIncome ,2)as AvgIncome,Ranked
FROM RankedGenderAvgIncome
ORDER BY Geography, Ranked;

-- 16 Using SQL, write a query to find out the average tenure of the people who have exited in each age bracket (18-30, 30-50, 50+).
-- Solution
Select Case 
   When AGE Between 18 And 30 Then '18-30'
   When AGE Between 31 and 50 Then '31-50'
   ELSE '50+' END AS AgeBracket,
   ROUND(AVG(tenure),2) AS AverageTenure
From customerinfo c
JOIN Bankchurn b ON
c.customerID = b.customerID
Where ExitCustomer = 'Exit'
Group by AgeBracket;

-- 17 Is there any direct correlation between salary and the balance of the customers? And is it different for people who have exited or not?
-- Solution
-- Correlation Coefficient for All Customers
SELECT 
    ROUND((COUNT(*) * SUM(EstimatedSalary * Balance) - SUM(EstimatedSalary) * SUM(Balance)) / 
    SQRT((COUNT(*) * SUM(EstimatedSalary * EstimatedSalary) - POW(SUM(EstimatedSalary), 2)) * 
    (COUNT(*) * SUM(Balance * Balance) - POW(SUM(Balance), 2))),4) AS Correlation_AllCustomers
FROM bankchurn ch
    join customerinfo c on c.CustomerId=ch.CustomerId;
    
    -- Correlation Coefficient for Exited customer 
SELECT 
    ROUND((COUNT(*) * SUM(EstimatedSalary * Balance) - SUM(EstimatedSalary) * SUM(Balance)) / 
    SQRT((COUNT(*) * SUM(EstimatedSalary * EstimatedSalary) - POW(SUM(EstimatedSalary), 2)) * 
    (COUNT(*) * SUM(Balance * Balance) - POW(SUM(Balance), 2))),4) AS Correlation_churned_Customers
FROM bankchurn ch
    join customerinfo c on c.CustomerId=ch.CustomerId
WHERE Exited = 1;

-- Correlation Coefficient for not Retained customer 
SELECT 
    ROUND((COUNT(*) * SUM(EstimatedSalary * Balance) - SUM(EstimatedSalary) * SUM(Balance)) / 
    SQRT((COUNT(*) * SUM(EstimatedSalary * EstimatedSalary) - POW(SUM(EstimatedSalary), 2)) * 
    (COUNT(*) * SUM(Balance * Balance) - POW(SUM(Balance), 2))),4) AS Correlation_not_churned_Customers
FROM bankchurn ch
    join customerinfo c on c.CustomerId=ch.CustomerId
WHERE Exited = 0;


-- 18 Is there any correlation between the salary and the Credit score of customers?
-- Solution
SELECT ROUND((COUNT(*) * SUM(EstimatedSalary * CreditScore) - SUM(EstimatedSalary) * SUM(CreditScore)) / 
    SQRT((COUNT(*) * SUM(EstimatedSalary * EstimatedSalary) - POW(SUM(EstimatedSalary), 2)) * 
    (COUNT(*) * SUM(CreditScore * CreditScore) - POW(SUM(CreditScore), 2))),4) AS Correlation_Salary_CreditScore
FROM customerinfo c join bankchurn ch on c.customerid=ch.CustomerId;


-- 19.	Rank each bucket of credit score as per the number of customers who have churned the bank.
SELECT CASE
WHEN CreditScore BETWEEN 800 AND 850 THEN 'Excellent'
WHEN CreditScore BETWEEN 740 AND 799 THEN 'Very Good'
WHEN CreditScore BETWEEN 670 AND 739 THEN 'Good'
WHEN CreditScore BETWEEN 580 AND 669 THEN 'Fair'
WHEN CreditScore BETWEEN 300 AND 579 THEN 'Poor'
ELSE 'Unknown'END AS CreditScoreCaregory, COUNT(*) AS NumChurnedCustomers,
DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS CreditRank
FROM Bankchurn
WHERE ExitCustomer = 'Exit'
GROUP BY CreditScoreCaregory
ORDER BY CreditRank;

-- 20.	According to the age buckets find the number of customers who have a credit card. 
-- Also retrieve those buckets that have lesser than average number of credit cards per bucket.

SELECT CASE 
WHEN Age BETWEEN 18 AND 30 THEN '18-30'
WHEN Age BETWEEN 30 AND 50 THEN '30-50'
WHEN Age >= 50 THEN '50+' ELSE 'Unknown' END AS AgeBucket,
COUNT(*) AS NumofCustomers FROM customerinfo c
JOIN bankchurn bc on c.CustomerId=bc.CustomerId
WHERE  CreditCard=1
group by AgeBucket;
-----------------------------------
WITH CreditCardCounts AS 
(SELECT CASE
WHEN Age BETWEEN 18 AND 30 THEN '18-30'
WHEN Age BETWEEN 31 AND 50 THEN '31-50'
WHEN Age >= 51 THEN '50+'
ELSE 'Unknown'END AS AgeBucket,
SUM(CreditCard) AS CreditCardCount,
COUNT(*) AS TotalCustomers
FROM customerinfo c join bankchurn  bc on c.CustomerId=bc.CustomerId
GROUP BY AgeBucket),
AverageCreditCards AS 
(SELECT AVG(CreditCardCount) AS AvgCreditCards 
FROM CreditCardCounts)
SELECT AgeBucket,CreditCardCount,TotalCustomers
FROM CreditCardCounts
WHERE CreditCardCount < (SELECT AvgCreditCards FROM AverageCreditCards);

-- 21.Rank the Locations as per the number of people who have churned the bank and average balance of the customers.
-- Solution
WITH LocationChurnStats AS 
(SELECT Geography,
COUNT(*) AS NumChurnedCustomers,
ROUND(AVG(Balance),2) AS AvgBalance
FROM customerinfo c
JOIN Bankchurn bc ON c.CustomerId = bc.CustomerId
WHERE Exited = 1 GROUP BY Geography)
SELECT Geography, NumChurnedCustomers, AvgBalance,
RANK() OVER (ORDER BY NumChurnedCustomers DESC, AvgBalance DESC) AS LocationRank
FROM LocationChurnStats
ORDER BY LocationRank;

-- 22.	As we can see that the “CustomerInfo” table has the CustomerID and Surname, 
-- now if we have to join it with a table where the primary key is also a combination of CustomerID and Surname, 
-- come up with a column where the format is “CustomerID_Surname”.
#Solution
#I have provided the answer of the given question in word file.

-- 23.	Without using “Join”, can we get the “ExitCategory” from ExitCustomers table to Bank_Churn table? If yes do this using SQL.	
-- Solution Yes, we can retrieve the “ExitCategory” from the ExitCustomers table using a subquery in SQL. 
#       However, I have already performed this step in Excel while cleaning the data and given below is the 
#       query for the same.
SELECT *,
    (SELECT e.ExitCategory 
     FROM ExitCustomers e 
     WHERE e.ExitID = b.Exited) AS ExitCategory
FROM BankChurn b;

-- 24.	Were there any missing values in the data, using which tool did you replace them and what are the ways to handle them?
-- Solution 
-- No there were no any missing data found from my side.

-- 25.	Write the query to get the customer IDs, their last name, 
-- and whether they are active or not for the customers whose surname ends with “on”.
-- Solution
select c.CustomerId,c.Surname,b.ActiveCustomer
from customerinfo c
inner join bankchurn b
on c.CustomerId=b.CustomerId
where c.Surname like "%on";

-- 26.	Can you observe any data disrupency in the Customer’s data? 
-- As a hint it’s present in the IsActiveMember and Exited columns. 
-- One more point to consider is that the data in the Exited Column is absolutely correct and accurate.


-- Subjective Questions

-- 9.	Utilize SQL queries to segment customers based on demographics and account details.

-- Segmenting by Geography
Select
    Geography,
    COUNT(CustomerID) AS CustomerCount
From CustomerInfo
Group by Geography
Order by CustomerCount DESC;

-- Segmenting by Age Group
Select
    Case
         When Age Between 18 AND 30 Then '18-30'
         When Age Between 31 AND 50 Then '31-50'
         Else '50+' 
	  END AS AgeGroup,
	COUNT(CustomerID) AS CustomerCount
From CustomerInfo
Group by AgeGroup;

-- Segmenting by Number of Products
Select
    NumofProducts,
    COUNT(CustomerID) AS CustomersCount
From Bankchurn
Group by NumofProducts
Order by CustomersCount DESC;

-- Segmenting by Credit Score
SELECT CASE
WHEN CreditScore BETWEEN 800 AND 850 THEN 'Excellent'
WHEN CreditScore BETWEEN 740 AND 799 THEN 'Very Good'
WHEN CreditScore BETWEEN 670 AND 739 THEN 'Good'
WHEN CreditScore BETWEEN 580 AND 669 THEN 'Fair'
WHEN CreditScore BETWEEN 300 AND 579 THEN 'Poor'
ELSE 'Unknown'END AS CreditScoreCaregory, COUNT(*) AS NumChurnedCustomers,
DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS CreditRank
FROM Bankchurn
WHERE ExitCustomer = 'Exit'
GROUP BY CreditScoreCaregory
ORDER BY CreditRank;

-- 14 Is the “Bank_Churn” table how can you modify the name of the “HasCrCard” column to “Has_creditcard”?
-- Solution

ALTER TABLE bankchurn
RENAME COLUMN HasCrCard To Has_CreditCard;

SELECT * FROM bankchurn;