USE [StreamInternal]
GO

/****** Object:  StoredProcedure [dbo].[sp_ERCOT_RFWD]    Script Date: 08/25/2014 12:16:39 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





/*
============================================================================
************************** Notes/Change Log *******************************
==========================================================================
Date				Author						Description
08/07/2014 			Jide Akintoye				Count # of TX Net Additions, and Attritions,
												and Total count of LDC @ the Begin and 
												End of the month per ERcot



==========================================================================						   
*/

CREATE PROCEDURE [dbo].[sp_ERCOT_RFWD]
    ( @SDate DATETIME
    , @EDate DATETIME
--, @State NVARCHAR (MAX) 
--, @Status NVARCHAR (MAX) 

    )
AS
BEGIN


--Begin Test Section
--    DECLARE @SDate DATETIME = '01/01/2010'
--    DECLARE @EDate DATETIME = '06/15/2010'
--End Test Section

--Avoiding Parameter Sniffing
    DECLARE @StartDate AS DATETIME = @SDate
    DECLARE @EndDate AS DATETIME = @EDate
 

    IF OBJECT_ID(N'tempdb..#ERCOTCount' , N'U') IS NOT NULL
        DROP TABLE #ERCOTCount;
    CREATE TABLE #ERCOTCount
        ( MonthID NVARCHAR(10)
        , ServiceMonth NVARCHAR(50)
        , Dimension NVARCHAR(20)
        , RecordCount INT
        ); 
    INSERT  INTO #ERCOTCount
    
/**************************************************
/*Begin ERCOTTrue Count*/
***************************************************/
            SELECT --DISTINCT
                    'MonthID' = CONVERT(VARCHAR(7) , ErcotDate , 120)--ErcotDate + 1--
                  , 'ServiceMonth' = SUBSTRING(DATENAME(MONTH , ErcotDate) , 1 ,
                                               3) + ' ' + DATENAME(YEAR ,
                                                              ErcotDate)
                  , 'Dimension' = 'TrueBegin||ERCOT'--CountType
                  , RecordCount
            FROM    StreamInternal.[dbo].[ERCOT_Numbers]
            WHERE   CountType = 'Begin'
                    AND ErcotDate >= @StartDate
                    AND ErcotDate <= @EndDate
            UNION ALL
/**************************************************
/*Begin ERCOT Count*/
            ***************************************************/
            SELECT --DISTINCT
                    'MonthID' = CONVERT(VARCHAR(7) , ErcotDate + 1 , 120)--ErcotDate + 1--
                  , 'ServiceMonth' = SUBSTRING(DATENAME(MONTH , ErcotDate + 1) ,
                                               1 , 3) + ' ' + DATENAME(YEAR ,
                                                              ErcotDate + 1)
                  , 'Dimension' = 'Begin||ERCOT'--CountType
                  , RecordCount
            FROM    StreamInternal.[dbo].[ERCOT_Numbers]
            WHERE   CountType = 'End'
                    AND ErcotDate + 1 >= @StartDate
                    AND ErcotDate + 1 <= @EndDate
            UNION ALL
/**************************************************
Count ALL New Customer Additions*
***************************************************/
            SELECT DISTINCT --TOP 1000
                    'MonthID' = CONVERT(VARCHAR(7) , [BeginServiceDate] , 120)--[BeginServiceDate]--
                  , 'ServiceMonth' = SUBSTRING(DATENAME(MONTH ,
                                                        [BeginServiceDate]) ,
                                               1 , 3) + ' ' + DATENAME(YEAR ,
                                                              [BeginServiceDate])
                  , 'Dimension' = 'CustAddition'
                  , 'RecordCount' = COUNT(DISTINCT enroll_orig_transaction_id)
            FROM    StreamInternal.dbo.TX_Enroll_Net
            WHERE   BeginServiceDate >= @StartDate
                    AND BeginServiceDate <= @EndDate
            GROUP BY SUBSTRING(DATENAME(MONTH , [BeginServiceDate]) , 1 , 3)
                    + ' ' + DATENAME(YEAR , [BeginServiceDate])
                  , DATEPART(MONTH , BeginServiceDate)
                  , CONVERT(VARCHAR(7) , [BeginServiceDate] , 120)
--ORDER BY CONVERT(VARCHAR(7) , [BeginServiceDate] , 120)
            UNION ALL
