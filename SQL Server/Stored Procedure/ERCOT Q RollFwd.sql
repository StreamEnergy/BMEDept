USE [StreamInternal]
GO

/****** Object:  StoredProcedure [dbo].[sp_ERCOT_Q_RFWD]    Script Date: 08/18/2014 14:39:31 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




/*
============================================================================
************************** Notes/Change Log *******************************
==========================================================================
Date				Author						Description
08/11/2014 			Jide Akintoye				Count # of TX Net Additions, and Attritions,
												and Total count of Transactions @ the Begin and 
												End of the quarter per ERcot



==========================================================================						   
*/

CREATE PROCEDURE [dbo].[sp_ERCOT_Q_RFWD]
    ( @SDate DATETIME
    , @EDate DATETIME
--, @State NVARCHAR (MAX) 
--, @Status NVARCHAR (MAX) 

    )
AS
BEGIN


----Begin Test Section
--    DECLARE @SDate DATETIME = '01/01/2008'
--    DECLARE @EDate DATETIME = '06/30/2011'
----End Test Section

--Avoiding Parameter Sniffing
    DECLARE @StartDate AS DATETIME = @SDate
    DECLARE @EndDate AS DATETIME = @EDate
 

    IF OBJECT_ID(N'tempdb..#Q_ERCOTCount' , N'U') IS NOT NULL
        DROP TABLE #Q_ERCOTCount;
    CREATE TABLE #Q_ERCOTCount
        ( MonthID NVARCHAR(10)
        , ServiceMonth NVARCHAR(50)
        , Dimension NVARCHAR(20)
        , RecordCount INT
        ); 
    INSERT  INTO #Q_ERCOTCount
    

--/**************************************************
--/*Begin ERCOT Count*/
--            ***************************************************/
            SELECT DISTINCT
                    'MonthID' = DATENAME(YEAR , ErcotDate + 1) + '-'
                    + DATENAME(QUARTER , ErcotDate + 1)
                  , 'ServiceMonth' = SUBSTRING(DATENAME(MONTH , ErcotDate + 1) ,
                                               1 , 3) + ' - '
                    + SUBSTRING(DATENAME(MONTH ,
                                         ( DATEADD(MONTH , 3 , ErcotDate) )) ,
                                1 , 3) + ' ' + DATENAME(YEAR , ErcotDate + 1)
                  , 'Dimension' = 'QBegin||ERCOT'--CountType
                  , RecordCount
            FROM    StreamInternal.[dbo].[ERCOT_Numbers] EN
            LEFT JOIN ( SELECT  c.CalendarDate
                              , CASE WHEN c.CalendarDate = DATEADD(s , +0 ,
                                                              DATEADD(QUARTER ,
                                                              DATEDIFF(QUARTER ,
                                                              0 ,
                                                              c.CalendarDate)
                                                              + 0 , 0))
                                     THEN 'Begin'
                                END AS 'DayofQuater'
                        FROM    StreamInternal.dbo.Calendar c
                        WHERE   CalendarDate >= @StartDate
                                AND CalendarDate <= @EndDate
                      ) CD ON CD.CalendarDate = EN.ErcotDate + 1
            WHERE   CD.DayofQuater IN ( 'End' , 'Begin' )
        --AND CountType = 'End'
    --ORDER BY 1
            UNION ALL
