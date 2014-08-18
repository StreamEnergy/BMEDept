--USE [StreamInternal]

-- --Begin Test Section
--DECLARE @StartDate VARCHAR(7) = '2014-03'
--DECLARE @EndDate VARCHAR(7) = '2014-04'
----End Test Section


 --Begin Test Section
DECLARE @StartDate DATETIME = '01/10/2014'
DECLARE @EndDate DATETIME = '05/31/2014'
DECLARE @SDate VARCHAR(7)
DECLARE @EDate VARCHAR(7)
--End Test Section

SELECT  @SDate = CONVERT(VARCHAR(7) , @StartDate , 120) 
SELECT  @EDate = CONVERT(VARCHAR(7) , @EndDate , 120) 
    
   
SELECT  --'MonthID' = SUBSTRING(N.[YYYY-MM] , 6 , 2)
      [BeginServiceDate]
      , 'Month' = DATENAME(MONTH,[BeginServiceDate])+' '+DATENAME(YEAR,[BeginServiceDate])--,'Year' = 
      , 'Net_New' = COUNT(N.enroll_orig_transaction_id)
FROM    StreamInternal.dbo.[TX_Enroll_Net] N
INNER JOIN StreamInternal.dbo.[TX_Enroll_Summary] S ON S.enroll_orig_transaction_id = N.enroll_orig_transaction_id
AND  S.EnrollType = 'New'
        AND  [BeginServiceDate] >= @StartDate
        AND  [BeginServiceDate] <= @EndDate
GROUP BY [BeginServiceDate]
ORDER BY [BeginServiceDate]--SUBSTRING(N.[YYYY-MM] , 6 , 2)





SELECT  'Month' = [YYYY-MM]
      , 'TOS' = COUNT(enroll_orig_transaction_id)
FROM    StreamInternal.dbo.[TX_Enroll_Summary]
WHERE   EnrollType = 'TOS'
GROUP BY [YYYY-MM]

SELECT  'Month' = [YYYY-MM]
      , 'Recycle1' = COUNT(enroll_orig_transaction_id)
FROM    StreamInternal.dbo.[TX_Enroll_Summary]
WHERE   EnrollType = 'R1'
GROUP BY [YYYY-MM]

SELECT  'Month' = [YYYY-MM]
      , 'Recycle2' = COUNT(enroll_orig_transaction_id)
FROM    StreamInternal.dbo.[TX_Enroll_Summary]
WHERE   EnrollType = 'R2'
GROUP BY [YYYY-MM]


SELECT  'Month' = [YYYY-MM]
      , 'Total_Count' = COUNT(enroll_orig_transaction_id)
FROM    StreamInternal.dbo.[TX_Enroll_Summary]
GROUP BY [YYYY-MM]
--WHERE EnrollType = 'R2'

SELECT TOP 100
        *
FROM    StreamInternal.dbo.[TX_Enroll_Summary]
WHERE   EnrollType = 'R2'