/**************************************************
--Count ALL Customer Dropped*
***************************************************/
            SELECT DISTINCT --TOP 1000
                    'MonthID' = CONVERT(VARCHAR(7) , EndServiceDate , 120)--EndServiceDate--
                  , 'ServiceMonth' = SUBSTRING(DATENAME(MONTH , EndServiceDate) ,
                                               1 , 3) + ' ' + DATENAME(YEAR ,
                                                              EndServiceDate)
                  , 'Dimension' = 'CustAttrition'
                  , 'RecordCount' = COUNT(DISTINCT drop_sender_transaction_id)
            FROM    StreamInternal.dbo.TX_Drop_Net
            WHERE   EndServiceDate >= @StartDate
                    AND EndServiceDate <= @EndDate
            GROUP BY SUBSTRING(DATENAME(MONTH , EndServiceDate) , 1 , 3) + ' '
                    + DATENAME(YEAR , EndServiceDate)
                  , DATEPART(MONTH , EndServiceDate)
                  , CONVERT(VARCHAR(7) , EndServiceDate , 120)
--ORDER BY MonthID
            UNION ALL    
/**************************************************
/*End Premise Count*/
            ***************************************************/
            SELECT --DISTINCT
                    'MonthID' = CONVERT(VARCHAR(7) , ErcotDate , 120)--ErcotDate--
                  , 'ServiceMonth' = SUBSTRING(DATENAME(MONTH , ErcotDate) , 1 ,
                                               3) + ' ' + DATENAME(YEAR ,
                                                              ErcotDate)
                  , 'Dimension' = 'End||ERCOT'--CountType
                  , RecordCount
            FROM    StreamInternal.[dbo].[ERCOT_Numbers]
            WHERE   CountType = 'End'
                    AND ErcotDate >= @StartDate
                    AND ErcotDate <= @EndDate
           
   
/**************************************************
/*Bring it all together into one table*/
***************************************************/  
 
    IF OBJECT_ID(N'tempdb..#FinalTable' , N'U') IS NOT NULL
        DROP TABLE #FinalTable;
    CREATE TABLE #FinalTable
        ( MonthID NVARCHAR(10)
        , ServiceMonth NVARCHAR(50)
        , [TrueBegin] INT
        , [Begin] INT
        , CustAddition INT
        , CustAttrition INT
        , [End] INT
        ); 
    INSERT  INTO #FinalTable
            SELECT  MonthID
                  , ServiceMonth
                  , CASE WHEN Dimension = 'TrueBegin||ERCOT'
                         THEN SUM(RecordCount)
                    END AS [TrueBegin]
                  , CASE WHEN Dimension = 'Begin||ERCOT' THEN SUM(RecordCount)
                    END AS [Begin]
                  , CASE WHEN Dimension = 'CustAddition' THEN SUM(RecordCount)
                    END AS [CustAddition]
                  , CASE WHEN Dimension = 'CustAttrition'
                         THEN SUM(RecordCount)
                    END AS [CustAttrition]
                  , CASE WHEN Dimension = 'End||ERCOT' THEN SUM(RecordCount)
                    END AS [End]
            --INTO    #FinalTable
            FROM    #ERCOTCount
            GROUP BY MonthID
                  , ServiceMonth
                  , Dimension
            ORDER BY MonthID;
            
             
/**************************************************
/*Select ERCOTRfwd ATTRITION Plug into table*/
***************************************************/  
 
    IF OBJECT_ID(N'tempdb..#AttritionPlug' , N'U') IS NOT NULL
        DROP TABLE #AttritionPlug;
    CREATE TABLE #AttritionPlug
        ( MonthID NVARCHAR(10)
        , ServiceMonth NVARCHAR(50)
        , [Begin||ERCOT] INT
        , CustAddition INT
        , CustAttrition INT
        , [End||ERCOT] INT
        ); 
   
    WITH    ERCOTRfwd
              AS ( SELECT   MonthID
                          , ServiceMonth
                          , [Begin||ERCOT] = SUM([Begin])
                          , CustAddition = SUM(CustAddition)
                          , CustAttrition = SUM(CustAttrition)
                          , [End||ERCOT] = SUM([End])
                   FROM     #FinalTable
                   GROUP BY MonthID
                          , ServiceMonth
                 )
        INSERT  INTO #AttritionPlug
                SELECT  MonthID
                      , ServiceMonth
                      , [Begin||ERCOT]
                      , CustAddition
                      , CustAttrition = ( [Begin||ERCOT] - [End||ERCOT] )
                        + CustAddition
                      , [End||ERCOT]
                FROM    ERCOTRfwd
                ORDER BY MonthID;
          --SELECT *
          --FROM #AttritionPlug
          --IF OBJECT_ID(N'tempdb..dbo.TX_ERCOTAttrPlug' , N'U') IS NOT NULL
        DROP TABLE dbo.TX_ERCOTAttrPlug;
    CREATE TABLE dbo.TX_ERCOTAttrPlug
        ( MonthID NVARCHAR(10)
        , ServiceMonth NVARCHAR(50)
        , Dimension NVARCHAR(20)
        , RecordCount INT
        ); 
    INSERT  INTO dbo.TX_ERCOTAttrPlug
            SELECT  MonthID
                  , ServiceMonth
                  , Dimension = 'Begin||ERCOT'
                  , CASE WHEN [Begin||ERCOT] IS NOT NULL THEN [Begin||ERCOT]
                    END AS RecordCount
            FROM    #AttritionPlug
            UNION
            SELECT  MonthID
                  , ServiceMonth
                  , Dimension = 'CustAddition'
                  , CASE WHEN CustAddition IS NOT NULL THEN CustAddition
                    END AS RecordCount
            FROM    #AttritionPlug
            UNION
            SELECT  MonthID
                  , ServiceMonth
                  , Dimension = 'CustAttrition'
                  , CASE WHEN CustAttrition IS NOT NULL THEN CustAttrition
                    END AS RecordCount
            FROM    #AttritionPlug
            UNION
            SELECT  MonthID
                  , ServiceMonth
                  , Dimension = 'End||ERCOT'
                  , CASE WHEN [End||ERCOT] IS NOT NULL THEN [End||ERCOT]
                    END AS RecordCount
            FROM    #AttritionPlug
                                
    --SELECT  *
 
    --FROM    dbo.TX_ERCOTAttrPlug  