/**************************************************
Count ALL New Customer Additions*
***************************************************/
            SELECT DISTINCT
                    'MonthID' = DATENAME(YEAR , [BeginServiceDate]) + '-'
                    + DATENAME(QUARTER , [BeginServiceDate])
                  , CASE WHEN SUBSTRING(DATENAME(QUARTER , [BeginServiceDate]) ,
                                        1 , 3) = 1
                         THEN 'Jan - Mar' + ' ' + DATENAME(YEAR ,
                                                           [BeginServiceDate])
                         WHEN SUBSTRING(DATENAME(QUARTER , [BeginServiceDate]) ,
                                        1 , 3) = 2
                         THEN 'Apr - Jun' + ' ' + DATENAME(YEAR ,
                                                           [BeginServiceDate])
                         WHEN SUBSTRING(DATENAME(QUARTER , [BeginServiceDate]) ,
                                        1 , 3) = 3
                         THEN 'Jul - Sep' + ' ' + DATENAME(YEAR ,
                                                           [BeginServiceDate])
                         WHEN SUBSTRING(DATENAME(QUARTER , [BeginServiceDate]) ,
                                        1 , 3) = 4
                         THEN 'Oct - Dec' + ' ' + DATENAME(YEAR ,
                                                           [BeginServiceDate])
                    END AS 'ServiceMonth'
                  , 'Dimension' = 'Q_CustAddition'
                  , 'RecordCount' = COUNT(DISTINCT enroll_orig_transaction_id)
            FROM    StreamInternal.dbo.TX_Enroll_Net
            WHERE   BeginServiceDate >= @StartDate
                    AND BeginServiceDate <= @EndDate
            GROUP BY SUBSTRING(DATENAME(QUARTER , [BeginServiceDate]) , 1 , 3)
                  , DATENAME(YEAR , [BeginServiceDate])
                  , DATENAME(YEAR , [BeginServiceDate]) + '-'
                    + DATENAME(QUARTER , [BeginServiceDate])
    --ORDER BY MonthID
            UNION ALL
--/**************************************************
----Count ALL Customer Dropped*
--***************************************************/
            SELECT DISTINCT
                    'MonthID' = DATENAME(YEAR , EndServiceDate) + '-'
                    + DATENAME(QUARTER , EndServiceDate)
                  , CASE WHEN SUBSTRING(DATENAME(QUARTER , EndServiceDate) , 1 ,
                                        3) = 1
                         THEN 'Jan - Mar' + ' ' + DATENAME(YEAR ,
                                                           EndServiceDate)
                         WHEN SUBSTRING(DATENAME(QUARTER , EndServiceDate) , 1 ,
                                        3) = 2
                         THEN 'Apr - Jun' + ' ' + DATENAME(YEAR ,
                                                           EndServiceDate)
                         WHEN SUBSTRING(DATENAME(QUARTER , EndServiceDate) , 1 ,
                                        3) = 3
                         THEN 'Jul - Sep' + ' ' + DATENAME(YEAR ,
                                                           EndServiceDate)
                         WHEN SUBSTRING(DATENAME(QUARTER , EndServiceDate) , 1 ,
                                        3) = 4
                         THEN 'Oct - Dec' + ' ' + DATENAME(YEAR ,
                                                           EndServiceDate)
                    END AS 'ServiceMonth'
                  , 'Dimension' = 'Q_CustAttrition'
                  , 'RecordCount' = COUNT(DISTINCT drop_sender_transaction_id)
            FROM    StreamInternal.dbo.TX_Drop_Net
            WHERE   EndServiceDate >= @StartDate
                    AND EndServiceDate <= @EndDate
            GROUP BY SUBSTRING(DATENAME(QUARTER , EndServiceDate) , 1 , 3)
                  , DATENAME(YEAR , EndServiceDate)
                  , DATENAME(YEAR , EndServiceDate) + '-' + DATENAME(QUARTER ,
                                                              EndServiceDate)
    --ORDER BY MonthID
            UNION ALL    
--/**************************************************
--/*End Premise Count*/
--            ***************************************************/
            SELECT DISTINCT
                    'MonthID' = DATENAME(YEAR , ErcotDate) + '-'
                    + DATENAME(QUARTER , ErcotDate)
                  , 'ServiceMonth' = SUBSTRING(DATENAME(MONTH ,
                                                        ( DATEADD(MONTH , -2 ,
                                                              ErcotDate) )) ,
                                               1 , 3) + ' - '
                    + SUBSTRING(DATENAME(MONTH ,
                                         ( DATEADD(MONTH , 0 , ErcotDate) )) ,
                                1 , 3) + ' ' + DATENAME(YEAR , ErcotDate)
                  , 'Dimension' = 'QEnd||ERCOT'--CountType
                  , RecordCount
            FROM    StreamInternal.[dbo].[ERCOT_Numbers] EN
            LEFT JOIN ( SELECT  c.CalendarDate
                              , CASE WHEN CONVERT(VARCHAR(8) , c.CalendarDate , 112) = CONVERT(VARCHAR(8) , DATEADD(s ,
                                                              -1 ,
                                                              DATEADD(QUARTER ,
                                                              DATEDIFF(QUARTER ,
                                                              0 ,
                                                              c.CalendarDate)
                                                              + 1 , 0)) , 112)
                                     THEN 'End'
                                END AS 'DayofQuater'
                        FROM    StreamInternal.dbo.Calendar c
                        WHERE   CalendarDate >= @StartDate
                                AND CalendarDate <= @EndDate
                      ) CD ON CD.CalendarDate = EN.ErcotDate
            WHERE   CD.DayofQuater IN ( 'End' , 'Begin' )
                    AND CountType = 'End'
            ORDER BY 1
   
