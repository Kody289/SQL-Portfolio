SELECT TOP 100 *
FROM HRdataset

SELECT TOP 100 *
FROM HRdataset h1, HRdataset h2
WHERE h1.employee_name = h2.employee_name
 AND h1.empid != h2.empid

 --Lets seperate the name into their own sections of first and last names
 SELECT TOP 100
	Employee_Name,
	SUBSTRING(Employee_name, CHARINDEX(' ',Employee_Name)+1,LEN(Employee_name) - CHARINDEX(' ', Employee_Name)) AS First_Name,
	SUBSTRING(Employee_Name, 1, CHARINDEX(',', Employee_Name)-1) AS Last_Name
FROM HRdataset

ALTER TABLE HRdataset
ADD First_Name VARCHAR(50), Last_Name VARCHAR(50)

UPDATE HRdataset
SET First_Name = SUBSTRING(Employee_name, CHARINDEX(' ',Employee_Name)+1,LEN(Employee_name) - CHARINDEX(' ', Employee_Name)),
	Last_Name = SUBSTRING(Employee_Name, 1, CHARINDEX(',', Employee_Name)-1)
WHERE First_Name IS NULL


--Lets do some recursions, make heirachies with the EmpID and the ManagerID through the usage of CTE
WITH EmpHier as
(
SELECT
	First_name,Last_name,EmpID,ManagerID,
	1 AS Level
FROM HRdataset
WHERE ManagerID IS NULL
	UNION ALL
SELECT 
	h1.First_name,h1.Last_name,h1.EmpID,h1.ManagerID,
	h2.Level + 1
FROM HRDataset h1
INNER JOIN EmpHier h2
--The -10000 is juse there to actually make the numbers match so the function can actually work
	ON (h2.EmpID-10000)= h1.ManagerID
WHERE h1.ManagerID IS NOT NULL
) 
--CTE is set all we need now is to call upon it
SELECT * 
FROM EmpHier 
ORDER BY empid
--Now some issues with this is the dataset, it realistically makes no sense but the code in itself works


--Lets try our hand at paritions
SELECT
	First_Name, Last_Name, DeptID, Salary,
--This paritions statement works only in this colum and group everything by their DeptID
	SUM(Salary) OVER (PARTITION BY DeptID) AS Total_Per_Department
FROM HRDataset
ORDER BY Total_Per_Department DESC, Salary DESC