/**************************************************
/*Select ERCOTRfwd ADDITION Plug into table*/
***************************************************/  
 
    IF OBJECT_ID(N'tempdb..#AdditionPlug' , N'U') IS NOT NULL
        DROP TABLE #AdditionPlug;
    CREATE TABLE #AdditionPlug
        ( MonthID NVARCHAR(10)
        , ServiceMonth NVARCHAR(50)
        , [Begin||ERCOT] INT
        , CustAddition INT
        , CustAttrition INT
        , [End||ERCOT] INT
        );            
    WITH    ERCOTRfwd
              AS ( SELECT   MonthID
                          , ServiceMonth
                          , [Begin||ERCOT] = SUM([Begin])
                          , CustAddition = SUM(CustAddition)
                          , CustAttrition = SUM(CustAttrition)
                          , [End||ERCOT] = SUM([End])
                   FROM     #FinalTable
                   GROUP BY MonthID
                          , ServiceMonth
                 )
        INSERT  INTO #AdditionPlug
                SELECT  MonthID
                      , ServiceMonth
                      , [Begin||ERCOT]
                      , CustAddition = ( [End||ERCOT] - [Begin||ERCOT] )
                        + CustAttrition
                      , CustAttrition
                      , [End||ERCOT]
                FROM    ERCOTRfwd
                ORDER BY MonthID;
                
                
    --IF OBJECT_ID(N'tempdb..dbo.TX_ERCOTAddPlug' , N'U') IS NOT NULL
        DROP TABLE dbo.TX_ERCOTAddPlug;
    CREATE TABLE dbo.TX_ERCOTAddPlug
        ( MonthID NVARCHAR(10)
        , ServiceMonth NVARCHAR(50)
        , Dimension NVARCHAR(20)
        , RecordCount INT
        ); 
    INSERT  INTO dbo.TX_ERCOTAddPlug
            SELECT  MonthID
                  , ServiceMonth
                  , Dimension = 'Begin||ERCOT'
                  , CASE WHEN [Begin||ERCOT] IS NOT NULL THEN [Begin||ERCOT]
                    END AS RecordCount
            FROM    #AdditionPlug
            UNION
            SELECT  MonthID
                  , ServiceMonth
                  , Dimension = 'CustAddition'
                  , CASE WHEN CustAddition IS NOT NULL THEN CustAddition
                    END AS RecordCount
            FROM    #AdditionPlug
            UNION
            SELECT  MonthID
                  , ServiceMonth
                  , Dimension = 'CustAttrition'
                  , CASE WHEN CustAttrition IS NOT NULL THEN CustAttrition
                    END AS RecordCount
            FROM    #AdditionPlug
            UNION
            SELECT  MonthID
                  , ServiceMonth
                  , Dimension = 'End||ERCOT'
                  , CASE WHEN [End||ERCOT] IS NOT NULL THEN [End||ERCOT]
                    END AS RecordCount
            FROM    #AdditionPlug
                                
    --SELECT  *
 
    --FROM    dbo.TX_ERCOTAddPlug        
