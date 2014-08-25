USE [StreamInternal]
GO

/****** Object:  StoredProcedure [dbo].[sp_MvInMvOt_Drop]    Script Date: 08/25/2014 12:21:28 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



/*
============================================================================
************************** Notes/Change Log *******************************
==========================================================================
Date				Author						Description
08/05/2014 			Jide Akintoye				Count # of Move in Move out Drop by combining
												the Net Drop, the dropped service total Transfer of Service (TOS)(same customer, diff esiid, within 30 days)
												,count of dropped of the R1 (Diff Customer, Same ESIID) and 
												the count of dropped of the R2 (same esiid, enroll within 90days after drop)
														   


==========================================================================						   
*/

CREATE PROCEDURE [dbo].[sp_MvInMvOt_Drop]
(@StartDate DATETIME
,@EndDate DATETIME
--, @State NVARCHAR (MAX) 
--, @Status NVARCHAR (MAX) 

)
AS
BEGIN


---- --Begin Test Section
--DECLARE @StartDate DATETIME = '10/31/2013'
--DECLARE @EndDate DATETIME = '03/31/2014'
----DECLARE @SDate VARCHAR(7)
----DECLARE @EDate VARCHAR(7)
----End Test Section

----SELECT  @SDate = CONVERT(VARCHAR(7) , @StartDate , 120) 
----SELECT  @EDate = CONVERT(VARCHAR(7) , @EndDate , 120) 
-------------------------------
-- Net Dropped Transaction
-------------------------------
    IF OBJECT_ID(N'tempdb..#NetDrop' , N'U') IS NOT NULL
        DROP TABLE #NetDrop;
    CREATE TABLE #NetDrop
        ( EndServiceDate DATETIME
        , MonthID NVARCHAR(10)
        , EndServiceMonth NVARCHAR(50)
        , DropType NVARCHAR(10)
        , RecordCount INT
        );    
    WITH    NetDrop
              AS ( SELECT  DISTINCT
                            EndServiceDate
                          , 'EndServiceMonth' = SUBSTRING(DATENAME(MONTH ,
                                                              [EndServiceDate]) ,
                                                            1 , 3) + ' '
                            + DATENAME(YEAR , [EndServiceDate])
                          , N.[YYYY-MM]
                          , DropType = 'New-Drop'
                          , 'NetDrop' = COUNT(DISTINCT N.[drop_sender_transaction_id])
                   FROM     StreamInternal.dbo.TX_Drop_Net N
                   WHERE    [EndServiceDate] >= @StartDate
                            AND [EndServiceDate] <= @EndDate
                   GROUP BY DATENAME(MONTH , [EndServiceDate]) + ' '
                            + DATENAME(YEAR , [EndServiceDate])
                          , [EndServiceDate]
                          , N.[YYYY-MM]
                 )
        INSERT  INTO #NetDrop
                SELECT  EndServiceDate
                      , 'MonthID' = [YYYY-MM]--DATEPART(MONTH , EndServiceDate)
                      , EndServiceMonth
                      , DropType
                      , 'NetDrop' = SUM(NetDrop)
                FROM    NetDrop
                GROUP BY EndServiceDate
                      , EndServiceMonth
                      , DropType
                      , [YYYY-MM]
                ORDER BY [EndServiceDate]
     --SELECT 'MonthID' = [YYYY-MM]
     --     , 'Month' = EndServiceMonth
     --     , 'NetAddition' = SUM(NetAddition)
     --FROM   Net_TOS
     --GROUP BY EndServiceMonth
     --     , [YYYY-MM]
     --ORDER BY [YYYY-MM];
 
    --SELECT  *
    --FROM    #NetDrop
    