/**************************************************
/*Bring it all together into one table*/
***************************************************/  
 
    IF OBJECT_ID(N'tempdb..#FinalTable' , N'U') IS NOT NULL
        DROP TABLE #FinalTable;
    CREATE TABLE #FinalTable
        ( MonthID NVARCHAR(10)
        , ServiceMonth NVARCHAR(50)
        , [Begin] INT
        , CustAddition INT
        , CustAttrition INT
        , [End] INT
        ); 
    INSERT  INTO #FinalTable
            SELECT  MonthID
                  , ServiceMonth
                  , CASE WHEN Dimension = 'QBegin||ERCOT'
                         THEN SUM(RecordCount)
                    END AS [Begin]
                  , CASE WHEN Dimension = 'Q_CustAddition'
                         THEN SUM(RecordCount)
                    END AS [CustAddition]
                  , CASE WHEN Dimension = 'Q_CustAttrition'
                         THEN SUM(RecordCount)
                    END AS [CustAttrition]
                  , CASE WHEN Dimension = 'QEnd||ERCOT' THEN SUM(RecordCount)
                    END AS [End]
            FROM    #Q_ERCOTCount
            GROUP BY MonthID
                  , ServiceMonth
                  , Dimension
            ORDER BY MonthID;
            
            --SELECT * FROM #FinalTable
            
             
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
                      --, Quart_AttrRate =  CAST(( [Begin||ERCOT] - [End||ERCOT] )
                      --  + CustAddition AS DECIMAL (5,2)) / CAST([Begin||ERCOT] AS DECIMAL (5,2))
                FROM    ERCOTRfwd
                ORDER BY MonthID;
          --SELECT *
          --FROM #AttritionPlug       
                
         
    DROP TABLE dbo.TX_Q_ERCOTAttrPlug;
    CREATE TABLE dbo.TX_Q_ERCOTAttrPlug
        ( MonthID NVARCHAR(10)
        , ServiceMonth NVARCHAR(50)
        , Dimension NVARCHAR(20)
        , RecordCount INT
        ); 
    INSERT  INTO dbo.TX_Q_ERCOTAttrPlug
            SELECT  MonthID
                  , ServiceMonth
                  , Dimension = 'Q-Begin||ERCOT'
                  , CASE WHEN [Begin||ERCOT] IS NOT NULL THEN [Begin||ERCOT]
                    END AS RecordCount
            FROM    #AttritionPlug
            UNION
            SELECT  MonthID
                  , ServiceMonth
                  , Dimension = 'Q-CustAddition'
                  , CASE WHEN CustAddition IS NOT NULL THEN CustAddition
                    END AS RecordCount
            FROM    #AttritionPlug
            UNION
            SELECT  MonthID
                  , ServiceMonth
                  , Dimension = 'Q-CustAttrition'
                  , CASE WHEN CustAttrition IS NOT NULL THEN CustAttrition
                    END AS RecordCount
            FROM    #AttritionPlug
            UNION
            SELECT  MonthID
                  , ServiceMonth
                  , Dimension = 'Q-End||ERCOT'
                  , CASE WHEN [End||ERCOT] IS NOT NULL THEN [End||ERCOT]
                    END AS RecordCount
            FROM    #AttritionPlug
                                
    --SELECT  *
    --FROM    dbo.TX_Q_ERCOTAttrPlug  
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
                
                
    --IF OBJECT_ID(N'tempdb..dbo.TX_Q_ERCOTAddPlug' , N'U') IS NOT NULL
    DROP TABLE dbo.TX_Q_ERCOTAddPlug;
    CREATE TABLE dbo.TX_Q_ERCOTAddPlug
        ( MonthID NVARCHAR(10)
        , ServiceMonth NVARCHAR(50)
        , Dimension NVARCHAR(20)
        , RecordCount INT
        ); 
    INSERT  INTO dbo.TX_Q_ERCOTAddPlug
            SELECT  MonthID
                  , ServiceMonth
                  , Dimension = 'Q-Begin||ERCOT'
                  , CASE WHEN [Begin||ERCOT] IS NOT NULL THEN [Begin||ERCOT]
                    END AS RecordCount
            FROM    #AdditionPlug
            UNION
            SELECT  MonthID
                  , ServiceMonth
                  , Dimension = 'Q-CustAddition'
                  , CASE WHEN CustAddition IS NOT NULL THEN CustAddition
                    END AS RecordCount
            FROM    #AdditionPlug
            UNION
            SELECT  MonthID
                  , ServiceMonth
                  , Dimension = 'Q-CustAttrition'
                  , CASE WHEN CustAttrition IS NOT NULL THEN CustAttrition
                    END AS RecordCount
            FROM    #AdditionPlug
            UNION
            SELECT  MonthID
                  , ServiceMonth
                  , Dimension = 'Q-End||ERCOT'
                  , CASE WHEN [End||ERCOT] IS NOT NULL THEN [End||ERCOT]
                    END AS RecordCount
            FROM    #AdditionPlug
                                