/**************************************************
/*Select ERCOTRfwd END and DIFF Plug into table*/
***************************************************/  
 
    IF OBJECT_ID(N'tempdb..#EndDiff' , N'U') IS NOT NULL
        DROP TABLE #EndDiff;
    CREATE TABLE #EndDiff
        ( MonthID NVARCHAR(10)
        , ServiceMonth NVARCHAR(50)
        , [Begin||ERCOT] INT
        , CustAddition INT
        , CustAttrition INT
        , EndCal INT
        , [End||ERCOT] INT
        , Diff INT
        );            
    WITH    ERCOTRfwd
              AS ( SELECT   MonthID
                          , ServiceMonth
                          , [Begin||ERCOT] = SUM([Begin])
                          , CustAddition = SUM(CustAddition)
                          , CustAttrition = SUM(CustAttrition)
                          , [End||ERCOT] = SUM([End])
                   FROM     #FinalTable
                   GROUP BY MonthID
                          , ServiceMonth
                 )
        INSERT  INTO #EndDiff
                SELECT  MonthID
                      , ServiceMonth
                      , [Begin||ERCOT]
                      , CustAddition
                      , CustAttrition
                      , 'EndCal' = [Begin||ERCOT] + ( CustAddition
                                                      - CustAttrition )
                      , [End||ERCOT]
                      , 'Diff' = [End||ERCOT] - ( [Begin||ERCOT]
                                                  + ( CustAddition
                                                      - CustAttrition ) )
                FROM    ERCOTRfwd
                ORDER BY  MonthID;
                
    --SELECT  *
    --FROM    #EndDiff
        DROP TABLE dbo.TX_ERCOTEndPlug;
    CREATE TABLE dbo.TX_ERCOTEndPlug
        ( MonthID NVARCHAR(10)
        , ServiceMonth NVARCHAR(50)
        , Dimension NVARCHAR(20)
        , RecordCount INT
        ); 
    INSERT  INTO dbo.TX_ERCOTEndPlug
            SELECT  MonthID
                  , ServiceMonth
                  , Dimension = 'Begin||ERCOT'
                  , CASE WHEN [Begin||ERCOT] IS NOT NULL THEN [Begin||ERCOT]
                    END AS RecordCount
            FROM    #EndDiff
            UNION
            SELECT  MonthID
                  , ServiceMonth
                  , Dimension = 'CustAddition'
                  , CASE WHEN CustAddition IS NOT NULL THEN CustAddition
                    END AS RecordCount
            FROM    #EndDiff
            UNION
            SELECT  MonthID
                  , ServiceMonth
                  , Dimension = 'CustAttrition'
                  , CASE WHEN CustAttrition IS NOT NULL THEN CustAttrition
                    END AS RecordCount
            FROM    #EndDiff
            UNION
            SELECT  MonthID
                  , ServiceMonth
                  , Dimension = 'EndCalc'
                  , CASE WHEN EndCal IS NOT NULL THEN EndCal
                    END AS RecordCount
            FROM    #EndDiff
            UNION
            SELECT  MonthID
                  , ServiceMonth
                  , Dimension = 'End||ERCOT'
                  , CASE WHEN [End||ERCOT] IS NOT NULL THEN [End||ERCOT]
                    END AS RecordCount
            FROM    #EndDiff
            UNION
            SELECT  MonthID
                  , ServiceMonth
                  , Dimension = 'Diff'
                  , CASE WHEN Diff IS NOT NULL THEN Diff
                    END AS RecordCount
            FROM    #EndDiff
                                
    --SELECT  *
 
    --FROM    dbo.TX_ERCOTEndPlug            
                   
----/**************************************************
----/*Select ERCOTRfwd END and DIFF Plug into table USING ERCOT True Begin*/
----***************************************************/  
 
----    IF OBJECT_ID(N'tempdb..#TrueEndDiff' , N'U') IS NOT NULL
----        DROP TABLE #TrueEndDiff;
----    CREATE TABLE #TrueEndDiff
----        ( MonthID NVARCHAR(10)
----        , ServiceMonth NVARCHAR(50)
----        , [Begin||ERCOT] INT
----        , CustAddition INT
----        , CustAttrition INT
----        , EndCal INT
----        , [End||ERCOT] INT
----        , Diff INT
----        );            
----    WITH    ERCOTRfwd
----              AS ( SELECT   MonthID
----                          , ServiceMonth
----                          , [Begin||ERCOT] = SUM(TrueBegin)
----                          , CustAddition = SUM(CustAddition)
----                          , CustAttrition = SUM(CustAttrition)
----                          , [End||ERCOT] = SUM([End])
----                   FROM     #FinalTable
----                   GROUP BY MonthID
----                          , ServiceMonth
----                 )
----        INSERT  INTO #TrueEndDiff
----                SELECT  MonthID
----                      , ServiceMonth
----                      , [Begin||ERCOT]
----                      , CustAddition
----                      , CustAttrition
----                      , 'EndCal' = [Begin||ERCOT] + ( CustAddition
----                                                      - CustAttrition )
----                      , [End||ERCOT]
----                      , 'Diff' = [End||ERCOT] - ( [Begin||ERCOT]
----                                                  + ( CustAddition
----                                                      - CustAttrition ) )
----                FROM    ERCOTRfwd
----                ORDER BY MonthID;
                
----    SELECT  *
----    FROM    #TrueEndDiff
   
END




GO