-------------------------------
-- Dropped:Transfer of Service (TOS) (same customer, diff esiid, within 30 days)
-------------------------------
    IF OBJECT_ID(N'tempdb..#Net_TOS_Drop' , N'U') IS NOT NULL
        DROP TABLE #Net_TOS_Drop;
    CREATE TABLE #Net_TOS_Drop
        ( EndServiceDate DATETIME
        , MonthID NVARCHAR(10)
        , EndServiceMonth NVARCHAR(50)
        , DropType NVARCHAR(10)
        , RecordCount INT
        );    
    WITH    NetTOS
              AS ( SELECT  DISTINCT
                            EndServiceDate
                          , 'EndServiceMonth' = SUBSTRING(DATENAME(MONTH ,
                                                              [EndServiceDate]) ,
                                                            1 , 3) + ' '
                            + DATENAME(YEAR , [EndServiceDate])
                          , N.[YYYY-MM]
                          , DropType = 'TOS-Drop'
                          , 'Net_TOS' = COUNT(DISTINCT N.[drop_sender_transaction_id])
                   FROM     StreamInternal.dbo.[TX_Drop_TOS] N
                   WHERE    [EndServiceDate] >= @StartDate
                            AND [EndServiceDate] <= @EndDate
                   GROUP BY DATENAME(MONTH , [EndServiceDate]) + ' '
                            + DATENAME(YEAR , [EndServiceDate])
                          , [EndServiceDate]
                          , N.[YYYY-MM]
                 )
        INSERT  INTO #Net_TOS_Drop
                SELECT  EndServiceDate
                      , 'MonthID' = [YYYY-MM]--DATEPART(MONTH , EndServiceDate)
                      , EndServiceMonth
                      , DropType
                      , 'Net_TOS' = SUM(Net_TOS)
                FROM    NetTOS
                GROUP BY EndServiceDate
                      , EndServiceMonth
                      , DropType
                      , [YYYY-MM]
                ORDER BY [EndServiceDate]
     --SELECT 'MonthID' = [YYYY-MM]
     --     , 'Month' = EndServiceMonth
     --     , 'NetAddition' = SUM(NetAddition)
     --FROM   Net_TOS
     --GROUP BY EndServiceMonth
     --     , [YYYY-MM]
     --ORDER BY [YYYY-MM];
 
    --SELECT  *
    --FROM    #Net_TOS_Drop
    
 ------------------------------
---- Dropped:R1 (Diff Customer, Same ESIID)
-------------------------------
    IF OBJECT_ID(N'tempdb..#Net_Recycle1_Drop' , N'U') IS NOT NULL
        DROP TABLE #Net_Recycle1_Drop;
    CREATE TABLE #Net_Recycle1_Drop
        ( EndServiceDate DATETIME
        , MonthID NVARCHAR(10)
        , EndServiceMonth NVARCHAR(50)
        , DropType NVARCHAR(20)
        , RecordCount INT
        );    
    WITH    NetRecycle1
              AS ( SELECT  DISTINCT
                            EndServiceDate
                          , 'EndServiceMonth' = SUBSTRING(DATENAME(MONTH ,
                                                              [EndServiceDate]) ,
                                                            1 , 3) + ' '
                            + DATENAME(YEAR , [EndServiceDate])
                          , N.[YYYY-MM]
                          , DropType = 'Recycle1-Drop'
                          , 'Net_Recycle1' = COUNT(DISTINCT N.[drop_sender_transaction_id])
                   FROM     StreamInternal.dbo.[TX_Drop_Recycle1] N
                   WHERE    [EndServiceDate] >= @StartDate
                            AND [EndServiceDate] <= @EndDate
                   GROUP BY DATENAME(MONTH , [EndServiceDate]) + ' '
                            + DATENAME(YEAR , [EndServiceDate])
                          , [EndServiceDate]
                          , N.[YYYY-MM]
                 )
        INSERT  INTO #Net_Recycle1_Drop
                SELECT  EndServiceDate
                      , 'MonthID' = [YYYY-MM]--DATEPART(MONTH , EndServiceDate)
                      , EndServiceMonth
                      , DropType
                      , 'Net_Recycle1' = SUM(Net_Recycle1)
                FROM    NetRecycle1
                GROUP BY EndServiceDate
                      , EndServiceMonth
                      , DropType
                      , [YYYY-MM]
                ORDER BY [EndServiceDate]
     --SELECT 'MonthID' = [YYYY-MM]
     --     , 'Month' = EndServiceMonth
     --     , 'NetAddition' = SUM(NetAddition)
     --FROM   Net_TOS
     --GROUP BY EndServiceMonth
     --     , [YYYY-MM]
     --ORDER BY [YYYY-MM];
 
    --SELECT  *
    --FROM    #Net_Recycle1_Drop

