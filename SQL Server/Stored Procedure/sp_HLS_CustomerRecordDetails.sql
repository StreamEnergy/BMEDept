USE [StreamInternal]
GO

/****** Object:  StoredProcedure [dbo].[sp_HLS_CustomerRecordDetails]    Script Date: 08/25/2014 12:16:55 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



/**********************************************************************************************
==============================================================================================
*********** Notes/Change Log ****************
--============================================================================================
Date				Author						Description
07/24/2014 			Jide Akintoye				Create HLS Customer Record Details		


**********************************************************************************************/



CREATE PROCEDURE [dbo].[sp_HLS_CustomerRecordDetails]
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
-- Master list of all Customers
*****************************************************/     
        IF OBJECT_ID(N'tempdb..#TempTable' , N'U') IS NOT NULL
            DROP TABLE #TempTable;
        CREATE TABLE #TempTable
            ( [App. Date] DATE ,
              [Cust ID] INT ,
              [Name] NVARCHAR(100) ,
              [Address] NVARCHAR(100) ,
              [City] NVARCHAR(25) ,
              [State] NVARCHAR(10) ,
              [ZipCode] NVARCHAR(20) ,
              [CustomerStatus] NVARCHAR(15) ,
              [ProductCode] NVARCHAR(100) ,
              SalesSource NVARCHAR(100) ,
              AgentID NVARCHAR(25) ,
              AgentName NVARCHAR(100) ,
              [Pre-V] DATE ,
              Active DATE ,
              Cancel DATE
            )
        INSERT  INTO #TempTable
                SELECT  'App. Date' = CAST ([EnrollDate] AS DATE) ,
                        'Cust ID' = [VendorCustomerNumber] ,
                        'Name' = [FirstName] + ' ' + [LastName] ,
                        'Address' = [Address1] + ' ' + [Address2] ,
                        [City] ,
                        [State] ,
                        [ZipCode] ,
                        'Status' = [CustomerStatus] ,
                        CASE WHEN ProductCode = 'seidcrit01'
                             THEN 'Platinum HomeLife Services: 3 Bundle (ID, Tech, CM)'
                             WHEN ProductCode = 'seidcrit02'
                             THEN 'Platinum HomeLife Services: 3 Bundle (ID, Tech, CM) - Waive First Month Fee'
                             WHEN ProductCode = 'seidcr01'
                             THEN 'Gold HomeLife Services: 2 Bundle (ID,CM)'
                             WHEN ProductCode = 'seidcr02'
                             THEN 'Gold HomeLife Services: 2 Bundle (ID,CM) - Waive First Month Fee'
                             WHEN ProductCode = 'seidit02'
                             THEN 'Gold HomeLife Services: 2 Bundle (ID,Tech) - Waive First Month Fee'
                             WHEN ProductCode = 'seid01'
                             THEN 'Silver HomeLife Services: ID Theft (ID)'
                             WHEN ProductCode = 'seid02'
                             THEN 'Silver HomeLife Services: ID Theft (ID) - Waive First Month Fee'
                             WHEN ProductCode = 'seidcrit01'
                             THEN 'Platinum HomeLife Services: 3 Bundle (ID, Tech, CM)'
                             WHEN ProductCode = 'seidcrit02'
                             THEN 'Platinum HomeLife Services: 3 Bundle (ID, Tech, CM) - Waive First Month Fee'
                             WHEN ProductCode = 'seidcr01'
                             THEN 'Gold HomeLife Services: 2 Bundle (ID,CM)'
                             WHEN ProductCode = 'seidcr02'
                             THEN 'Gold HomeLife Services: 2 Bundle (ID,CM) - Waive First Month Fee'
                             WHEN ProductCode = 'secrit02'
                             THEN 'Gold HomeLife Services: 2 Bundle (Tech, CM) - Waive First Month Fee'
                             WHEN ProductCode = 'seidit01'
                             THEN 'Gold HomeLife Services: 2 Bundle (ID,IT)'
                             WHEN ProductCode = 'secrit01'
                             THEN 'Gold HomeLife Services: 2 Bundle (CM, IT)'
                             WHEN ProductCode = 'secr01'
                             THEN 'Silver HomeLife Services: Credit Monitoring (CM)'
                             WHEN ProductCode = 'secr02'
                             THEN 'Silver HomeLife Services: Credit Monitoring (CM) - Waive First Month Fee'
                             WHEN ProductCode = 'seidcrit01'
                             THEN 'Platinum HomeLife Services: 3 Bundle (ID, Tech, CM)'
                             WHEN ProductCode = 'seidcrit02'
                             THEN 'Platinum HomeLife Services: 3 Bundle (ID, Tech, CM) - Waive First Month Fee'
                             WHEN ProductCode = 'seidit02'
                             THEN 'Gold HomeLife Services: 2 Bundle (ID,Tech) - Waive First Month Fee'
                             WHEN ProductCode = 'secrit02'
                             THEN 'Gold HomeLife Services: 2 Bundle (Tech, CM) - Waive First Month Fee'
                             WHEN ProductCode = 'seit01'
                             THEN 'Silver HomeLife Services: Tech Support (Tech)'
                             WHEN ProductCode = 'seit02'
                             THEN 'Silver HomeLife Services: Tech Support (Tech) - Waive First Month Fee'
                             WHEN ProductCode = 'seatechftby'
                             THEN ' Add on Tech with free trial'
                             WHEN ProductCode = 'seatechby '
                             THEN 'Add on tech'
                             WHEN ProductCode = 'seaidftby'
                             THEN 'Add on ID with free trial'
                             WHEN ProductCode = 'seaidby' THEN 'Add on ID'
                             WHEN ProductCode = 'seacrftby'
                             THEN 'Add on Credit with free trial'
                             WHEN ProductCode = 'seacrby' THEN 'Add on Credit'
                             ELSE ProductCode
                        END AS ProductCode ,
                        SalesSource ,
                        'AgentID' = [AssociateNumber] ,
                        'AgentName' = AgentId ,
                        CASE WHEN CustomerStatus = 'Pre-Verify'
                                  OR EnrollDate IS NOT NULL
                             THEN CAST(EnrollDate AS DATE)
                             ELSE NULL
                        END AS 'Pre-V' ,
                        CASE WHEN CustomerStatus = 'Active'
                                  OR StartDate IS NOT NULL
                             THEN CAST(StartDate AS DATE)
                             ELSE NULL
                        END AS 'Active' ,
                        CASE WHEN CustomerStatus = 'Cancelled'
                             THEN CAST(CancelDate AS DATE)
                             ELSE NULL
                        END AS 'Cancel'
                FROM    [StreamInternal].[dbo].[HLS_Customers_Data]
                WHERE   EnrollDate IS NOT NULL
 --AND StartDate IS NOT NULL
 --AND [FirstName] LIKE '%Diane%'
                GROUP BY CAST ([EnrollDate] AS DATE) ,
                        [VendorCustomerNumber] ,
                        [FirstName] + ' ' + [LastName] ,
                        [Address1] + ' ' + [Address2] ,
                        [City] ,
                        [State] ,
                        [ZipCode] ,
                        [CustomerStatus] ,
                        [ProductCode] ,
                        [AssociateNumber] ,
                        AgentId ,
                        EnrollDate ,
                        StartDate ,
                        CancelDate ,
                        SalesSource
    
