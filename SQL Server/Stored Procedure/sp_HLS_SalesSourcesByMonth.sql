USE [StreamInternal]
GO

/****** Object:  StoredProcedure [dbo].[sp_HLS_SalesSourcesByMonth]    Script Date: 08/25/2014 12:17:06 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





/**********************************************************************************************
==============================================================================================
*********** Notes/Change Log ****************
--============================================================================================
Date				Author						Description
07/23/2014 			Jide Akintoye				Create HLS Customer Sales Sources By Month		



**********************************************************************************************/


CREATE PROCEDURE [dbo].[sp_HLS_SalesSourcesByMonth]
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
--  Temptable to hold Sales Sources by dates
*****************************************************/

        IF OBJECT_ID(N'tempdb..#TempTable2' , N'U') IS NOT NULL
            DROP TABLE #TempTable2;
        CREATE TABLE #TempTable2
            ( SalesSource NVARCHAR(25) ,
              EnrollDate DATETIME ,
              KubraMyAccount INT ,
              MyIgniteRenew INT ,
              MyIgnite INT ,
              PowerCenter INT ,
              NULLSource INT ,
              [Call Center] INT ,
              MyStreamRenew INT ,
              MyStream INT ,
              TotalCount INT
            );
        INSERT  INTO #TempTable2
                SELECT  SalesSource ,
                        EnrollDate ,
                        CASE WHEN SalesSource = 'KubraMyAccount'
                             THEN COUNT(DISTINCT VendorCustomerNumber)
                        END AS KubraMyAccount ,
                        CASE WHEN SalesSource = 'MyIgniteRenew'
                             THEN COUNT(DISTINCT VendorCustomerNumber)
                        END AS MyIgniteRenew ,
                        CASE WHEN SalesSource = 'MyIgnite'
                             THEN COUNT(DISTINCT VendorCustomerNumber)
                        END AS MyIgnite ,
                        CASE WHEN SalesSource = 'PowerCenter'
                             THEN COUNT(DISTINCT VendorCustomerNumber)
                        END AS PowerCenter ,
                        CASE WHEN SalesSource IS NULL
                             THEN COUNT(DISTINCT VendorCustomerNumber)
                        END AS NULLSource ,
                        CASE WHEN SalesSource = 'Call Center'
                             THEN COUNT(DISTINCT VendorCustomerNumber)
                        END AS [Call Center] ,
                        CASE WHEN SalesSource = 'MyStreamRenew'
                             THEN COUNT(DISTINCT VendorCustomerNumber)
                        END AS MyStreamRenew ,
                        CASE WHEN SalesSource = 'MyStream'
                             THEN COUNT(DISTINCT VendorCustomerNumber)
                             ELSE ''
                        END AS MyStream ,
                        'TotalCount' = COUNT(DISTINCT VendorCustomerNumber)
                FROM    [StreamInternal].[dbo].HLS_Customers_Data T
                INNER JOIN #StateLst SL ON T.State = SL.StateAbbr
                INNER JOIN #Status S ON T.CustomerStatus = S.CustomerStatus
                WHERE   EnrollDate >= @StartDate
                        AND EnrollDate <= @EndDate
                GROUP BY EnrollDate ,
                        SalesSource
                ORDER BY EnrollDate

--SELECT * FROM #TempTable2

/****************************************************
-- Sales Sources Account Count by Date (Month)
*****************************************************/
        IF OBJECT_ID(N'tempdb..#TempTable4' , N'U') IS NOT NULL
            DROP TABLE #TempTable4;

        SELECT  'MonthID' = DATEPART(mm , EnrollDate) ,
                'Month' = DATENAME(mm , EnrollDate) + ' ' + DATENAME(YY ,
                                                              EnrollDate) ,
                'KubraMyAccount' = SUM(KubraMyAccount) ,
                'MyIgniteRenew' = SUM(MyIgniteRenew) ,
                'MyIgnite' = SUM(MyIgnite) ,
                'PowerCenter' = SUM(PowerCenter) ,
                'NULLSource' = SUM(NULLSource) ,
                'Call Center' = SUM([Call Center]) ,
                'MyStreamRenew' = SUM(MyStreamRenew) ,
                'MyStream' = SUM(MyStream) ,
                'MonthlyTotal' = SUM(TotalCount)
        INTO    #TempTable4
        FROM    #TempTable2
        GROUP BY DATENAME(mm , EnrollDate) + ' ' + DATENAME(YY , EnrollDate) ,
                DATEPART(mm , EnrollDate)
        ORDER BY DATEPART(mm , EnrollDate)

        SELECT  *
        FROM    #TempTable4	
    END







GO