------------------------------
---- Dropped:R2 (same esiid, enroll within 90days after drop)
-------------------------------
    IF OBJECT_ID(N'tempdb..#Net_Recycle2_Drop' , N'U') IS NOT NULL
        DROP TABLE #Net_Recycle2_Drop;
    CREATE TABLE #Net_Recycle2_Drop
        ( EndServiceDate DATETIME
        , MonthID NVARCHAR(10)
        , EndServiceMonth NVARCHAR(50)
        , DropType NVARCHAR(20)
        , RecordCount INT
        );    
    WITH    NetRecycle2
              AS ( SELECT  DISTINCT
                            EndServiceDate
                          , 'EndServiceMonth' = SUBSTRING(DATENAME(MONTH ,
                                                              [EndServiceDate]) ,
                                                            1 , 3) + ' '
                            + DATENAME(YEAR , [EndServiceDate])
                          , N.[YYYY-MM]
                          , DropType = 'Recycle2-Drop'
                          , 'Net_Recycle2' = COUNT(DISTINCT N.[drop_sender_transaction_id])
                   FROM     StreamInternal.dbo.[TX_Drop_Recycle2] N
                   WHERE    [EndServiceDate] >= @StartDate
                            AND [EndServiceDate] <= @EndDate
                   GROUP BY DATENAME(MONTH , [EndServiceDate]) + ' '
                            + DATENAME(YEAR , [EndServiceDate])
                          , [EndServiceDate]
                          , N.[YYYY-MM]
                 )
        INSERT  INTO #Net_Recycle2_Drop
                SELECT  EndServiceDate
                      , 'MonthID' = [YYYY-MM]--DATEPART(MONTH , EndServiceDate)
                      , EndServiceMonth
                      , DropType
                      , 'Net_Recycle2' = SUM(Net_Recycle2)
                FROM    NetRecycle2
                GROUP BY EndServiceDate
                      , EndServiceMonth
                      , DropType
                      , [YYYY-MM]
                ORDER BY [EndServiceDate]
     --SELECT 'MonthID' = [YYYY-MM]
     --     , 'Month' = EndServiceMonth
     --     , 'NetAddition' = SUM(NetAddition)
     --FROM   Net_TOS
     --GROUP BY EndServiceMonth
     --     , [YYYY-MM]
     --ORDER BY [YYYY-MM];
 
    --SELECT  *
    --FROM    #Net_Recycle2_Drop

---------------------------------
---- Get  Total Dropped
---------------------------------  

    IF OBJECT_ID(N'tempdb..#MvInMvOt_DropSummary' , N'U') IS NOT NULL
        DROP TABLE #MvInMvOt_DropSummary;
    CREATE TABLE #MvInMvOt_DropSummary
        ( EndServiceDate DATETIME
        , MonthID NVARCHAR(10)
        , EndServiceMonth NVARCHAR(50)
        , DropType NVARCHAR(10)
        , RecordCount INT
        )
    INSERT  INTO #MvInMvOt_DropSummary
            SELECT  EndServiceDate
                  , MonthID
                  , EndServiceMonth
                  , DropType = 'Total-Drop'
                  , RecordCount
            FROM    #NetDrop
            UNION ALL
            SELECT  EndServiceDate
                  , MonthID
                  , EndServiceMonth
                  , DropType = 'Total-Drop'
                  , RecordCount
            FROM    #Net_TOS_Drop
            UNION ALL
            SELECT  EndServiceDate
                  , MonthID
                  , EndServiceMonth
                  , DropType = 'Total-Drop'
                  , RecordCount
            FROM    #Net_Recycle1_Drop
            UNION ALL
            SELECT  EndServiceDate
                  , MonthID
                  , EndServiceMonth
                  , DropType = 'Total-Drop'
                  , RecordCount
            FROM    #Net_Recycle2_Drop
            ORDER BY MonthID
            

    --SELECT  *
    --FROM    #MvInMvOt_DropSummary


---------------------------------
---- Bringing it all "dropped" together
---------------------------------    
    SELECT  *
    FROM    #NetDrop
    UNION ALL
    SELECT  *
    FROM    #Net_TOS_Drop
    UNION ALL
    SELECT  *
    FROM    #Net_Recycle1_Drop
    UNION ALL
    SELECT  *
    FROM    #Net_Recycle2_Drop
    UNION ALL
    SELECT  EndServiceDate
          , MonthID
          , EndServiceMonth
          , DropType
          , SUM(RecordCount)
    FROM    #MvInMvOt_DropSummary
    GROUP BY EndServiceDate
          , MonthID
          , EndServiceMonth
          , DropType
    ORDER BY MonthID
END





GO