--    SELECT  *
--    FROM    dbo.TX_Q_ERCOTAddPlug        
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
                ORDER BY MonthID;
                
    --SELECT  *
    --FROM    #EndDiff
    DROP TABLE dbo.TX_Q_ERCOTEndPlug;
    CREATE TABLE dbo.TX_Q_ERCOTEndPlug
        ( MonthID NVARCHAR(10)
        , ServiceMonth NVARCHAR(50)
        , Dimension NVARCHAR(20)
        , RecordCount INT
        ); 
    INSERT  INTO dbo.TX_Q_ERCOTEndPlug
            SELECT  MonthID
                  , ServiceMonth
                  , Dimension = 'Q-Begin||ERCOT'
                  , CASE WHEN [Begin||ERCOT] IS NOT NULL THEN [Begin||ERCOT]
                    END AS RecordCount
            FROM    #EndDiff
            UNION
            SELECT  MonthID
                  , ServiceMonth
                  , Dimension = 'Q-CustAddition'
                  , CASE WHEN CustAddition IS NOT NULL THEN CustAddition
                    END AS RecordCount
            FROM    #EndDiff
            UNION
            SELECT  MonthID
                  , ServiceMonth
                  , Dimension = 'Q-CustAttrition'
                  , CASE WHEN CustAttrition IS NOT NULL THEN CustAttrition
                    END AS RecordCount
            FROM    #EndDiff
            UNION
            SELECT  MonthID
                  , ServiceMonth
                  , Dimension = 'Q-EndCalc'
                  , CASE WHEN EndCal IS NOT NULL THEN EndCal
                    END AS RecordCount
            FROM    #EndDiff
            UNION
            SELECT  MonthID
                  , ServiceMonth
                  , Dimension = 'Q-End||ERCOT'
                  , CASE WHEN [End||ERCOT] IS NOT NULL THEN [End||ERCOT]
                    END AS RecordCount
            FROM    #EndDiff
            UNION
            SELECT  MonthID
                  , ServiceMonth
                  , Dimension = 'Q-Diff'
                  , CASE WHEN Diff IS NOT NULL THEN Diff
                    END AS RecordCount
            FROM    #EndDiff
                                
--    SELECT  *
--    FROM    dbo.TX_Q_ERCOTEndPlug            
          
   
END





GO