/****************************************************
--Update Master list with Active Member Dates and Status
*****************************************************/     
        IF OBJECT_ID(N'tempdb..#TempTable1' , N'U') IS NOT NULL
            DROP TABLE #TempTable1;
        CREATE TABLE #TempTable1
            ( [Cust ID] INT ,
              Active DATE ,
              [CustomerStatus] NVARCHAR(15)
            )
        INSERT  INTO #TempTable1
                SELECT  VendorCustomerNumber ,
                        StartDate ,
                        [CustomerStatus]
                FROM    [StreamInternal].[dbo].[HLS_Customers_Data]
                WHERE   [CustomerStatus] = 'Active'

        UPDATE  #TempTable
        SET     #TempTable.[CustomerStatus] = S.[CustomerStatus] ,
                #TempTable.ACTIVE = S.ACTIVE
	--, #TempTable.Active = S.Active
        FROM    #TempTable1 S
        INNER JOIN #TempTable H ON s.[Cust ID] = H.[Cust ID]
 
/****************************************************
--Update Master list with Cancelled Member Dates and Status
*****************************************************/
 
        IF OBJECT_ID(N'tempdb..#TempTable2' , N'U') IS NOT NULL
            DROP TABLE #TempTable2;
        CREATE TABLE #TempTable2
            ( [Cust ID] INT ,
              Cancel DATE
--, Active DATE
              ,
              [CustomerStatus] NVARCHAR(15)
            )
        INSERT  INTO #TempTable2
                SELECT  VendorCustomerNumber ,
                        CancelDate 
		--,StartDate
                        ,
                        [CustomerStatus]
                FROM    [StreamInternal].[dbo].[HLS_Customers_Data]
                WHERE   [CustomerStatus] = 'Cancelled'

        UPDATE  #TempTable
        SET     #TempTable.[CustomerStatus] = S.[CustomerStatus] ,
                #TempTable.Cancel = S.Cancel
	--, #TempTable.Active = S.Active
        FROM    #TempTable2 S
        INNER JOIN #TempTable H ON s.[Cust ID] = H.[Cust ID]
/****************************************************
-- Result list
*****************************************************/  
        SELECT  DISTINCT
                [App. Date] ,
                [Cust ID] ,
                [Name] ,
                [Address] ,
                [City] ,
                T.[State] ,
                [ZipCode] ,
                T.[CustomerStatus] ,
                [ProductCode] ,
                SalesSource ,
                AgentID ,
                AgentName ,
                [Pre-V] ,
                Active ,
                Cancel
        FROM    #TempTable T
        INNER JOIN #StateLst SL ON T.State = SL.StateAbbr
        INNER JOIN #Status S ON T.CustomerStatus = S.CustomerStatus
        WHERE   [Pre-V] >= @StartDate
                AND [Pre-V] < @EndDate
 --AND T.[CustomerStatus]= @Status
 --where Cancel is not null
 --where Name LIKE '%Rashad%'
  --SELECT  * FROM #TempTable1

 --SELECT * FROM [StreamInternal].[dbo].[HLS_Customers_Data] --ORDER BY EnrollDate
 --WHERE  [FirstName] LIKE '%Diane%'--VendorCustomerNumber IN(  '214221046')--, '214104868')
    END








GO


