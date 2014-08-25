USE [StreamInternal]
GO

/****** Object:  StoredProcedure [dbo].[sp_HLS_ProductByMonth]    Script Date: 08/25/2014 12:17:03 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





/**********************************************************************************************
==============================================================================================
*********** Notes/Change Log ****************
--============================================================================================
Date				Author						Description
07/28/2014 			Jide Akintoye				Create HLS Product Sold By Month


**********************************************************************************************/


CREATE PROCEDURE [dbo].[sp_HLS_ProductByMonth]
    ( @StartDate DATETIME
    , @EndDate DATETIME
    , @State NVARCHAR(MAX)
    , @Status NVARCHAR(MAX)
    )
AS
    BEGIN


--/**BeginTest**/
--DECLARE @StartDate DATETIME = '04/01/2014'
--DECLARE @EndDate DATETIME = '07/15/2014'
--DECLARE @State NVARCHAR (MAX) = '43'
--DECLARE @Status NVARCHAR (100) = ('1,2,3')
----/**EndTest**/


/****************************************************
-- Create Temp Table To hold State List
*****************************************************/ 
        IF OBJECT_ID(N'tempdb..#StateLst' , N'U') IS NOT NULL
            DROP TABLE #StateLst;
        CREATE TABLE #StateLst
            ( State INT
            , StateAbbr NVARCHAR(3)
--,StateID INT
            )
        INSERT  INTO #StateLst
                ( STATE
                , StateAbbr
                )
--DECLARE @State NVARCHAR (MAX) = '10,15'
                SELECT  fs.Element
                      , StateAbbr
                FROM    StreamInternal.dbo.fn_Split(@State , ',') AS FS
                INNER JOIN [dbo].[Lst_State] s ON fs.Element = s.StateID

--Select * from #StateLst
/****************************************************
-- Create Temp Table To hold Customer Status
*****************************************************/ 
        IF OBJECT_ID(N'tempdb..#Status' , N'U') IS NOT NULL
            DROP TABLE #Status;
        CREATE TABLE #Status
            ( CustomerStatusID INT
            , CustomerStatus NVARCHAR(MAX)
            )
        INSERT  INTO #Status
                ( CustomerStatusID
                , CustomerStatus
                )

--DECLARE @Status NVARCHAR (20) = ('1,2')
                SELECT  fs.Element
                      , S.Status
                FROM    StreamInternal.dbo.fn_Split(@Status , ',') AS FS
                INNER JOIN ( SELECT 'StatusID' = 1
                                  , 'Status' = 'Active'
                             UNION
                             SELECT 'StatusID' = 2
                                  , 'Status' = 'Cancelled'
                             UNION
                             SELECT 'StatusID' = 3
                                  , 'Status' = 'Pre-Verify'
                           ) s ON fs.Element = S.StatusID

--Select * from #Status

/****************************************************
--  Temptable to hold Sales Sources by dates
*****************************************************/

        IF OBJECT_ID(N'tempdb..#TempTable2' , N'U') IS NOT NULL
            DROP TABLE #TempTable2;
        CREATE TABLE #TempTable2
            ( Product NVARCHAR(25)
            , EnrollDate DATETIME
            , IdentityProtection INT
            , CreditMonitoring INT
            , TechSupport INT
            ,Family_Addon INT
            , TotalCount INT
            );
        INSERT  INTO #TempTable2
                SELECT  PV.Product
                      , T.EnrollDate
                      , CASE WHEN PV.Product = 'IdentityProtection'
                             THEN COUNT(DISTINCT PV.VendorCustomerNumber)
                        END AS IdentityProtection
                      , CASE WHEN PV.Product = 'CreditMonitoring'
                             THEN COUNT(DISTINCT PV.VendorCustomerNumber)
                        END AS CreditMonitoring
                      , CASE WHEN PV.Product = 'TechSupport'
                             THEN COUNT(DISTINCT PV.VendorCustomerNumber)
                        END AS TechSupport
                      , CASE WHEN PV.Product = 'Family_Addon'
                             THEN COUNT(DISTINCT PV.VendorCustomerNumber)
                        END AS TechSupport
                      , CASE WHEN PV.Product IS NOT NULL
                             THEN COUNT(DISTINCT PV.VendorCustomerNumber)
                        END AS 'TotalCount'-- = COUNT (DISTINCT PV.VendorCustomerNumber)
                FROM    [v_HLS_Product_View] PV
                INNER JOIN [StreamInternal].[dbo].HLS_Customers_Data T ON PV.VendorCustomerNumber = T.VendorCustomerNumber
                INNER JOIN #StateLst SL ON T.State = SL.StateAbbr
                INNER JOIN #Status S ON T.CustomerStatus = S.CustomerStatus
                WHERE   EnrollDate >= @StartDate
                        AND EnrollDate <= @EndDate
                GROUP BY EnrollDate
                      , Product
                ORDER BY EnrollDate

--SELECT * FROM #TempTable2

--/****************************************************
---- Sales Sources Account Count by Date (Month)
--*****************************************************/
        IF OBJECT_ID(N'tempdb..#TempTable4' , N'U') IS NOT NULL
            DROP TABLE #TempTable4;

        SELECT  'MonthID' = DATEPART(mm , EnrollDate)
              , 'Month' = DATENAME(mm , EnrollDate) + ' ' + DATENAME(YY ,
                                                              EnrollDate)
              , 'IdentityProtection' = SUM(IdentityProtection)
              , 'CreditMonitoring' = SUM(CreditMonitoring)
              , 'TechSupport' = SUM(TechSupport)
              , 'Family_Addon' = SUM(Family_Addon)
              , 'MonthlyTotal' = SUM(TotalCount)
        INTO    #TempTable4
        FROM    #TempTable2
        GROUP BY DATENAME(mm , EnrollDate) + ' ' + DATENAME(YY , EnrollDate)
              , DATEPART(mm , EnrollDate)
        ORDER BY DATEPART(mm , EnrollDate)

        SELECT  MonthID
              , Month
              , IdentityProtection
              , CreditMonitoring
              , TechSupport
              , Family_Addon
              , MonthlyTotal
        FROM    #TempTable4	
    END












GO


