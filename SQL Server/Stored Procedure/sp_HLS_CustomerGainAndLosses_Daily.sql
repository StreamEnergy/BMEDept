USE [StreamInternal]
GO

/****** Object:  StoredProcedure [dbo].[sp_HLS_CustomerGainAndLosses_Daily]    Script Date: 08/25/2014 12:16:48 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



/**********************************************************************************************
==============================================================================================
*********** Notes/Change Log ****************
--============================================================================================
Date				Author						DESCRIPTION
07/23/2014 			Jide Akintoye				CREATE Daily HLS Customer Gain AND Losses		


**********************************************************************************************/

CREATE PROCEDURE [dbo].[sp_HLS_CustomerGainAndLosses_Daily]
    ( @StartDate DATETIME ,
      @EndDate DATETIME ,
      @State NVARCHAR(MAX) ,
      @Status NVARCHAR(MAX)
    )
AS
    BEGIN

--/**BeginTest**/
--DECLARE @StartDate DATETIME = '06/01/2014'
--DECLARE @EndDate DATETIME = '06/15/2014'
--DECLARE @State NVARCHAR (MAX) = '43'
--DECLARE @Status NVARCHAR (100) = ('1,3')
----/**EndTest**/


/****************************************************
-- Create Temp Table To hold State List
*****************************************************/ 
        IF OBJECT_ID(N'tempdb..#StateLst' , N'U') IS NOT NULL
            DROP TABLE #StateLst;
        CREATE TABLE #StateLst
            ( State INT ,
              StateAbbr NVARCHAR(3)
--,StateID INT
            )
        INSERT  INTO #StateLst
                ( State ,
                  StateAbbr
                )
--DECLARE @State NVARCHAR (MAX) = '10,15'
                SELECT  fs.Element ,
                        StateAbbr
                FROM    StreamInternal.dbo.fn_Split(@State , ',') AS FS
                INNER JOIN [dbo].[Lst_State] s ON fs.Element = s.StateID

--Select * from #StateLst
/****************************************************
-- Create Temp Table To hold Customer Status
*****************************************************/ 
        IF OBJECT_ID(N'tempdb..#Status' , N'U') IS NOT NULL
            DROP TABLE #Status;
        CREATE TABLE #Status
            ( CustomerStatusID INT ,
              CustomerStatus NVARCHAR(MAX)
            )
        INSERT  INTO #Status
                ( CustomerStatusID ,
                  CustomerStatus
                )

--DECLARE @Status NVARCHAR (20) = ('1,2')
                SELECT  fs.Element ,
                        S.Status
                FROM    StreamInternal.dbo.fn_Split(@Status , ',') AS FS
                INNER JOIN ( SELECT 'StatusID' = 1 ,
                                    'Status' = 'Active'
                             UNION
                             SELECT 'StatusID' = 2 ,
                                    'Status' = 'Cancelled'
                             UNION
                             SELECT 'StatusID' = 3 ,
                                    'Status' = 'Pre-Verify'
                           ) s ON fs.Element = S.StatusID

--Select * from #Status

/****************************************************
----Compile temp table for Monthly Gains and Losses
--*****************************************************/

        IF OBJECT_ID(N'tempdb..#TempTable1' , N'U') IS NOT NULL
            DROP TABLE #TempTable1;
        CREATE TABLE #TempTable1
            ( EnrollDate DATETIME ,
              DailyGainCount INT ,
              DailyCancelCount INT
            )
        INSERT  INTO #TempTable1
                SELECT  'EnrollDate' = CAST (EnrollDate AS DATE) ,
                        'DailyGainCount' = COUNT(DISTINCT VendorCustomerNumber) --Distinct CustomerStatus 
                        ,
                        'DailyCancelCount' = '0'
                FROM    HLS_Customers_Data T
                INNER JOIN #StateLst SL ON T.State = SL.StateAbbr
                INNER JOIN #Status S ON T.CustomerStatus = S.CustomerStatus
                WHERE   EnrollDate IS NOT NULL--between '04/07/2014' and GETDATE()
GROUP BY                EnrollDate
                UNION
                SELECT  'EnrollDate' = CAST (CancelDate AS DATE) ,
                        'DailyGainCount' = '0' ,
                        'DailyCancelCount' = COUNT(DISTINCT VendorCustomerNumber) --Distinct CustomerStatus 
                FROM    HLS_Customers_Data T
                INNER JOIN #StateLst SL ON T.State = SL.StateAbbr
                INNER JOIN #Status S ON T.CustomerStatus = S.CustomerStatus
                WHERE   CancelDate IS NOT NULL--between '04/07/2014' and GETDATE()
                        AND CancelDate >= COALESCE('' ,
                                                   DATEADD(DD , 1 , StartDate))
                GROUP BY CancelDate
--SELECT * FROM #TempTable1

/****************************************************
---- Daily Gains and Losses**
--*****************************************************/
        SELECT  EnrollDate ,
                'DailyGain' = SUM(DailyGainCount) ,
                'DailyLoss' = SUM(DailyCancelCount) ,
                'DailyNetGains' = SUM(DailyGainCount) - SUM(DailyCancelCount)
        FROM    #TempTable1
        WHERE   EnrollDate >= @StartDate
                AND EnrollDate <= @EndDate
        GROUP BY EnrollDate
--,DATENAME (YY, EnrollDate)
--,DATEPART (mm, EnrollDate)
ORDER BY        EnrollDate

    END








GO


